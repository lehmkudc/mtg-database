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
                       paste0( 'Edit ', X$title) )
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

tables_ui <- function(id){
   mainPanel(
      rHandsontableOutput(id),
      lapply( binders, function(X) {
         br()
         h3( X$title )
         rHandsontableOutput(paste0( 'tb_', X$short) )
      })
   )
}

init_values <- function(input, output, session){
   
   values <- reactiveValues()
   conn <- connect()
   lapply( binders, function(X) {
      values[[ X$short ]] <- binder_to_short( conn, X$table )
   })
   values[["active"]] <- ''
   dbDisconnect( conn) 
   return( values )
}

edit_table_server <- function(DF, values, input, output, session){
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
   
   output$hot <- renderRHandsontable({
       DF <- values[["DF"]]
       if (!is.null(DF)){
          if (input$ac_name & input$ac_set){
            rhandsontable(DF, useTypes = T)%>% 
            hot_col(col='Name', type ='autocomplete', 
                    source = name_source, strict = T)%>%
            hot_col(col='SetName', type ='autocomplete',
                    source = set_source, strict = T)
          } else if (input$ac_name & !input$ac_set) {
             rhandsontable(DF, useTypes = T)%>% 
                hot_col(col='Name', type ='autocomplete',
                        source = name_source, strict = T)
          } else if (!input$ac_name & input$ac_set) {
             rhandsontable(DF, useTypes = T)%>% 
                hot_col(col='SetName', type ='autocomplete',
                        source = set_source, strict = T)
          } else {
             rhandsontable(DF, useTypes = T)
          }
       }
    }) 
}


tables_server <- function(values, input, output, session){
   
   lapply( binders, function(X){
      output[[paste0( 'tb_', X$short)]] <- renderRHandsontable({
         if (!is.null( values[[X$short]] )){
            S <- values[[X$short]]
            rhandsontable( S, readOnly = T, useTypes = T, stretchH='all')
            }
         
      })
   })
   return(output)
}

clear_server <- function(values, input, output, session){
   observeEvent( input$clear, {
      values[["DF"]] <- empty
      values[['active']] <- ''
   })   
}

load_btns_server <- function( values, input, output, session ){
   
   lapply( binders, function(X){
      observeEvent( input[[paste0( 'to_', X$short)]], {
         finalDF <- isolate( values[["DF"]])
         if( nrow(trim_dataframe(finalDF)) > 0){
            short_to_binder( finalDF, X$table )
            values[["DF"]] <- empty
            conn <- connect()
            values[[X$short]] <- binder_to_short( conn, X$table )
            dbDisconnect( conn )
         }
         
      })
      
   })
   
}

the_app <- function(){
   # Function Wrapper to trick RStudio into running the whole code
   
   ui <- fluidPage(
      
      titlePanel("Dustin's Database"),
      sidebarLayout(
         
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
         ),
         
         mainPanel(
            rHandsontableOutput("hot"),
            lapply( binders, function(X) {
               br()
               h3( X$title )
               rHandsontableOutput(paste0( 'tb_', X$short) )
            })
         )
         )
      )
   
   server <- function(input,output,session){
      values <- init_values(input, output, session)
      edit_table_server( empty, values, input, output, session )
      output <- tables_server( values, input, output, session )
      clear_server(values, input, output, session)
      load_btns_server( values, input, output, session )
   }
   
   
   shinyApp(ui, server)
}

the_app()