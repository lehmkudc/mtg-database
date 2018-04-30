options(stringsAsFactors = FALSE)
library(RMySQL)
library(rhandsontable)
library(shiny)

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
               'WHERE SetName = ', set_name, ')),',
               foil, ',', notes, ';')
   #print( q )
   
   dbSendQuery( conn, q )
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
   
   q <- paste( 'SELECT COUNT(*) AS QTY, CardName, SetName, Foil, Notes',
               'FROM', binder, 'AS b',
               'JOIN all_prints AS p ON b.PrintID = p.PrintID',
               'JOIN all_cards AS c ON p.CardID = c.CardID',
               'JOIN all_sets AS s ON p.SetID = s.SetID',
               'GROUP BY CardName, SetName, Foil, Notes;' )
   print( q )
   rs <- dbSendQuery( conn, q )
   df <- fetch( rs )
   df$QTY <- as.integer( df$QTY )
   df$Foil <- as.logical( df$Foil )
   
   return( df )
}



short_to_binder <- function( df_short, binder ){
   # Take a decklists and import the data to a chosen binder by
   #    Using the loading zone
   df_short <- trim_dataframe( df_short )
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