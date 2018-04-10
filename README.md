# Magic the Gathering Database and Collection Manager

## At a Glance Status:
10 April 2018
I have recently finished the autocomplete features when entering in cards. 
I added a toggle feature as the autocomplete for card name was incredibly slow.
The new goal is to restructure the app program as to let other people interact with it without hard-coding my sensitive
information like passwords and IP address into the app. I may seek a web service to provide me another mySQL server to work with.
In general, the first prototype is finished as I planned it out.

## Q: What is this project about?
A: My goal is to create an app/dashboard that I can use to track and manage mine and my roommate's personal
Magic the Gathering collection. The data is stored in a mySQL server, and the dashboard app is made using RShiny.

## Q: What is Magic the Gathering?  
A: Magic the Gathering is a trading card game developed by Wizards of the Coast and owned by Hasbro. 
It's the most popular TCG in the country and has competitive tournaments all across the world. 
The recent 2017 World Championship boasted a first prize of $100,000. I play this game fairly competitively as well, 
and spend a fair amount of my time playing, theorycrafting, or otherwise interacting with Magic. 
As it is a successful TCG, many of its cards have significant value and even have their own seconday market, 
with single prices of cards reaching tens of thousands of dollars. 
Most repeat players have some sort of trading binder with cards displayed for trading, 
but the actual price of these cards varies depending on the market. 

## Q: Why make your own app when there are plenty available with more features?
A: I have plenty of reasons. In no particular order:
*This is fun for me. I enjoy data management and coding in R and have been looking for a good project as an excuse to get used to RShiny.
*Making my own app gives me more freedom with implementing features like autocompletion and inputing cards as tables.
*I wanted a solid SQL project for my portfolio

## Q: So overall how does this work?
A: The app as coded above interacts with a mySQL server database. 
The app has a series of buttons and tables that allow the user to make changes to the database with transactions.
These transactions are funcitons in R that create a query in SQL that implements the change to the database.
Ideally, The database can be maintained and edited by the user with __only__ the RShiny App.

## Q: How do you run the app?
A: Currently, the app is only able to be run on my laptop for mySQL permissions sake. The file only_app.R once sourced opens the app. 
It sources my: 
*transaction_functions.R file which holds my r code for interacitng with SQL directly
*app_functions.R file which holds the nitty-gritty code for the app in question, as well as some useful constants.
*config.R which holds my username, password, database name, and IP_address of the server (NOT INCLUDED IN GITHUB FOR SECURITY PURPOSES)

## Q: What does your app look like?
