rm(list = ls())
library(shiny)


henlo <- function(){
   h2( "Hello Function")
   
}


ui <- fluidPage(
   h1( "Hello World" ),
   henlo()
)

server <- function( input, output){
   
   
   
}


the_app <- function(){
   shinyApp(ui, server)
}

the_app()