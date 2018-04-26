options(stringsAsFactors = FALSE)
library(RMySQL)
library(rhandsontable)
library(shiny)

connect <- function(){
   mydb <- dbConnect( MySQL(), user =user, 
                      password = password,
                      dbname =dbname,
                      host = host )
   return( mydb )
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
   card_name <- paste0('"',card_name,'"')
   set_name <- paste0('"',set_name,'"')
   notes <- paste0('"',notes,'"')
   
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

load_all <- function( conn, df_flat ){
   N <- nrow( df_flat )
   for (i in 1:N){
      load( conn, df_flat$CardName, df_flat$SetName, df_flat$Foil, df_flat$Notes )
   }
   
}

load_all <- function(mydb, lz){
   N <- nrow(lz)
   for (i in 1:N){
      load( mydb, lz[i,1], lz[i,2],lz[1,3],lz[1,4])
   }
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

load_empty <- function(mydb){
   
   query <- 'DELETE FROM loading_zone;'
   dbSendQuery(mydb, query)
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

from_table_to_binder <- function(user,password,dbname,host, df, binder){
   print('function called')
   finalDF <- trim_dataframe(df)
   print('dataframe trimmed')
   print( finalDF)
   cvt <- cvt_cardlist(finalDF)
   print( 'converted')
   mydb <- connect(user,password,dbname,host)
   print( 'connected')
   load_all(mydb,cvt)
   print( 'loaded')
   unload(mydb, binder)
   print( 'unloaded')
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
