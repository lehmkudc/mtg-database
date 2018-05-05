options(stringsAsFactors = FALSE)
library(RMySQL)
library(rhandsontable)
library(shiny)
library(rjson)

connect <- function(){
   # Connect to sql server using credentials in R environment
   conn <- dbConnect( MySQL(), user = user, 
                      password = password,
                      dbname = dbname,
                      host = host )
   return( conn )
}


short_to_long <- function( df_short ){
   # Convert a decklist-style dataframe to an itemized list
   
   total    <- sum( df_short$QTY )
   CardName <- rep( 0, total )
   SetName  <- rep( NA, total )
   Foil     <- rep( 0, total )
   Notes    <- rep( NA, total )
   
   j <- 1
   for (i in 1:nrow(df_short)){
      r <- j:(j + df_short$QTY[i] - 1 )
      CardName[r] <- df_short$CardName[i]
      SetName[r]  <- df_short$SetName[i]
      Foil[r]     <- df_short$Foil[i]
      Notes[r]    <- df_short$Notes[i]
      j <- j + df_short$QTY[i]
   }
   
   df_long <- data.frame( CardName = CardName, SetName = SetName, 
                          Foil = Foil, Notes = Notes)
   return( df_long )
}


load <- function( conn, card_name, set_name, foil=0, notes=''){
   # Move a user-inputted card into the loading zone
   #     and assign to correct printing
   # WARNING: If correct print is not found, row not insterted
   
   card_name   <- paste0('"',card_name,'"')
   set_name    <- paste0('"',set_name,'"')
   notes       <- paste0('"',notes,'"')
   
   q <- paste( 'INSERT INTO load_zone (PrintID, Foil, Notes)',
               'SELECT (SELECT PrintID FROM all_prints',
               'WHERE CardID = (SELECT CardID FROM all_cards',
               'WHERE CardName = ', card_name, ')',
               'AND SetID = (SELECT SetID FROM all_sets ',
               'WHERE SetName = ', set_name, ')) LIMIT 1,',
               foil, ',', notes, ';')
   print( q )
   
   dbSendQuery( conn, q )
   print( 'loaded' )
}


load_all <- function( conn, df_long ){
   # Perform the load() function on every tuple in extended card list
   
   N <- nrow( df_long )
   for (i in 1:N){
      load( conn, df_long$CardName[i], df_long$SetName[i], 
            foil = df_long$Foil[i], notes = df_long$Notes[i] )
   }
}



load_to_binder <- function( conn, binder ){
   # Move all tuples from loading zone to a binder
   
   q <- paste( 'INSERT INTO', binder,
               '(PrintID, Foil, Notes)',
               'SELECT PrintID, Foil, Notes FROM load_zone;')
   dbSendQuery( conn, q )
}



empty_load_zone <- function( conn ){
   # Empty the loading zone
   
   q <- 'DELETE FROM load_zone;'
   dbSendQuery( conn, q )
}



binder_to_short <- function( conn, binder ){
   # Extract condensed card list from a binder
   
   q <- paste( 'SELECT COUNT(*) AS QTY, CardName, SetName, Foil, Notes, Price, SUM( Price )',
               'FROM', binder, 'AS b',
               'JOIN all_prints AS p ON b.PrintID = p.PrintID',
               'JOIN all_cards AS c ON p.CardID = c.CardID',
               'JOIN all_sets AS s ON p.SetID = s.SetID',
               'GROUP BY CardName, SetName, Foil, Notes, Price;' )
   rs <- dbSendQuery( conn, q )
   df <- fetch( rs )
   df$QTY <- as.integer( df$QTY )
   df$Foil <- as.logical( df$Foil )
   
   return( df )
}

binder_to_edit <- function( conn, binder ){
   q <- paste( 'SELECT COUNT(*) AS QTY, CardName, SetName, Foil, Notes, Mult',
               'FROM', binder, 'AS b',
               'JOIN all_prints AS p ON b.PrintID = p.PrintID',
               'JOIN all_cards AS c ON p.CardID = c.CardID',
               'JOIN all_sets AS s ON p.SetID = s.SetID',
               'GROUP BY CardName, SetName, Foil, Notes, Mult;' )
   rs <- dbSendQuery( conn, q )
   df <- fetch( rs )
   df$QTY <- as.integer( df$QTY )
   df$Foil <- as.logical( df$Foil )
   
   return( df )
}


short_to_binder <- function( df_short, binder ){
   # Take a decklists and import the data to a chosen binder by
   #    Using the loading zone
   df_long <- short_to_long( df_short )
   print( df_long )
   conn <- connect()
   load_all( conn, df_long )
   print( 'loaded' )
   load_to_binder( conn, binder )
   print( 'bindered' )
   empty_load_zone( conn )
   dbDisconnect( conn )
}



trim_dataframe <- function( df ){
   # Take an output from the edit table and ensure no phantom data is passed
   df1 <- df[df$CardName != '' & df$QTY > 0,]
   df1$Foil <- as.integer(df1$Foil)
   return(df1)
}

empty_binder <- function( conn, binder){
   # Remove all cards from a binder
   q <- paste('DELETE FROM', binder)
   dbSendQuery(conn, q)
}

kill_connections <- function(){
   # Ensure that a connection can be made, and generally when used stops
   #   multiple connections from being open at the same time while debugging
   conn <- connect()
   dbDisconnect(conn)
}





get_card <- function( set_code, cnumber, promo){
   star <- ifelse( promo == 1, '%E2%98%85', '')
   url <- paste0( "https://api.scryfall.com/cards/",
                  set_code, "/", cnumber, star )
   card <- fromJSON( file = url )
   return( card )
}

get_locator <- function( print_id ){
   conn <- connect()
   aq <- paste( "SELECT SetCode, CNumber, Promo FROM all_prints AS p",
                "JOIN all_sets AS s ON p.SetID = s.SetID",
                "WHERE PrintID =", print_id )
   locator <- fetch( dbSendQuery( conn, aq ) )[1,]
   locator <- list( set_code = locator$SetCode,
                    cnumber = locator$CNumber,
                    promo = locator$Promo)
   dbDisconnect( conn )
   return( locator )
}

get_stale <- function( binder ){
   conn <- connect()
   q <- paste( "SELECT * FROM", binder, "AS b",
               "JOIN all_prints AS p ON b.PrintID = p.PrintID",
               "WHERE b.Fresh < CURDATE();" )
   s <- dbSendQuery( conn, q )
   stale <- fetch( s )
   dbDisconnect( conn )
   return( stale )
}

get_price <- function( print_id, foil, mult ){
   locator <- get_locator( print_id )
   card <- get_card( locator$set_code, locator$cnumber, locator$promo )
   p <- card$usd
   price <- as.numeric(p)*mult
   return( price )
}

update_card_price <- function(binder, pk_name, pk_value, price ){
   q <- paste( "UPDATE", binder,
               "SET Price =", price, ",Fresh = CURDATE()",
               "WHERE", pk_name, "=", pk_value, ";" )
   print( q )
   conn <- connect()
   dbSendQuery( conn, q )
   dbDisconnect( conn )
}


update_prices <- function(binder){
   stale <- get_stale( binder )
   for ( i in 1:nrow(stale) ){
      price <- get_price( stale$PrintID[i], 0, 1 )
      update_card_price( binder, colnames( stale )[1], 
                         stale[i,1], price )
   }
}
