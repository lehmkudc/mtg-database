library(rjson)
rm( list=ls())
options(stringsAsFactors = FALSE)

all <- fromJSON(file= 'mtg-database/AllCards.json')

N = length(all)

length(all[[1431]]$colors)==0

converted <- list()

for (i in 1:length(all)){
   x <- rep( 0, 4)
   a <- all[[i]]
   x[1] <- i
   x[2] <- iconv( a$name, to = "ASCII//TRANSLIT")
   x[2] <- gsub( '"', '', x[2])
   x[2] <- gsub( ' //.+', '', x[2])
   
   am <- a$cmc
   if ( am > 20 ){
      x[3] <- 20
   } else {
      x[3] <- floor( am )
   }

   ac <- a$colors
   
   if ( length(ac) == 0 ){
      if ( length(grep( 'Land', a$type)) > 0 ){
         x[4] <- 7
      } else {
         x[4] <- 6
      }
   } else if ( length(ac) > 1 ){
      x[4] <- 5
   } else if ( ac == 'Green' ){
      x[4] <- 4
   } else if ( ac == 'Red' ){
      x[4] <- 3
   } else if ( ac == 'Black' ){
      x[4] <- 2
   } else if ( ac == 'Blue' ){
      x[4] <- 1
   } else if ( ac == 'White' ){
      x[4] <- 0
   } else {
      x[4] <- 'PANIC'
   }
       
   
   converted[[i]] <- x
}


df <- data.frame( matrix( unlist(converted), nrow=N, byrow =T) )
colnames(df) <- c( 'CardID','CardName','CMC','ColorID')

write.csv(x = df,file = 'mtg-database/all-cards.csv',row.names = F)



      