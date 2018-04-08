rm( list=ls())
library(shiny)

source('mtg-database/transaction_functions.R')



ui <- fluidPage(
   
   titlePanel("Play Binder"
   ),
   fluidRow(
      column( 12, tableOutput('play'))
   ),
   titlePanel("Trade Binder"
   ),
   fluidRow(
      column( 12, tableOutput('trade'))
   ),
   titlePanel("Wish Binder"
   ),
   fluidRow(
      column( 12, tableOutput('wish'))
   )
)
   
server <- function(input,output){
   mydb <- connect('10.1.10.166')
   
   play <- select_binder(mydb, 'play_binder')
   output$play <- renderTable(play)
   trade <- select_binder(mydb, 'trade_binder')
   output$trade <- renderTable(trade)
   wish <- select_binder(mydb, 'wish_binder')
   output$wish <- renderTable(wish)
   
   dbDisconnect(mydb)
   
}

shinyApp(ui = ui, server = server)