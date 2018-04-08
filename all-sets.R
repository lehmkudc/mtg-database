library(rjson)
rm( list=ls())
options(stringsAsFactors = FALSE)

all <- fromJSON(file= 'mtg-database/AllSets.json')

N = length( all )
all[[1]]$onlineOnly

converted <- list()
for (i in 1:N ){
   x <- rep(0, 3)
   a <- all[[i]]
   
   
   x[1] <- a$code
   x[2] <- iconv( a$name, to = "ASCII//TRANSLIT")
   x[3] <- ifelse( length(a$onlineOnly) == 0, 1, 0)
   
   converted[[i]] <- x
}


df <- data.frame( matrix( unlist(converted), nrow=N, byrow =T) )
colnames(df) <- c( 'SetID','SetName','Paper')

write.csv(x = df,file = 'mtg-database/all_sets.csv',row.names = F)