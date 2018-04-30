rm(list = ls())
source( 'mtg-database/transactions.R')
source( 'C:/Users/Dustin/Desktop/config.R')

play <- data.frame( QTY = as.integer(c(3,2,0,0,0,0)), 
                  CardName = c('Bomat Courier','Hazoret the Fervent','','','',''),
                  SetName = c('Kaladesh','Amonkhet','','','',''),
                  Foil = c(F,T,T,F,F,F),
                  Notes = c('derp','p','','','','')
)



short_to_binder(play, 'play' )

# conn <- connect()
# df_short <- trim_dataframe( play )
# df_long <- short_to_long( df_short )
# load_all( conn, df_long )
# load_to_binder( conn, binder )
# empty_load_zone( conn )
# dbDisconnect( conn )