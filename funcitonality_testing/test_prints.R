rm( list=ls() )
library(rjson)
options(stringsAsFactors = FALSE)

source('mtg-database/transaction_functions.R')
source('C:/Users/Dustin/Desktop/config.R')
source('mtg-database/app_functions.R')



api <- 'https://api.scryfall.com/cards/search?q=e:unh&unique=prints'

set_code <- 'unh'
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
      
      print( x )
   }
   if ( page$has_more == F ){
      end <- T
   } else {
      page <- fromJSON(file= as.character(page$next_page) )
   }
}

nchar( 'Our market research suggests that players')
