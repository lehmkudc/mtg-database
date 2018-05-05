library(magrittr)
library(shiny)
library(RMySQL)
library(rhandsontable)


source( 'mtg-database/transactions.R' )
source( 'C:/Users/Dustin/Desktop/config.R')

binders <- list()
binders[[1]] <- list( title = 'Currently Used',
                      short = 'play',
                      table = 'play' )
binders[[2]] <- list( title = 'Trade Binder',
                      short = 'trade',
                      table = 'trade' )
binders[[3]] <- list( title = 'Wishlist',
                      short = 'wish',
                      table = 'wish' )


kill_connections()


conn <- connect()
#load( conn, 'Thalia, Heretic Cathar', 'Eldritch Moon Promos')
dbDisconnect( conn )


