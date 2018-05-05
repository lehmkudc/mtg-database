rm( list = ls() )

library(magrittr)
library(shiny)
library(RMySQL)
library(rhandsontable)

empty <- data.frame( QTY=as.integer(0), CardName=rep('',20), 
                     SetName = rep('',20), Foil=rep(FALSE,20),
                     Notes = rep('',20), Mult=rep(1,20))


name_source <- readLines('mtg-database/data_prep/card_names.txt' )

set_source <- read.csv( 'mtg-database/data_prep/set_names.csv' )
set_source <- set_source$SetName


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

source( 'mtg-database/transactions.R' )
source( 'C:/Users/Dustin/Desktop/config.R')
source( 'mtg-database/dashboard_app.R')

kill_connections()
DF <- empty



