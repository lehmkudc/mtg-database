# Initialized dataframe for debugging.
play <- data.frame( QTY = as.integer(c(3,2,0,0,0,0)), 
                  Name = c('Bomat Courier','Hazoret the Fervent','','','',''),
                  Set = c('KLD','AKH','','','',''),
                  Foil = c(F,T,T,F,F,F),
                  Notes = c('derp','','','','','')
)
# Large empty database for the hot table
empty <- data.frame( QTY=as.integer(0), Name=rep('',20), Set = rep('',20),
                                    Foil=rep(FALSE,20), Notes=rep('',20))

name_source <- scan(  "mtg-database/card-names", what=character(),sep = '\n' )
library(magrittr)


editTable <- function(DF, user,password,dbname,host){
   
  ui <- shinyUI(fluidPage(

    titlePanel("Dustin's Database"),
    sidebarLayout(
      sidebarPanel(
        helpText("Hello, my name is Dustin and this is my MTG Database.", 
                 "As you can see, this is a rough work in progress.", 
                 "Try not to add any storm crows!"),

        br(),
        wellPanel(
          actionButton("clear", "Clear Input Table") 
        ),
        
        # Loading Buttons
        wellPanel(
           h3("Load into Binders"), 
           actionButton("to_play", "To My Binder"),
           actionButton("to_trade", "To Trade Binder"),
           actionButton("to_wish", "To Wishlist")
        ),
        # Editing Buttons
        wellPanel(
           h3("Edit Binders "),
           actionButton("ed_play", "Edit My Binder"),
           actionButton("ed_trade", "Edit Trade Binder"),
           actionButton("ed_wish", "Edit Wishlist"),
           br(),
           actionButton("commit", "Commit Changes")
        ),
        
        # Emptying Buttons
        wellPanel(
           h3("Empty Binders (PLZ BE CAREFUL)"),
           actionButton("em_play", "Empty My Binder"),
           actionButton("em_trade", "Empty Trade Binder"),
           actionButton("em_wish", "Empty Wishlist")
        )
        

      ),
      
      # Table Outputs on UI
      mainPanel(
        rHandsontableOutput("hot"),
        br(), h3('Owned Binder'),
        rHandsontableOutput("play"),
        br(), h3('Trade Binder'),
        rHandsontableOutput("trade"),
        br(), h3('Wishlist Binder'),
        rHandsontableOutput("wish")
      )
    )
  ))

# ======================================================================= #  
  
  server <- shinyServer(function(input, output) {

     # Reactive Values and initializations
    values <- reactiveValues()
    values[["play"]] <- show_binder( user,password,dbname,host, 'play_binder')
    values[["trade"]] <- show_binder(user,password,dbname,host,  'trade_binder')
    values[["wish"]] <- show_binder(user,password,dbname,host, 'wish_binder')
    values[["active"]] <- ''
    
    # Editable Hot Table
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

    # Rendering Tables to output =====================================
    output$hot <- renderRHandsontable({
       DF <- values[["DF"]]
      if (!is.null(DF))
         rhandsontable(DF, useTypes = T)%>% 
         hot_col(col='Name', type ='autocomplete', source = name_source, strict = T)
    }) 
    
    output$play <- renderRHandsontable({
       Splay <- values[["play"]]
       rhandsontable(Splay, useTypes = T, stretchH="all")
    })
    output$trade <- renderRHandsontable({
       Strade <- values[["trade"]]
       rhandsontable(Strade, useTypes = T, stretchH="all")
    })
    output$wish <- renderRHandsontable({
       Swish <- values[["wish"]]
       rhandsontable(Swish, useTypes = T, stretchH="all")
    })

    
    observeEvent( input$clear, {
       values[["DF"]] <- empty
    })
    
    
    ## Loading Buttons ===============================================
    observeEvent(input$to_play, {
      finalDF <- isolate(values[["DF"]])
      if( nrow(trim_dataframe(finalDF)) > 0 ){
         from_table_to_binder(user,password,dbname,host, finalDF, 'play_binder')
         values[["DF"]] <- empty
         values[["play"]] <- show_binder(user,password,dbname,host, 'play_binder')
      }
    })
    
    observeEvent(input$to_trade, {
      finalDF <- isolate(values[["DF"]])
      if( nrow(trim_dataframe(finalDF)) > 0 ){
         from_table_to_binder(user,password,dbname,host,finalDF,'trade_binder')
         values[["DF"]] <- empty
         values[["trade"]] <- show_binder(user,password,dbname,host, 'trade_binder')
      }
    })
    
    observeEvent(input$to_wish, {
      finalDF <- isolate(values[["DF"]])
      if( nrow(trim_dataframe(finalDF)) > 0 ){
         from_table_to_binder(user,password,dbname,host,finalDF,'wish_binder')
         values[["DF"]] <- empty
         values[["wish"]] <- show_binder(user,password,dbname,host,'wish_binder')
      }
    })
    
    # Editing Buttons ===================================================
    observeEvent( input$ed_play, {
       values[["DF"]] <- show_binder(user,password,dbname,host,'play_binder')
       values[["active"]] <- 'play_binder'
    })
    observeEvent( input$commit, {
       print( 'button pressed')
       if (values[["active"]] != ''){
          print( 'in loop')
          mydb <- connect(user,password,dbname,host)
          print( 'connected')
          empty_binder( mydb, values[["active"]] )
          print( 'binder emptied')
          dbDisconnect(mydb)
          print( 'disconected')
          finalDF <- isolate(values[["DF"]])
          print( finalDF )
          from_table_to_binder(user,password,dbname,host, finalDF, values[["active"]])
          print( 'moved')
          values[["DF"]] <- empty
          values[["play"]] <- show_binder(user,password,dbname,host,'play_binder')
          values[["trade"]] <- show_binder(user,password,dbname,host,'trade_binder')
          values[["wish"]] <- show_binder(user,password,dbname,host,'wish_binder')
          
          
          values[["active"]] <- ''
       }
       
    })
    
    
    
    
    # Emptying Buttons ================================================
    observeEvent( input$em_play, {
       mydb <- connect(user,password,dbname,host)
       empty_binder(mydb, 'play_binder')
       dbDisconnect(mydb)
       values[["play"]] <- show_binder(user,password,dbname,host,'play_binder')
    })
    observeEvent( input$em_trade, {
       mydb <- connect(user,password,dbname,host)
       empty_binder(mydb, 'trade_binder')
       dbDisconnect(mydb)
       values[["trade"]] <- show_binder(user,password,dbname,host,'trade_binder')
    })
    observeEvent( input$em_wish, {
       mydb <- connect(user,password,dbname,host)
       empty_binder(mydb, 'wish_binder')
       dbDisconnect(mydb)
       values[["wish"]] <- show_binder( user,password,dbname,host,'wish_binder')
    })
    
    

  })

  ## run app 
  shinyApp(ui = ui, server = server)
  # runApp(list(ui=ui, server=server))
  # return(invisible())
}