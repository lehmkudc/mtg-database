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
   CNumber  <- rep( "", total )
   Notes    <- rep( NA, total )
   Mult     <- rep( 1, total )
   Price    <- rep( 0, total )
   Fresh    <- rep( 0, total )
   
   j <- 1
   for (i in 1:nrow(df_short)){
      r <- j:(j + df_short$QTY[i] - 1 )
      CardName[r] <- df_short$CardName[i]
      SetName[r]  <- df_short$SetName[i]
      CNumber[r]  <- df_short$CNumber[i]
      Notes[r]    <- df_short$Notes[i]
      Mult[r]     <- df_short$Mult[i]
      Price[r]     <- df_short$Price[i]
      Fresh[r]     <- df_short$Fresh[i]
      
      
      j <- j + df_short$QTY[i]
   }
   
   df_long <- data.frame( CardName = CardName, SetName = SetName, 
                          CNumber = CNumber, Notes = Notes, Mult = Mult,
                          Price = Price, Fresh = Fresh)
   return( df_long )
}


load <- function( conn, card_name, set_name, cnum='', notes='',
                  mult = 1, price = 0, fresh='2000-01-01'){
   # Move a user-inputted card into the loading zone
   #     and assign to correct printing
   # WARNING: If correct print is not found, row not insterted
   
   card_name   <- paste0('"',card_name,'"')
   set_name    <- paste0('"',set_name,'"')
   notes       <- paste0('"',notes,'"')
   fresh       <- paste0('"',fresh,'"')
   
   qb <- paste( 'INSERT INTO load_zone (PrintID, Notes, Mult, Price, Fresh)',
                'SELECT (SELECT PrintID FROM all_prints',
                'WHERE CardID = (SELECT CardID FROM all_cards',
                'WHERE CardName = ', card_name, ')',
                'AND SetID = (SELECT SetID FROM all_sets ',
                'WHERE SetName = ', set_name, ')' )
   ql <- paste( notes, ',', mult, ',', price, ',', fresh, ';')
                
   if ( cnum == '' ){
      qm <- 'LIMIT 1 ),'
   } else {
      qm <- paste0( 'AND CNumber = "', cnum, '" ),' )
   }
   
   q <- paste( qb, qm, ql )
   print( q )
   dbSendQuery( conn, q )
}


load_all <- function( conn, df_long ){
   # Perform the load() function on every tuple in extended card list
   
   N <- nrow( df_long )
   for (i in 1:N){
      load( conn, df_long$CardName[i], df_long$SetName[i], 
            cnum = df_long$CNumber[i], notes = df_long$Notes[i],
            mult = df_long$Mult[i], price = df_long$Price[i],
            fresh = df_long$Fresh[i])
   }
}



load_to_binder <- function( conn, binder ){
   # Move all tuples from loading zone to a binder
   
   q <- paste( 'INSERT INTO', binder,
               '(PrintID, Notes, Mult, Price, Fresh)',
               'SELECT PrintID, Notes, Mult, Price, Fresh',
               'FROM load_zone;')
   dbSendQuery( conn, q )
}



empty_load_zone <- function( conn ){
   # Empty the loading zone
   
   q <- 'DELETE FROM load_zone;'
   dbSendQuery( conn, q )
}



binder_to_short <- function( conn, binder ){
   # Extract condensed card list from a binder
   
   q <- paste( 'SELECT COUNT(*) AS QTY, CardName, SetName, CNumber, Notes,',
               'Mult*Price AS Per_Card, SUM( mult*Price ) AS Total',
               'FROM', binder, 'AS b',
               'JOIN all_prints AS p ON b.PrintID = p.PrintID',
               'JOIN all_cards AS c ON p.CardID = c.CardID',
               'JOIN all_sets AS s ON p.SetID = s.SetID',
               'GROUP BY CardName, SetName, CNumber, Notes, Mult, Price;' )
   rs <- dbSendQuery( conn, q )
   df <- fetch( rs )
   df$QTY <- as.integer( df$QTY )
   
   return( df )
}

binder_to_edit <- function( conn, binder ){
   q <- paste( 'SELECT COUNT(*) AS QTY, CardName, SetName, CNumber, Notes, Mult, Price, Fresh',
               'FROM', binder, 'AS b',
               'JOIN all_prints AS p ON b.PrintID = p.PrintID',
               'JOIN all_cards AS c ON p.CardID = c.CardID',
               'JOIN all_sets AS s ON p.SetID = s.SetID',
               'GROUP BY CardName, SetName, CNumber, Notes, Mult, Price, Fresh;' )
   rs <- dbSendQuery( conn, q )
   df <- fetch( rs )
   df$QTY <- as.integer( df$QTY )
   
   return( df )
}


