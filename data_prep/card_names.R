rm( list=ls() )
library(rjson)
options(stringsAsFactors = FALSE)

source('mtg-database/transaction_functions.R')
source('C:/Users/Dustin/Desktop/config.R')
source('mtg-database/app_functions.R')

add_card_name <- function(conn, card_name){
   card_name <- paste0( '"', card_name, '"' )
   q <- paste( 'INSERT INTO all_cards (CardName) VALUES',
                  '(', card_name, ');')
   sq <- dbSendQuery( conn, q )
}

add_set_name <- function( conn, set_name, set_code){
   set_name <- paste0( '"', set_name, '"' )
   set_code <- paste0( '"', set_code, '"' )
   
   q <- paste( 'INSERT INTO all_sets (SetName, SetCode) VALUES',
               '(', set_name, ',' , set_code, ');' )
   sq <- dbSendQuery( conn, q)
}

add_print <- function( conn, cardid, setid, cnum, promo ){
   print( paste( cardid, setid, cnum, promo ) )
}

add_set_prints <- function( conn, set_code ){
   api <- paste0('https://api.scryfall.com/cards/search?q=e:',
                 set_code, '&unique=prints' )
   page <- fromJSON( file = api )
   end <- F
   
   while ( end == F ){ # Per Page
      N_cards <- length( page$data )
      
      for (i in 1:N_cards){ # For Each Card
         card <- page$data[[i]]
         
         x <- rep( 0, 4 )
         if ( length(card$card_faces) == 0 ){
            
            x[1] <- iconv( card$name, to = "ASCII//TRANSLIT")
            x[1] <- gsub( '"', '', x[1])
            x[1] <- gsub( ' //.+', '', x[1])
            if (nchar(x[1]) > 100){
               x[1] <- 'Our Market Research'
            }
         } else {
            cf <- card$card_faces[[1]]
            
            x[1] <- iconv( cf$name, to = "ASCII//TRANSLIT")
            x[1] <- gsub( '"', '', x[1])
            x[1] <- gsub( ' //.+', '', x[1])
         }
         
         x[2] <- set_code
         cn <- card$collector_number
         x[3] <- gsub( '\\D', '', cn, perl=F)
         x[4] <- as.integer(length(grep( '\\D', cn, perl=F)) >0)
         
         add_print( conn, x[1], x[2], x[3], x[4] )
      }
      if ( page$has_more == F ){
         end <- T
      } else {
         page <- fromJSON(file= as.character(page$next_page) )
      }
   }
   
}


conn <- connect()

add_set_prints( conn, 'unh' )

dbDisconnect( conn )





update_card_names <- function(){
   all <- fromJSON(file= 'https://api.scryfall.com/catalog/card-names')

   t <- unlist(all$data,use.names = F)
   t1 <- iconv(t, to = "ASCII//TRANSLIT")
   t2 <- gsub( '"', '', t1)
   t3 <- gsub( ' //.+', '', t2)
   t3[ grep( 'Our Market Research', t3) ] <- 'Our Market Research'
   
   x <-  readLines('mtg-database/data_prep/card_names.txt' )
   y <- setdiff(t3,x)
   yq <- paste0( '"', y, '"')
   
   conn <- connect()
   for ( i in 1:length(y) ){
      add_card_name( conn, y[i] )
      x <- c( x, y[i] )
      
   }
   write.table( x, 'mtg-database/data_prep/card_names.txt', row.names = F, quote = F, col.names = F)
   dbDisconnect( conn )
   
}

update_sets <- function(){
   all <- fromJSON(file= 'https://api.scryfall.com/sets')
   all <- all$data

   converted <- list()
   for ( i in 1:length(all) ){
      x <- rep(0,2)
      a <- all[[i]]
      x[1] <- a$code
      x[2] <- a$name
      
      converted[[i]] <- x
   }
   
   df <- data.frame( matrix( unlist(converted), nrow=length(all), byrow =T) )
   colnames(df) <- c( 'SetCode','SetName')
   x <- read.csv( 'mtg-database/data_prep/set_names.csv' )
   x1 <- x$SetName
   y <- df$SetName
   z <- setdiff( y, x1 )
}



# for ( i in 1:length(z) ){
#    dual <- df[ df$SetName == z[i], ] 
#    
#    
#    # Add Set to local file
#    # Add Set to database
#    # Add set's printings to database
#    
# }

#write.csv( df, 'mtg-database/data_prep/set_names.csv', row.names = F, quote = F)

#update_card_names()