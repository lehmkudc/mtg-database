
cardlist <- 'mtg-database/test_cardlist.csv'
options(stringsAsFactors = FALSE)


load_prep <- function( csv ){
   df <- read.csv(csv,header = FALSE)
   
   total <- sum(df[,1])
   name <- rep(0,total)
   set <- rep(0,total)
   foil <- rep(0,total)
   notes <- rep(NA,total)
   
   j <- 1
   for (i in 1:nrow(df)){
      r <- j:(j +df[i,1]-1)
      name[ r ] <- df[i,2]
      set[ r ] <- df[i,3]
      foil[ r ] <- df[i,4]
      notes[r] <- df[i,5]
      j <- j+df[i,1]
   }
   
   out <- data.frame( name = name, set = set, foil = foil,notes = notes)
   return( out )
}







load_prep( cardlist )