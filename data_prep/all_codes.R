library(rjson)
rm( list=ls())
options(stringsAsFactors = FALSE)

all <- fromJSON(file= 'https://api.scryfall.com/sets')
all <- all$data
length(all)

converted <- list()
for ( i in 1:length(all) ){
   x <- rep(0,3)
   a <- all[[i]]
   x[1] <- a$code
   x[2] <- a$name
   
   converted[[i]] <- x
}

df <- data.frame( matrix( unlist(converted), nrow=length(all), byrow =T) )
colnames(df) <- c( 'SetCode','SetName')


write.csv(x = df,file = 'mtg-database/all_codes.csv',row.names = F)




write(df$SetName, 'mtg-database/set-names')

x<- scan(  "mtg-database/set-names", what=character(),sep = '\n' )
