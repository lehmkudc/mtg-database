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
      
      imageOutput( "bolt" ),
      
      apply( v_data, 1, function(x){
         wellPanel(
            h3( paste0(x[2], '_', x[3] ) ),
            imageOutput( paste0(x[2], '_', x[3] ) )
            #h3(paste( 'QTY:', v_data$QTY[i]) )
         #br()
         )
      })
      
   )
   
   server <- function(input, output){
      
      file_name <- normalizePath( file.path( 'mtg-database/cached_images',
                                             paste0('bolt', '_', 'a25', '.jpg') ) )
      output[["bolt"]] <- renderImage({
         list( src = file_name,
               alt='bolt') 
      }, deleteFile = F)
      
      apply( v_data, 1, function(x){
         output[[paste0(x[2],'_',x[3])]] <- renderImage({
            name <- normalizePath( file.path( 'mtg-database/cached_images',
                                             paste0(x[2], '_', x[3], '.jpg')))
            label <- paste0( x[2],'_',x[3] )
            return(list( src=name,alt=label))}, deleteFile=F)
      })
      
      # lapply( 1:N, function(i){
      #    output[[paste0(v_data$SetCode[i],'_',v_data$CNumber[i])]] <- renderImage({
      #       
      #       name <- normalizePath( file.path( 'mtg-database/cached_images',
      #                                         paste0( v_data$SetCode[i],'_',v_data$CNumber[i],'.jpg' ) ) )
      #       label <- paste0(v_data$SetCode[i],'_',v_data$CNumber[i])
      #       print( name)
      #       print( label )
      # 
      #       list( src = name,
      #             alt = label )
      #    }, deleteFile = F )
      # })
   }

   shinyApp(ui=ui, server=server)
}


v_b2 <- function( binder ){
   
   update_cache( binder )
   v_data <- get_v_data( binder )
   N <- nrow( v_data )
   
   
   ui <- fluidPage(
      sidebarLayout(
         sidebarPanel(
            fileInput( inputId = 'files',
                       label = 'select and Image',
                       multiple = TRUE,
                       accept = c('image/png','image/jpeg'))
         ),
         mainPanel( 
            tableOutput( 'files' ),
            uiOutput( 'image')
         )
      )
   )
      
   server <- function( input, output, session){
      output$files <- renderTable( input$files )
      
      files <- reactive({
         files <- input$files
         #files$datapath <- gsub
         files
      })
      
      output$images <- renderUI({
         image_output_list <- 
            lapply( 1:nrow( files()),
                    function( i )
                    {
                       imagename = paste0(v_data$SetCode[i], '_', v_data$CNumber[i] )
                       imageOutput( imagename )
                    })
         do.call( tagList, image_output_list )
      })
      
      observe({
         for (i in 1:nrow(files()))
         {
            print( i )
            local({
               my_i <- i
               imagename =  paste0(v_data$SetCode[i], '_', v_data$CNumber[i] )
               print(imagename)
               output[[imagename]] <- 
                  renderImage({
                     list( src = files()$datapath[my_i],
                           alt = 'Image failed to render')
                  }, deleteFile = F )
            })
         }
      })
   }
         
   shinyApp( ui = ui, server = server )
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

v_b2( 'held_binder' )

#card_img_url( 'unh','106q')

#binder_cards <- get_v_data( 'held_binder' )

#update_cache( 'held_binder' )

#( 'held_binder' )

#only_bolt()
