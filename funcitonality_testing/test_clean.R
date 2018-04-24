rm(list = ls())
options(stringsAsFactors = FALSE)

source('mtg-database/transaction_functions.R')
source('C:/Users/Dustin/Desktop/config.R')
source('mtg-database/app_functions.R')

kill_connections(host)


clean_load <- function(CardName, SetName, Foil, Notes){
   card_name = paste0( '"',CardName,'"')
   set_name = paste0( '"', SetName, '"')
   query <- paste( 'SELECT CardID FROM all_cards2',
                   'WHERE CardName = ', card_name,
                   'AND SetCode = ( SELECT SetCode FROM all_codes',
                   'WHERE SetName =', set_name, ');')
   
   
   
   
}