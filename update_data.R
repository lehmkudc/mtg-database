rm( list=ls() )
library(rjson)
options(stringsAsFactors = FALSE)

source('mtg-database/transaction_functions.R')
source('C:/Users/Dustin/Desktop/config.R')
source('mtg-database/app_functions.R')

kill_connections()

add_card_name <- function(conn, card_name){
   card_name <- paste0( '"', card_name, '"' )
   q <- paste( 'INSERT INTO all_cards (CardName) VALUES',
                  '(', card_name, ');')
   sq <- dbSendQuery( conn, q )
}

add_set_name <- function( conn, set_name, set_code){
   set_name <- paste0( '"', set_name, '"' )
   set_code <- paste0( '"', set_code, '"' )
   
   q <- paste( 'INSERT INTO all_sets (SetName, SetCode)',
               'SELECT', set_name,',', set_code,
               'WHERE NOT EXISTS ( SELECT * FROM all_sets',
               'WHERE SetName =', set_name,
               'OR SetCode = ', set_code,
               ') LIMIT 1;' )
   dbSendQuery( conn, q)
}

add_print <- function( conn, card_name, set_code, cnum, promo ){
   #print( card_name)
   #print( set_code )
   card_name <- paste0( '"', card_name, '"' )
   set_code <- paste0( '"', set_code, '"')
   q1 <- paste( 'SELECT (SELECT CardID FROM all_cards',
                'WHERE CardName =', card_name,
                ') as CardID,(SELECT SetID FROM all_sets',
                'WHERE SetCode =', set_code,
                ') as SetID' )
   #print( q1 )
   sq1 <- dbSendQuery( conn, q1 )
   d1 <- fetch( sq1 )
   q2 <- paste( 'INSERT INTO all_prints ( SetID, CardID, CNumber, Promo)',
                'SELECT',
                '(SELECT SetID from all_sets WHERE SetCode = ', set_code,
                '),(SELECT CardID from all_cards WHERE CardName =', card_name,
                '),', cnum,',', promo,
                'WHERE NOT EXISTS ( SELECT * FROM all_prints',
                'WHERE SetID = (SELECT SetID from all_sets WHERE SetCode =', set_code,
                ') AND CardID = (SELECT CardID from all_cards WHERE CardName =', card_name,
                ') AND CNumber =', cnum, 'AND Promo =', promo, ');' )
   dbSendQuery( conn, q2 )
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
   full_json <- fromJSON(file= 'https://api.scryfall.com/sets')
   data_json <- full_json$data

   api_sets <- list()
   for ( i in 1:length(data_json) ){
      set_data <- rep(0,2)
      aset <- data_json[[i]]
      set_data[1] <- aset$code
      set_data[2] <- aset$name
      
      api_sets[[i]] <- set_data
   }
   api_sets <- data.frame( matrix( unlist(api_sets), nrow=length(data_json), byrow =T) )
   colnames(api_sets) <- c( 'SetCode','SetName')
   
   local_sets <- read.csv( 'mtg-database/data_prep/set_names.csv' )

   new_set_names <- setdiff( api_sets$SetName, local_sets$SetName )
   print( new_set_names )
   
   for ( i in 1:length(new_set_names) ){
      new_set <- api_sets[ api_sets$SetName == new_set_names[i], ]
      
      # Add Set to database
      conn <- connect()
      
      add_set_name( conn, new_set$SetName, new_set$SetCode )
      
      dbDisconnect( conn )
      # Add set's printings to database
      conn <- connect()
      
      add_set_prints(conn, new_set$SetCode)
      
      dbDisconnect(conn )
   
      # Add Set to local file
      local_sets <- rbind( local_sets, new_set )
      write.csv( local_sets, 'mtg-database/data_prep/set_names.csv',
                 row.names = F, quote = F)
      
   }
}

#=====================================================================

# update_sets()
# SELECT statement isnt 

# conn <- connect()
# 
# add_set_name( conn, 'unh' )
# 
# dbDisconnect( conn )

#nchar("Duel Decks Anthology: Divine vs. Demonic Tokens")
#write.csv( df, 'mtg-database/data_prep/set_names.csv', row.names = F, quote = F)

#update_card_names()