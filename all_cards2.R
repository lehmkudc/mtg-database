rm( list=ls() )

library(rjson)
options(stringsAsFactors = FALSE)

all <- fromJSON(file= 'https://api.scryfall.com/catalog/card-names')

t <- unlist(all$data,use.names = F)
t1 <- iconv(t, to = "ASCII//TRANSLIT")
t2 <- gsub( '"', '', t1)
t3 <- gsub( ' //.+', '', t2)



#write( all, "mtg-database/card-names.json")
df <- read.csv('mtg-database/all-cards.csv')
grep( '"', df$CardName)
