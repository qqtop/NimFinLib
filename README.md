# NimFinLib

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![Join the chat at https://gitter.im/qqtop/NimFinLib](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/qqtop/NimFinLib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Financial Library for Nim 
==========================
(Work in Progress)


Description: 

             Now using historic data via free apikey from Alpha Vantage. 
             Basic data fetching and data display is working.
             The indicator API does return data for some markets like USA , UK
             but not yet for others like Germany , Hongkong etc.
             The plan is to add portfolio management and analysis.
             Basic charts can currently be displayed via gnuplot.
       
       


| Library    | Status      | Version | License        | OS     | Compiler       |
|------------|-------------|---------|----------------|--------|----------------|
| nimFinLib  | Development | 0.3.0.x | MIT opensource | Linux  | Nim >= 0.17.x  |




Data gathering and calculations support 
----------------------------------------

                          
              Alpha Vantage Api support               ----> testing since Nov 2017
              
                         
              Dataframe for display and easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations and more
              
              Indicator displays
                      
              Kitco Metal Prices                      
              
              
API Docs
--------

      Planned to be in
      
      http://qqtop.github.io/nimFinLib.html

      # http://qqtop.github.io/libFinHk.html
      
  
   
Tests and Examples
------------------
    
      
      nimexrates  ok with api key
      nfT53       ok w/o api key
      nfT55       ok w/o api key
      nimmetal    ok
     

Requirements
------------
     
           
      nimcx         nimble install nimcx
      
      nimdataframe  nimble install https://github.com/qqtop/nimdataframe.git
      
          
 
Installation 
------------
  
       
      nimble install nimFinLib 
      
      Note : it is always a good idea to install the latest libraries
      
  
             
![Image](http://qqtop.github.io/quickStock.png?raw=true)             
Example screen from quickStock.nim              
             
![Image](http://qqtop.github.io/nfT53-1.png?raw=true)

![Image](http://qqtop.github.io/nfT53-2.png?raw=true)

![Image](http://qqtop.github.io/nfT53-3.png?raw=true)
Example screen from nfT53.nim


![Image](http://qqtop.github.io/nfT55.png?raw=true)
Example screen from nfT55.nim  displaying SMA,WMA,EMA Indicator data




Below screenshots of nimFinLib usage prior to demise of Yahoo Finance API on Nov 1 2017.


![Image](http://qqtop.github.io/nfT50.png?raw=true)
Example screen from nfT50.nim



![Image](http://qqtop.github.io/minifin1.png?raw=true)
Example screen from minifin.nim             
             
             
             
             
             
NOTE : 
  
     Improvements may be made at any time.              
     Forking ,testing, suggestions ,ideas are welcome.
     This is development code , use at your own risk.
     
     
     
     Tested on openSuse TumbleWeed
              

![Image](http://qqtop.github.io/qqtop-small.png?raw=true)
