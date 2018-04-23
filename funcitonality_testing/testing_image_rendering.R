rm( list=ls() )
library(shiny)
library(rjson)

file_name <- paste0('mtg-database/cached_images/' ,'bolt', '_', 'a25', '.jpg')
   

ui <- fluidPage(
   imageOutput( "bolt" ),
   
   lapply( 1:3, function(i){
      imageOutput( paste0( "bolt",i) )
   })

)

server <- function(input, output, session) {
   
   output[["bolt"]] <- renderImage({
     list( src = file_name,
           alt='bolt') 
   }, deleteFile = F)
   
   lapply( 1:3, function(i){
      output[[paste0('bolt',i)]] <- renderImage({
         list( src = file_name,
           alt=paste0('bolt',i))
      },deleteFile =F)
   })
}

actual_app <- function(){
   shinyApp(ui = ui, server = server)
}

actual_app()