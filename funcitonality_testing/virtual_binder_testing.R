rm(list = ls())
options(stringsAsFactors = FALSE)

library(magrittr)
library(shiny)
library(RMySQL)
library(rhandsontable)
library(rjson)

source( 'mtg-database/transactions.R' )
source( 'C:/Users/Dustin/Desktop/config.R')


get_binder_cards <- function( binder ){
   conn <- connect()
   binder <- paste0( '"', binder, '"' )
   bq <- paste( "SELECT * FROM", binder)
   bs <- dbSendQuery( conn, bq )
   binder_cards <- fetch( bs )
   dbDisconnect( conn )
   return( binder_cards )
}

get_price_info <- function(){
   conn <- connect()
   pq <- "SELECT * FROM card_prices;"
   ps <- dbSendQuery( conn, pq )
   price_info <- fetch( ps )
   dbDisconnect( conn )
   return( price_info )
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
   locator <- fetch( dbSendQuery( conn, aq ) )
   dbDisconnect( conn )
   return( locator )
}


for ( i in 1:nrow(binder_cards) ){
   print_id <- binder_cards$PrintID[i]
   if ( print_id %in% price_info$PrintID) { # PrintID exists?
      
      target <- price_info[ price_info$PrintID == binder_cards$PrintID[i],]
      
      if ( target$UpDate == Sys.Date() ){ # Updated today?
         # Do Nothing
      } else {
         
         
      }

      
   } else {
      locator <- get_locator( print_id )[1,]
      set_code <- locator$SetCode
      cnumber <- locator$CNumber
      promo <- locator$Promo
      card <- get_card( set_code, cnumber, promo )
      price <- card$usd
      
   }
   
   
}