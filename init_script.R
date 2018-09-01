rm( list = ls() )

options(stringsAsFactors = FALSE)
library(magrittr)
library(shiny)
library(RMySQL)
library(rhandsontable)
library(rlist)
library(rjson)

empty <- data.frame( QTY=as.integer(0), CardName=rep('',20), 
                     SetName = rep('',20), CNumber=rep('',20),
                     Notes = rep('',20), Mult=rep(1,20),
                     Price = rep(0,20), Fresh=rep('2010-01-01',20) )


name_source <- readLines('mtg-database/data_prep/card_names.txt' )

set_source <- read.csv( 'mtg-database/data_prep/set_names.csv' )
set_source <- set_source$SetName

binders <- list.load( 'mtg-database/binders.rdata')

source( 'mtg-database/transactions.R' )
source( 'C:/Users/Dustin/Desktop/config.R')
source( 'mtg-database/dashboard_app.R')

kill_connections()
DF <- empty


dashboard()
