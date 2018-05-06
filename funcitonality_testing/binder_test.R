source( 'mtg-database/init_script.R' )





create_binder <- function(title_name, short_name, table_name){
   # Open Binder
   binders <- list.load( 'mtg-database/binders.rdata') 

   # Add to mySQL
   pk_id <- paste0( "`", tools::toTitleCase(short_name), "ID`" )
   q <- paste0("CREATE TABLE `magic`.`", table_name, "` ( `",
               tools::toTitleCase(short_name), "ID` INT NOT NULL AUTO_INCREMENT, ",
               "`PrintID` INT NULL, ",
               "`Foil` TINYINT(1) NULL DEFAULT 0, ",
               "`Notes` VARCHAR(45) NULL, ",
               "`Mult` DECIMAL(3,2) NULL DEFAULT 1, ",
               "`Price` DECIMAL(9,2) NULL DEFAULT 0, ",
               "`Fresh` DATE NULL DEFAULT '2000-01-01', ",
               "PRIMARY KEY (", pk_id, "));" )
   print( q )
   conn <- connect()
   dbSendQuery( conn, q )
   dbDisconnect( conn )
   
   # Add to local information
   
   binders[[ length(binders) + 1 ]] <- list( title = title_name,
                                             short = short_name,
                                             table = table_name )
   # Add to file cache
   list.save( binders, 'mtg-database/binders.rdata')
}

delete_binder <- function(table_name){
   binders <- list.load( 'mtg-database/binders.rdata' )
   
   for( i in 1:length(binders) ){
      if ( binders[[i]]$table == table_name){
         # Remove the selected binder
         binders <- binders[ -i ]
         
         # Delete binder from MySQL
         q <- paste0( "DROP TABLE `magic`.`", table_name, "`;" )
         conn <- connect()
         dbSendQuery( conn, q )
         dbDisconnect( conn )
         
         
         # Remove from file cache
         list.save( binders, 'mtg-database/binders.rdata')
         
      }
      
   }
   
}


#delete_binder( 'test' )

#create_binder( 'Standard: Hazored', 'hazored','hazored' )

#create_binder( 'TESTING', 'test', 'test' )
dashboard()
#select_table( 'play' )
# update_prices( 'play' )
