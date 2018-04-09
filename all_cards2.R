rm( list=ls() )

library(rjson)
options(stringsAsFactors = FALSE)

all <- fromJSON(file= 'https://api.scryfall.com/catalog/card-names')

t <- unlist(all$data,use.names = F)
t1 <- iconv(t, to = "ASCII//TRANSLIT")
t2 <- gsub( '"', '', t1)
t3 <- gsub( ' //.+', '', t2)

t3[ grep( 'Our Market Research', t3) ] <- 'Our Market Research'


t3 <- t3[ order( t3)]
write( t3, "mtg-database/card-names")

x<- scan(  "mtg-database/card-names", what=character(),sep = '\n' )
