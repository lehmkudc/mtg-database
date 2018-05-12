source( 'mtg-database/init_script.R' )



virtual_binder <- function( binder ){
   conn <- connect()
   df <- binder_to_short( conn, binder )
   dbDisconnect( conn )
   
   
   # Get cache squared away
   for ( i in 1:nrow( df ) ){
      # Does Image exist in cache?
      
      # If so, output it
      
      
      # If not, get it in cache, then output it.
   
   }
   
   
   
   
   # Output all images needed for cache
}


card_img_url <- function( set_code, cnum, promo){
   url <- paste0( "https://img.scryfall.com/cards/normal/en/",
                  set_code, "/", cnum, ".jpg" )

   return( url )
}


fogey <- get_card( 'unh', 106, promo = T)

a1 <- iconv(fogey$collector_number, to = "ASCII//TRANSLIT")
fogey$collector_number

card_img_url( 'unh', a1, 0)


get_card( 'unh', a1, promo = F)