short_to_binder <- function( df_short, binder ){
   # Take a decklists and import the data to a chosen binder by
   #    Using the loading zone
   print( df_short )
   df_long <- short_to_long( df_short )
   conn <- connect()
   load_all( conn, df_long )
   load_to_binder( conn, binder )
   empty_load_zone( conn )
   dbDisconnect( conn )
}



trim_dataframe <- function( df ){
   # Take an output from the edit table and ensure no phantom data is passed
   df1 <- df[df$CardName != '' & df$QTY > 0,]
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

get_card <- function( set_code, cnumber){
   cnumber <- gsub( 'q', '%E2%98%85', cnumber )
   url <- paste0( "https://api.scryfall.com/cards/",
                  set_code, "/", cnumber )
   card <- fromJSON( file = url )
   return( card )
}

get_locator <- function( print_id ){
   conn <- connect()
   aq <- paste( "SELECT SetCode, CNumber FROM all_prints AS p",
                "JOIN all_sets AS s ON p.SetID = s.SetID",
                "WHERE PrintID =", print_id )
   locator <- fetch( dbSendQuery( conn, aq ) )[1,]
   locator <- list( set_code = locator$SetCode,
                    cnumber = locator$CNumber)
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

get_price <- function( print_id, mult ){
   locator <- get_locator( print_id )
   card <- get_card( locator$set_code, locator$cnumber )
   p <- card$usd
   price <- as.numeric(p)
   return( price )
}

update_card_price <- function(binder, pk_name, pk_value, price ){
   q <- paste( "UPDATE", binder,
               "SET Price =", price, ",Fresh = CURDATE()",
               "WHERE", pk_name, "=", pk_value, ";" )
   conn <- connect()
   dbSendQuery( conn, q )
   dbDisconnect( conn )
}


update_prices <- function(binder){
   stale <- get_stale( binder )
   if( nrow( stale ) > 0){
      for ( i in 1:nrow(stale) ){
         price <- get_price( stale$PrintID[i], 1 )
         update_card_price( binder, colnames( stale )[1], 
                            stale[i,1], price )
      }
   }
}

select_table <- function( table ){
   conn <- connect()
   q <- paste( "SELECT * FROM", table)
   data <- fetch( dbSendQuery( conn, q ) )
   dbDisconnect( conn )
   return( data )
}

empty_table <- function( table ){
   conn <- connect()
   q <- paste( "DELETE FROM", table )
   dbSendQuery( conn, q )
   dbDisconnect( conn )
}

create_binder <- function(title_name, short_name, table_name){
   # Open Binder
   binders <- list.load( 'mtg-database/binders.rdata') 

   # Add to mySQL
   pk_id <- paste0( "`", tools::toTitleCase(short_name), "ID`" )
   q <- paste0("CREATE TABLE `magic`.`", table_name, "` ( `",
               tools::toTitleCase(short_name), "ID` INT NOT NULL AUTO_INCREMENT, ",
               "`PrintID` INT NULL, ",
               "`Notes` VARCHAR(45) NULL, ",
               "`Mult` DECIMAL(3,2) NULL DEFAULT 1, ",
               "`Price` DECIMAL(9,2) NULL DEFAULT 0, ",
               "`Fresh` DATE NULL DEFAULT '2000-01-01', ",
               "PRIMARY KEY (", pk_id, "));" )
   conn <- connect()
   dbSendQuery( conn, q )
   dbDisconnect( conn )
   
   # Add to local information
   
   binders[[ length(binders) + 1 ]] <- list( title = title_name,
                                             short = short_name,
                                             table = table_name )
   # Add to file cache
   list.save( binders, 'mtg-database/binders.rdata')
}

delete_binder <- function(table_name){
   binders <- list.load( 'mtg-database/binders.rdata' )
   
   for( i in 1:length(binders) ){
      if ( binders[[i]]$table == table_name){
         # Remove the selected binder
         binders <- binders[ -i ]
         
         # Delete binder from MySQL
         q <- paste0( "DROP TABLE `magic`.`", table_name, "`;" )
         conn <- connect()
         dbSendQuery( conn, q )
         dbDisconnect( conn )
         
         
         # Remove from file cache
         list.save( binders, 'mtg-database/binders.rdata')
         
      }
      
   }
   
}

find_sets <- function( card_name ){
   card_name <- paste0('"', card_name, '"')
   q <- paste( "SELECT SetName, CNumber FROM all_prints as p",
               "JOIN all_cards AS c ON c.CardID = p.CardID",
               "JOIN all_sets as s ON s.SetID = p.SetID",
               "WHERE CardName =", card_name, ";" )
   conn <- connect()
   data <- fetch( dbSendQuery( conn, q ) )
   dbDisconnect( conn )
   return( data )
}

format_set_list <- function( df_sets ){
   out <- c( df_sets$SetName[1] )
   for (i in 2:nrow(df_sets)){
      out <- c( out, '\n', df_sets$SetName[i] )
   }
   return( out )
}