dashboard <- function(){
   # Function wrapper to trick RStudio into running entire code
   
   ui <- shinyUI(fluidPage(
      
      titlePanel("Magic the Gathering Collection Manager"),
      
      sidebarLayout(
         sidebarPanel(
            helpText("Hello, my name is Dustin and this is my MTG Database.", 
                     "As you can see, this is a rough work in progress.", 
                     "https://github.com/lehmkudc/mtg-database"),
            
            br(),
            wellPanel(
               # Operation of Edit Table
               actionButton("clear", "Clear Input Table"),
               checkboxInput('ac_name',"Autocorrect Name"),
               checkboxInput('ac_set',"Autocorrect Set", value=T)
            ),
            # Loading Buttons
            wellPanel(
               h3("Load into Binders"), 
               lapply( binders, function(X){
                  actionButton( paste0( 'to_', X$short), 
                                paste0( 'To ', X$title) )
               })
            ),
            # Editing Buttons
            wellPanel(
               h3("Edit Binders "),
               lapply( binders, function(X){
                  actionButton( paste0( 'ed_', X$short),
                                paste0( 'Edit ', X$title) )
               }),
               br(),
               actionButton("commit", "Commit Changes")
            ),
            # Emptying Buttons
            wellPanel(
               h3("Empty Binders (PLZ BE CAREFUL)"),
               lapply( binders, function(X) {
                  actionButton( paste0( 'em_', X$short),
                                paste0( 'Empty ', X$title) )
               })
            ),
            
            #Update Price Buttons
            wellPanel(
               h3("Update Prices"),
               lapply( binders, function(X) {
                  actionButton( paste0( 'up_', X$short),
                                paste0( 'Update ', X$title, ' Prices') )
               })
            )
         ),
         
         # Table Outputs on UI
         mainPanel(
            wellPanel(
               h3( 'Editing Table' ),
               rHandsontableOutput("hot")
            ),
            lapply( binders, function(X) {
               wellPanel(
                  h3( X$title ),
                  rHandsontableOutput(paste0( 'tb_', X$short) )
                  )
            })
         )
      )
   ))
   
   # ======================================================================= #  
   
   server <- shinyServer(function(input, output) {
      
      # Reactive Values and initializations

      values <- reactiveValues()
      conn <- connect()
      lapply( binders, function(X) {
         values[[ X$short ]] <- binder_to_short( conn, X$table )
      })
      dbDisconnect( conn )
      values[["active"]] <- ''
      
      # Edit table functionality to recognize user changes
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
      
      # Edit Table
      
      colw <- c( )
      output$hot <- renderRHandsontable({
         DF <- values[["DF"]]
         if( !is.null(DF) ){
            base <- rhandsontable(DF, useTypes = T, stretchH='all') %>%
            hot_context_menu( allowRowEdit = FALSE, allowColEdit = FALSE) %>%
            hot_col( col='Price', readOnly = T) %>%
            hot_col( col='Fresh', readOnly = T)
            if (input$ac_name & input$ac_set){
               base %>%
               hot_col( col='CardName', type ='autocomplete',
                       source = name_source, strict = T) %>%
               hot_col( col='SetName', type ='autocomplete',
                       source = set_source, strict = T)
            } else if (input$ac_name & !input$ac_set) {
               hot_col(base, col='CardName', type ='autocomplete',
                       source = name_source, strict = T)
            } else if (!input$ac_name & input$ac_set) {
               hot_col(base, col='SetName', type ='autocomplete',
                       source = set_source, strict = T)
            } else {
               base
            }
         }
      })
      
      # Binder Preview Windows
      lapply( binders, function(X){
         output[[paste0( 'tb_', X$short)]] <- renderRHandsontable({
            if (!is.null( values[[X$short]] )){
               S <- values[[X$short]]
               rhandsontable( S, readOnly = T, useTypes = T, stretchH='all')
            }
         })
      })
      
      
      ## Various Buttons =================================================
      
      # Clear Edit Table
      observeEvent( input$clear, {
         values[["DF"]] <- empty
         values[['active']] <- ''
      })
      
      # Load-in Buttons
      lapply( binders, function(X){
         observeEvent( input[[paste0( 'to_', X$short)]], {
            df_read <- isolate( values[["DF"]])
            df_trim <- trim_dataframe( df_read )
            if( nrow(df_trim) > 0){
               short_to_binder( df_trim, X$table )
               values[["DF"]] <- empty
               update_prices( X$table )
               conn <- connect()
               values[[X$short]] <- binder_to_short( conn, X$table )
               dbDisconnect( conn )
            }
         })
      })
      
      # Edit Buttons
      lapply( binders, function(X){
         observeEvent( input[[paste0( 'ed_', X$short)]], {
            conn <- connect()
            values[["DF"]] <- binder_to_edit( conn, X$table )
            values[["active"]] <- X$table
            dbDisconnect( conn )
         })
      })
      
      # Commit Edit
      observeEvent( input$commit, {
         if (values[["active"]] != ''){
            conn <- connect()
            empty_binder( conn, values[["active"]] )
            dbDisconnect( conn )
            finalDF <- isolate(values[["DF"]])
            short_to_binder( finalDF, values[["active"]])
            values[["DF"]] <- empty
            conn <- connect()
            update_prices( values[["active"]] ) 
            lapply( binders, function(X) {
               values[[X$short]] <- binder_to_short( conn, X$table )
            })
            values[["active"]] <- ''
            dbDisconnect( conn )
         }
      })
      
      # Empty Buttons
      lapply( binders, function(X){
         observeEvent( input[[paste0( 'em_', X$short )]], {
            conn <- connect()
            empty_binder( conn, X$short )
            values[[X$short]] <- binder_to_short( conn, X$table )
            dbDisconnect(conn )
         })
      })
      
      # Update Price Buttons
      lapply( binders, function(X){
         observeEvent( input[[paste0( 'up_', X$short)]], {
            update_prices( X$table )
            conn <- connect()
            values[[X$short]] <- binder_to_short( conn, X$table )
            dbDisconnect( conn )
         })
      })
   })
   
   ## APP Call ============================================================== 
   shinyApp(ui = ui, server = server)
}