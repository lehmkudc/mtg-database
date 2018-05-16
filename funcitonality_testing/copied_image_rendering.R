library(shiny)

vb <- function(binder){
   update_cache( binder )
   vdata <- get_v_data( binder )
   N <- nrow( vdata )
   server <- shinyServer(function(input, output) {
      output$files <- renderTable(input$files)
      
      files <- reactive({
         files <- input$files
         files$datapath <- gsub("\\\\", "/", files$datapath)
         files
      })
      
      
      output$images <- renderUI({
         if(is.null(input$files)) return(NULL)
         image_output_list <- 
            lapply(1:nrow(files()),
                   function(i)
                   {
                      v <- vdata[i,]
                      imagename = paste0(v$SetCode,'_',v$CNumber)
                      imageOutput(imagename)
                   })
         
         do.call(tagList, image_output_list)
      })
      
      observe({
         if(is.null(input$files)) return(NULL)
         for (i in 1:nrow(files()))
         {
            #print(i)
            local({
               my_i <- i
               v <- vdata[my_i,]
               imagename = paste0(v$SetCode,'_',v$CNumber)
               #print(imagename)
               output[[imagename]] <- 
                  renderImage({
                     list(src = files()$datapath[my_i],
                          alt = "Image failed to render")
                  }, deleteFile = FALSE)
            })
         }
         print( str(files()) )
      })
      

   })
   
   ui <- shinyUI(fluidPage(
      
      titlePanel("Uploading Files"),
      sidebarLayout(
         sidebarPanel(
            fileInput(inputId = 'files', 
                      label = 'Select an Image',
                      multiple = TRUE,
                      accept=c('image/png', 'image/jpeg'))
         ),
         mainPanel(
            tableOutput('files'),
            uiOutput('images')
         )
      )
   ))
   
   shinyApp(ui=ui,server=server)
   
}

vb('held_binder')