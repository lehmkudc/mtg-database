options(stringsAsFactors = FALSE)
library(RMySQL)
library(rhandsontable)
library(shiny)

connect <- function(user,password,dbname,host){
   mydb <- dbConnect( MySQL(), user =user, 
                      password = password,
                      dbname =dbname,
                      host = host )
   return( mydb )
}

# own_card <- function( card_name, set_name, status, notes){
#    card_name <- paste0("'",card_name,"'")
#    set_name <- paste0("'",set_name,"'")
#    notes <- paste0("'",notes,"'")
#    
#    query <-paste(
#    "INSERT INTO owned_cards ( CardID, SetID, location, notes)", 
#    "VALUES(( SELECT CardID FROM magic.all_cards WHERE CardName =",
#    card_name,
#    "),( SELECT SetID FROM magic.all_sets WHERE ShortName =", 
#    set_name, "),",
#    status, ",",
#    notes,
#    ");", sep=' ')
#    
#    dbSendQuery( mydb, query)
#    dbDisconnect(mydb)
#    
# }
# 
# wish_card <- function( card_name, set_name, status, notes){
#    mydb <- dbConnect( MySQL(), user='desktop', 
#                       password='Lucied!3',
#                       dbname='magic',
#                       host='192.168.1.147' )
#    card_name <- paste0("'",card_name,"'")
#    set_name <- paste0("'",set_name,"'")
#    notes <- paste0("'",notes,"'")
#    
#    query <-paste(
#    "INSERT INTO desired_cards ( CardID, SetID, location, notes)", 
#    "VALUES(( SELECT CardID FROM magic.all_cards WHERE CardName =",
#    card_name,
#    "),( SELECT SetID FROM magic.all_sets WHERE ShortName =", 
#    set_name, "),",
#    status, ",",
#    notes,
#    ");", sep=' ')
#    
#    dbSendQuery( mydb, query)
#    dbDisconnect(mydb)
#    
#    
# }

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

load <- function( mydb, card_name, set_code, foil, notes){
   #mydb <- connect()
   card_name <- paste0('"',card_name,'"')
   set_code <- paste0('"',set_code,'"')
   notes <- paste0('"',notes,'"')
   
   query <- paste( 'INSERT INTO loading_zone',
                   '(CardName, SetCode, Foil, Notes) VALUES(',
                   card_name, ',',set_code,',',foil,',',notes,');' )
   
   dbSendQuery( mydb, query)
   #dbDisconnect( mydb )
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
                   'JOIN all_cards as c ON l.CardName = c.CardName',
                   'JOIN all_codes as s ON l.SetCode = s.SetCode);')
   dbSendQuery(mydb, query)
   
   load_empty(mydb)
}

load_empty <- function(mydb){
   
   query <- 'DELETE FROM loading_zone;'
   dbSendQuery(mydb, query)
}

show_binder <- function(user,password,dbname,host, binder, order='' ){
   query <- sprintf(paste( 'SELECT DISTINCT count(*) as QTY,CardName as Name, SetCode, Foil, Notes FROM',
                   binder, 'as o',
                   'JOIN all_cards as c ON o.CardID = c.CardID',
                   'JOIN all_codes as s ON o.SetID = s.SetID',
                   'JOIN color_codes as cc on c.ColorID = cc.ColorID',
                   'GROUP BY CardName, SetCode, Foil, Notes;'))
   mydb <- connect(user,password,dbname,host)
   rs <- dbSendQuery( mydb, query )
   data <- fetch(rs)
   data[,1] <- as.integer(data[,1])
   dbDisconnect(mydb)
   return( data )
}

select_binder <- function( mydb,binder, order='' ){
   query <- paste( 'SELECT * FROM', binder, ';')
   rs <- dbSendQuery( mydb, query)
   data <- fetch(rs)
   return(data)
}

load_pointed <- function( points, binder ){
   if ( binder == 'play_binder'){
      id <- 'playID'
   } else if ( binder == 'trade_binder'){
      id <- 'tradeID'
   } else if ( binder == 'wish_binder'){
      id <- 'wishID'
   }
   
   query <- paste('INSERT INTO loading_zone (CardName, SetCode, Foil, Notes)',
                  'SELECT CardName, SetCode,Foil, Notes FROM',
                  binder,'as o',
                  'JOIN all_cards as c ON o.CardID = c.CardID',
                  'JOIN all_codes as s ON o.SetID = s.SetID',
                  'WHERE', id, 'IN (',
                  paste(points, collapse = ','), ');'
   )
   dbSendQuery( mydb, query)
}

delete_pointed <- function( points, binder ){
   if ( binder == 'play_binder'){
      id <- 'playID'
   } else if ( binder == 'trade_binder'){
      id <- 'tradeID'
   } else if ( binder == 'wish_binder'){
      id <- 'wishID'
   }
   
   query <- paste('DELETE FROM', binder,'WHERE',
                  id, 'IN (',
                  paste( points, collapse = ','), ');'
   )
   dbSendQuery( mydb, query)
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

kill_connections <- function( IP_address){
   mydb <- connect(user,password,dbname,host)
   dbDisconnect(mydb)
}

# 
# # 
# mydb <- connect('10.1.10.166')
# # 
# points <- c(1,2,3,4,5)
# delete_pointed( points, 'trade_binder')
# # play <- select_binder(mydb, 'play_binder') 
# # 
# dbDisconnect(mydb)
