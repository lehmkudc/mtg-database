rm(list = ls())
options(stringsAsFactors = FALSE)

library(magrittr)
library(shiny)
library(RMySQL)
library(rhandsontable)
library(rjson)

source( 'mtg-database/transactions.R' )
source( 'C:/Users/Dustin/Desktop/config.R')


binders <- list()
binders[[1]] <- list( title = 'Currently Used',
                      short = 'play',
                      table = 'play',
                      pk = 'PlayID')
binders[[2]] <- list( title = 'Trade Binder',
                      short = 'trade',
                      table = 'trade',
                      pk = 'TradeID')
binders[[3]] <- list( title = 'Wishlist',
                      short = 'wish',
                      table = 'wish',
                      pk = 'WishID')



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

update_prices <- function(binder,pk_name){
   stale <- get_stale( binder )
   for ( i in 1:nrow(stale) ){
      price <- get_price( stale$PrintID[i], 0, 1 )
      update_card_price( binder, colnames( stale )[1], 
                         stale[i,1], price )
   }
}
#get_locator( get_stale('play')$PrintID[1] )
update_prices('play','PlayID')

#get_price( 1337, 0, 1.2)
#get_stale( 'play')
