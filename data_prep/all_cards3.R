rm( list=ls() )
library(rjson)
options(stringsAsFactors = FALSE)


page <- fromJSON(file= 'https://api.scryfall.com/cards')
end <- F
storage <- list()
index <- 0
cat_color <- function( ac, typeline ){
   if ( length(ac) == 0 ){
      if ( length(grep( 'Land', typeline)) > 0 ){
         x <- 7
      } else {
         x <- 6
      }
   } else if ( length(ac) > 1 ){
      x <- 5
   } else if ( ac == 'G' ){
      x <- 4
   } else if ( ac == 'R' ){
      x <- 3
   } else if ( ac == 'B' ){
      x <- 2
   } else if ( ac == 'U' ){
      x <- 1
   } else if ( ac == 'W' ){
      x <- 0
   } else {
      x <- 'PANIC'
   }
   return(x)
}


while ( end == F ){ # Per Page
   N_cards <- length( page$data )
   
   for (i in 1:N_cards){ # For Each Card
      index <- index + 1
      card <- page$data[[i]]
      
      x <- rep( 0, 5)
      
      
      if ( length(card$card_faces) == 0 ){
         
         x[1] <- iconv( card$name, to = "ASCII//TRANSLIT")
         x[1] <- gsub( '"', '', x[1])
         x[1] <- gsub( ' //.+', '', x[1])
      
         x[2] <- cat_color( card$colors, card$type_line )
         
      } else {
         cf <- card$card_faces[[1]]
         
         x[1] <- iconv( cf$name, to = "ASCII//TRANSLIT")
         x[1] <- gsub( '"', '', x[1])
         x[1] <- gsub( ' //.+', '', x[1])
   
         x[2] <- cat_color( cf$colors, cf$type_line )
      }
      
      if ( card$cmc > 20 ){
         x[3] <- 20
      } else {
         x[3] <- floor( card$cmc )
      }
      
      x[4] <- iconv( card$set, to = "ASCII//TRANSLIT")
#      x[4] <- iconv( card$set_name, to = "ASCII//TRANSLIT")
      x[5] <- iconv( card$uri, to = "ASCII//TRANSLIT")
      
      storage[[index]] <- x
   }

   if ( page$has_more == F ){
      end <- T
   } else {
      page <- fromJSON(file= as.character(page$next_page) )
   }
   
}

df <- data.frame( matrix( unlist(storage), nrow=index, byrow =T) )
colnames(df) <- c( 'CardName','ColorID','CMC','SetCode','Uri')
write.csv(x = df,file = 'mtg-database/all_cards2.csv',row.names = F)


card$uri
