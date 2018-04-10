rm( list=ls() )

options(stringsAsFactors = FALSE)
library(RMySQL)
library(rhandsontable)
library(shiny)

x<- 'testing info'


dummy_app <- function(){
   ui1 <- shinyUI(fluidPage(
      titlePanel('Yay!')
   ))
   server1 <- shinyServer(function(input, output) {

   })
   
   shinyApp(ui = ui1, server = server1)
}




ui <- shinyUI(fluidPage(
   h3(x),
   actionButton('new_app','New App')
   
))

server <- shinyServer(function(input, output) {
   observeEvent( input$new_app, {
      dummy_app()
   })
   
})

shinyApp(ui = ui, server = server)