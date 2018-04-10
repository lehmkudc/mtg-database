rm(list = ls())

source('mtg-database/transaction_functions.R')
source('C:/Users/Dustin/Desktop/config.R')
source('mtg-database/app_functions.R')

kill_connections(host)

editTable( empty, user,password,dbname,host )