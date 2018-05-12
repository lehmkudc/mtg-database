rm( list=ls() )
library(rjson)
options(stringsAsFactors = FALSE)



all <- fromJSON( file = 'https://api.scryfall.com/cards/search?q=is:promo' )
end <- F
codes <- c()

while( end == F ){
   for ( i in 1:length(all$data) ){
      card <- all$data[[i]]
      cn <- card$collector_number
      
      if ( grepl('\\D', cn, perl=F) == T){
         
         
         if( iconv(cn, to = "ASCII//TRANSLIT") != cn ){
            print( paste( card$name, card$set, cn) )
            print( gsub( '\\D', 'q', cn, perl=F))
         }
         
         gn <- gsub( '\\d', '', cn, perl=F)
         if( gn %in% codes ){
         } else {
            codes <- c( codes, gn)
            print( codes )
         }
         
      }
      
   }
   
   if ( all$has_more == T){
      all <- fromJSON( file = all$next_page)
   } else {
      end == T
   }
   Sys.sleep( 1 )
}