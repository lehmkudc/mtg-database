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
   
   total    <- sum( df$QTY )
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

cvt_cardlist <- function( cardlist ){
   if ( is.character(cardlist) & length(cardlist) == 1 ){
      df <- read.csv(cardlist,header = TRUE)
   } else {
      df <- cardlist
   }
   
   
   total <- sum(df[,1])
   name <- rep(0,total)
   set <- rep(NA,total)
   foil <- rep(0,total)
   notes <- rep(NA,total)
   
   j <- 1
   for (i in 1:nrow(df)){
      r <- j:(j +df[i,1]-1)
      name[ r ] <- df[i,2]
      set[ r ] <- df[i,3]
      foil[ r ] <- df[i,4]
      notes[r] <- df[i,5]
      j <- j+df[i,1]
   }
   
   out <- data.frame( name = name, set = set, foil = foil,notes = notes)
   return( out )
}

load <- function( conn, card_name, set_name, foil=0, notes){
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
   
   dbSendQuery( conn, q )
}
   
load <- function( mydb, card_name, set_name, foil, notes){
   #mydb <- connect()
   card_name <- paste0('"',card_name,'"')
   set_name <- paste0('"',set_name,'"')
   notes <- paste0('"',notes,'"')
   
   query <- paste( 'INSERT INTO loading_zone',
                   '(CardName, SetName, Foil, Notes) VALUES(',
                   card_name, ',',set_name,',',foil,',',notes,');' )
   
   dbSendQuery( mydb, query)
   #dbDisconnect( mydb )
}

load_all <- function( conn, df_long ){
   # Perform the load() function on every tuple in extended card list
   
   N <- nrow( df_long )
   for (i in 1:N){
      load( conn, df_long$CardName, df_long$SetName, 
            df_long$Foil, df_long$Notes )
   }
}

load_all <- function(mydb, lz){
   N <- nrow(lz)
   for (i in 1:N){
      load( mydb, lz[i,1], lz[i,2],lz[1,3],lz[1,4])
   }
}

load_to_binder <- function( conn, binder ){
   # Move all tuples from loading zone to a binder
   
   q <- paste( 'INSERT INTO', binder,
               '(PrintID, Foil, Notes)',
               'SELECT PrintID, Foil, Notes FROM load_zone;')
   dbSendQuery( conn, q )
}

unload <- function(mydb, binder ){
   query <- paste( 'INSERT INTO', binder,
                   '(CardID, SetID, Foil, Notes) (',
                   'SELECT CardID, SetID, Foil, Notes FROM',
                   'magic.loading_zone as l',
                   'JOIN all_cards2 as c ON l.CardName = c.CardName',
                   'JOIN all_codes as s ON l.SetName = s.SetName);')
   dbSendQuery(mydb, query)
   
   load_empty(mydb)
}

empty_load_zone <- function( conn ){
   # Empty the loading zone
   
   q <- 'DELETE FROM load_zone;'
   dbSendQuery( conn, q )
}

load_empty <- function(mydb){
   
   query <- 'DELETE FROM loading_zone;'
   dbSendQuery(mydb, query)
}

binder_to_short <- function( conn, binder ){
   # Extract condensed card list from a binder
   
   q <- paste( 'SELECT COUNT(*) AS QTY, CardName, SetName, Foil, Notes',
               'FROM', binder, 'AS b',
               'JOIN all_prints AS p ON b.PrintID = p.PrintID',
               'JOIN all_cards AS c ON p.CardID = c.CardID',
               'JOIN all_sets AS s ON p.SetID = s.SetID',
               'GROUP BY PrintID, Foil, Notes;' )
   rs <- dbSendQuery( conn, q )
   df <- fetch( rs )
   df$QTY <- as.integer( df$QTY )
   df$Foil <- as.logical( df$Foil )
   
   return( df )
}

show_binder <- function(user,password,dbname,host, binder, order='' ){
   query <- sprintf(paste( 'SELECT DISTINCT count(*) as QTY,CardName as Name, SetName, Foil, Notes FROM',
                   binder, 'as o',
                   'JOIN all_cards2 as c ON o.CardID = c.CardID',
                   'JOIN all_codes as s ON o.SetID = s.SetID',
                   'JOIN color_codes as cc on c.ColorID = cc.ColorID',
                   'GROUP BY CardName, SetName, Foil, Notes;'))
   mydb <- connect(user,password,dbname,host)
   rs <- dbSendQuery( mydb, query )
   data <- fetch(rs)
   data[,1] <- as.integer(data[,1])
   data[,4] <- as.logical(data[,4])
   dbDisconnect(mydb)
   return( data )
}


select_binder <- function( mydb,binder, order='' ){
   query <- paste( 'SELECT * FROM', binder, ';')
   rs <- dbSendQuery( mydb, query)
   data <- fetch(rs)
   return(data)
}

short_to_binder <- function( conn, df_short, binder ){
   df_short <- trim_dataframe( df_short )
   df_long <- short_to_long
   
   
   
}

from_table_to_binder <- function(user,password,dbname,host, df, binder){
   finalDF <- trim_dataframe(df)
   print( finalDF)
   cvt <- cvt_cardlist(finalDF)
   mydb <- connect(user,password,dbname,host)
   load_all(mydb,cvt)
   unload(mydb, binder)
   dbDisconnect(mydb)
}

trim_dataframe <- function( df ){
   
   df1 <- df[df$Name != '' & df$QTY > 0,]
   df1[,4] <- as.integer(df1$Foil)
   return(df1)
}

empty_binder <- function( mydb, binder){
   query <- paste('DELETE FROM', binder)
   dbSendQuery(mydb, query)
}

kill_connections <- function(){
   mydb <- connect()
   dbDisconnect(mydb)
}
