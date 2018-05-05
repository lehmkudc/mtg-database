source( 'mtg-database/init_script.R' )


test_df <-  data.frame( QTY = 4, CardName = 'Ahn-Crop Crasher',
                        SetName = 'Amonkhet', Foil = 0,
                        Notes = '', Mult = 1 )
   
#test_df

#short_to_long( test_df )
#select_table( 'load_zone' )

#conn <- connect()
#load_all( conn, test_df )
#dbDisconnect( conn )

dashboard()