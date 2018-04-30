library(magrittr)
library(shiny)
library(rhandsontable)

empty <- data.frame( QTY=as.integer(0), Name=rep('',20), SetName = rep('',20),
                                    Foil=rep(FALSE,20), Notes=rep('',20))


name_source <- readLines('mtg-database/data_prep/card_names.txt' )

set_source <- read.csv( 'mtg-database/data_prep/set_names.csv' )
set_source <- set_source$SetName

binders <- list()
binders[[1]] <- list( title = 'Currently Used',
                      short = 'play',
                      table = 'play' )
binders[[2]] <- list( title = 'Trade Binder',
                      short = 'trade',
                      table = 'trade' )
binders[[3]] <- list( title = 'Wishlist',
                      short = 'wish',
                      table = 'wish' )

source( 'mtg-database/transactions.R' )
source( 'C:/Users/Dustin/Desktop/config.R')
                      
   

sidebar <- function(){
   sidebarPanel(
      helpText("Hello, my name is Dustin and this is my MTG Database.", 
                 "As you can see, this is a rough work in progress.", 
                 "Try not to add any storm crows!"),
      br(),
      wellPanel(
         actionButton("clear", "Clear Input Table"),
         checkboxInput('ac_name',"Autocorrect Name"),
         checkboxInput('ac_set',"Autocorrect Set")
      ),
      load_btns(),
      edit_btns(),
      empty_btns()
   )
}
load_btns <- function(){
   wellPanel(
      h3("Load into Binders"), 
      lapply( binders, function(X){
         actionButton( paste0( 'to_', X$short), 
                       paste0( 'To ', X$title) )
      })
   )
}

edit_btns <- function(){
   wellPanel(
      h3("Edit Binders "),
      lapply( binders, function(X){
         actionButton( paste0( 'ed_', X$short),
                       paste0( 'To ', X$title) )
         }),
      br(),
      actionButton( "commit", "Commit Changes" )
   )
}
empty_btns <- function(){
   wellPanel(
      h3("Empty Binders (PLZ BE CAREFUL)"),
      lapply( binders, function(X) {
         actionButton( paste0( 'em_', X$short),
                       paste0( 'Empty ', X$title) )
         })
      )
}

tables_ui <- function(){
   mainPanel(
      rHandsontableOutput("hot"),
      lapply( binders, function(X) {
         br()
         h3( X$title )
         rHandsontableOutput(paste0( 'tb_', X$short) )
      })
   )
}

init_values <- function(){
   
   values <- reactiveValues()
   conn <- connect()
   lapply( binders, function(X) {
      values[[ X$short ]] <- binder_to_short( conn, X$table )
   })
   values[["active"]] <- ''
}

edit_table_server <- function(DF){
   observe({
      if (!is.null(input$hot)) {
        DF = hot_to_r(input$hot)
      } else {
        if (is.null(values[["DF"]]))
          DF <- DF
        else
          DF <- values[["DF"]]
      }
      values[["DF"]] <- DF
    })
}

the_app <- function(){
   
   ui <- fluidPage(
      
   titlePanel("Dustin's Database"),
   sidebarLayout(
      sidebar(),
      tables_ui()
      )
   )
   
   server <- function(input,output){
      init_values()
      edit_table_server( empty )
   }
   
   
   shinyApp(ui, server)
}

the_app()