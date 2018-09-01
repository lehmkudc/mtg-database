rm(list = ls())
options(stringsAsFactors = FALSE)

source('mtg-database/transaction_functions.R')
source('C:/Users/Dustin/Desktop/config.R')
source('mtg-database/app_functions.R')

#kill_connections(host)

b <- show_binder(user,password,dbname,host, 'wish_binder')

card_name = 'Cavern of Souls'
set_name = 'Avacyn Restored'

get_card_set <- function( card_name, set_name ){
   card_name = paste0( '"', card_name, '"')
   set_name = paste0( '"', set_name, '"')
   query <- paste('SELECT CardID, SetID, Uri FROM (',
                  'SELECT CardID, CardName, SetCode,Uri  FROM all_cards2',
                  'WHERE CardName =', card_name,
                  ' AND SetCode = (SELECT SetCode FROM all_codes',
                  'WHERE SetName =', set_name,
                  ')) as p JOIN all_codes as c ON p.SetCode = c.SetCode;')
   print( query)
   mydb <- connect(user,password,dbname,host)
   rs <- dbSendQuery( mydb, query )
   data <- fetch(rs)
   dbDisconnect(mydb)
   return( data )
}

in_price <- function(card_name, set_name){
   card_name = paste0( '"', card_name, '"')
   set_name = paste0( '"', set_name, '"')
   
}

get_card_set( 'Cavern of Souls', 'Avacyn Restored' )