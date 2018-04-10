rm( list=ls())
library(rhandsontable)
library(shiny)
source('mtg-database/transaction_functions.R')


play <- data.frame( QTY = as.integer(c(3,2,0,0,0,0)), 
                  Name = c('Bomat Courier','Hazoret the Fervent','','','',''),
                  Set = c('KLD','AKH','','','',''),
                  Foil = c(F,T,T,F,F,F),
                  Notes = c('derp','','','','','') )

empty <- data.frame( QTY=as.integer(0), Name=rep('',20), Set = rep('',20),
                                    foil=rep(FALSE,20), Notes=rep('',20))

editTable <- function(DF){
   ui <- shinyUI(fluidPage(
      actionButton("restart", "Restart"),
      rHandsontableOutput("hot")
   ))
   
   server <- shinyServer(function(input, output) {
      values <- reactiveValues()
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
         if (!is.null(DF))
           rhandsontable(DF, useTypes = T, stretchH = "all")
      })
      
      observeEvent(input$restart, {
         finalDF <- isolate(values[["DF"]])
         finalDF <- trim_dataframe(finalDF)
         print( finalDF )
         values[["DF"]] <- empty
      })
   })
                  
   shinyApp(ui = ui, server = server)
}

editTable(play)
                  