source('mtg-database/transaction_functions.R')



# DF <- data.frame(Value = 1:10, Status = TRUE, Name = LETTERS[1:10],
#                     Date = seq(from = Sys.Date(), by = "days", length.out = 10),
#                     stringsAsFactors = FALSE)
kill_connections('192.168.1.147')

# mydb <- connect('10.1.10.150')
# # 
# #points <- c(1,2,3,4,5)
# #delete_pointed( points, 'trade_binder')
# play <- select_binder(mydb, 'play_binder') 
# # 
# dbDisconnect(mydb)

play <- data.frame( QTY = as.integer(c(3,2,0,0,0,0)), 
                  Name = c('Bomat Courier','Hazoret the Fervent','','','',''),
                  Set = c('KLD','AKH','','','',''),
                  Foil = c(F,T,T,F,F,F),
                  Notes = c('derp','','','','','')
)
empty <- data.frame( QTY=as.integer(0), Name=rep('',20), Set = rep('',20),
                                    Foil=rep(FALSE,20), Notes=rep('',20))
# play <- data.frame( QTY=as.integer(0), Name=rep('',20), Set = rep('',20),
#                     foil=rep(FALSE,20), Notes=rep('',20))

editTable <- function(DF, IP_address){
  ui <- shinyUI(fluidPage(

    titlePanel("Edit and save a table"),
    sidebarLayout(
      sidebarPanel(
        helpText("Hello, my name is Dustin and this is my MTG Database.", 
                 "As you can see, this is a rough work in progress.", 
                 "Try not to add any storm crows!"),

        br(), 

        wellPanel(
           h3("Load into Binders"), 
           actionButton("to_play", "To My Binder"),
           actionButton("to_trade", "To Trade Binder"),
           actionButton("to_wish", "To Wishlist")
        ),
        wellPanel(
           h3("Empty Binders (PLZ BE CAREFUL)"),
           actionButton("em_play", "Empty My Binder"),
           actionButton("em_trade", "Empty Trade Binder"),
           actionButton("em_wish", "Empty Wishlist")
        )

      ),

      mainPanel(
        rHandsontableOutput("hot")
 #       rHandsontableOutput("play")
      )
    )
  ))

  server <- shinyServer(function(input, output) {

    values <- reactiveValues()
    #values[["play"]] <- show_binder( IP_address, 'play_binder')

    ## Handsontable
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
    
    # output$play <- renderRHandsontable({
    #    Splay <- values[["play"]]
    #    rhandsontable(Splay, useTypes = T, stretchH="all")
    # })

    ## Save 
    observeEvent(input$to_play, {
      finalDF <- isolate(values[["DF"]])
      if( nrow(trim_dataframe(finalDF)) > 0 ){
         from_table_to_binder(IP_address, finalDF, 'play_binder')
         print( trim_dataframe(finalDF ))
         values[["DF"]] <- empty
         #values[["play"]] <- show_binder( IP_address, 'play_binder')
      }
    })
    
    observeEvent(input$to_trade, {
      finalDF <- isolate(values[["DF"]])
      if( nrow(trim_dataframe(finalDF)) > 0 ){
         from_table_to_binder(IP_address,finalDF,'trade_binder')
         print( trim_dataframe(finalDF ))
         values[["DF"]] <- empty
      }
    })
    
    observeEvent(input$to_wish, {
      finalDF <- isolate(values[["DF"]])
      if( nrow(trim_dataframe(finalDF)) > 0 ){
         from_table_to_binder(IP_address,finalDF,'wish_binder')
         print( trim_dataframe(finalDF ))
         values[["DF"]] <- empty
      }
    })
    
    observeEvent( input$em_play, {
       mydb <- connect(IP_address)
       empty_binder(mydb, 'play_binder')
       dbDisconnect(mydb)
    })
    observeEvent( input$em_trade, {
       mydb <- connect(IP_address)
       empty_binder(mydb, 'trade_binder')
       dbDisconnect(mydb)
    })
    observeEvent( input$em_wish, {
       mydb <- connect(IP_address)
       empty_binder(mydb, 'wish_binder')
       dbDisconnect(mydb)
    })
    
    

  })

  ## run app 
  shinyApp(ui = ui, server = server)
  # runApp(list(ui=ui, server=server))
  # return(invisible())
}


editTable( play, '192.168.1.147' )
