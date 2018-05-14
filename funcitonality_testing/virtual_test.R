source( 'mtg-database/init_script.R' )

get_label <- function( set_code, cnumber){
   return( paste0( set_code, '_', cnumber ) )
}

get_filename <- function( set_code, cnumber){
   return( paste0( set_code, '_', cnumber, '.jpg' ) )
}

get_full <- function( set_code, cnumber){
   
   filename <- get_filename( set_code, cnumber)
   return( paste0( 'mtg-database/cached_images/', filename) )
   
}
get_v_data <- function( binder ){
   
   q <- paste( "SELECT COUNT(*) AS QTY, SetCode, CNumber,ROUND( Mult*Price, 2)",
               "AS PerCard FROM", binder, "AS b",
               "JOIN all_prints AS p ON p.PrintID = b.PrintID",
               "JOIN all_sets AS s ON s.SetID = p.SetID",
               "GROUP BY SetCode, CNumber, Mult, Price;" )
               
   conn <- connect()
   
   v_data <- fetch( dbSendQuery( conn, q ) )
   
   dbDisconnect( conn )
   
   return( v_data )
}

update_cache <- function( binder ){
   v_data <- get_v_data( binder )
   
   # Get cache squared away
   for ( i in 1:nrow( v_data ) ){
      # Get the names
      filename <- paste0( v_data$SetCode[i], '_', v_data$CNumber[i], '.jpg' )
      full <- paste0( 'mtg-database/cached_images/', filename)
      url <- card_img_url( v_data$SetCode[i], v_data$CNumber[i] )
      # Does Image exist in cache?
      if( !filename %in% list.files('mtg-database/cached_images') ){
         download.file( url, full, mode='wb' )
      }
   }
}

card_img_url <- function( set_code, cnumber){
   cnumber <- gsub( 'q', '%E2%98%85', cnumber )
   url <- paste0( "https://img.scryfall.com/cards/normal/en/",
                  set_code, "/", cnumber, ".jpg" )
   return( url )
}

virtual_binder <- function( binder ){
   update_cache( binder )
   v_data <- get_v_data( binder )
   N <- nrow( v_data )
   
   ui <- fluidPage(
      
      lapply( 1:N, function(i){
         img( src = get_full( v_data$SetCode[i], v_data$CNumber[i]) )
         
         
      }),
      
      lapply( 1:N, function(i){
         imageOutput( get_label(v_data$SetCode[i], v_data$CNumber[i]) )
         #h3(paste( 'QTY:', v_data$QTY[i]) )
         #br()
      })
      
   )
   
   server <- function(input, output){
      
      lapply( 1:N, function(i){
         output[[get_label(v_data$SetCode[i], v_data$CNumber[i])]] <- renderImage({
            full <- get_full(v_data$SetCode[i], v_data$CNumber[i] )
            label <- get_label(v_data$SetCode[i], v_data$CNumber[i])
                             
            list( src = full,
                  alt = label )
         }, deleteFile = F )
      })
      
      
   }

   shinyApp(ui=ui, server=server)
}

only_bolt <- function(){
   file_name <- paste0('mtg-database/cached_images/' ,'bolt', '_', 'a25', '.jpg')
   
   ui <- fluidPage(
      imageOutput( "bolt" )
      
   )
   
   server <- function(input, output, session) {
      
      output[["bolt"]] <- renderImage({
         list( src = file_name,
               alt='bolt') 
      }, deleteFile = F)
      
   }
   
   shinyApp(ui = ui, server = server)
   
}

#card_img_url( 'unh','106q')

#binder_cards <- get_v_data( 'held_binder' )

#update_cache( 'held_binder' )

virtual_binder( 'held_binder' )

#only_bolt()
