# NimFinLib

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![Join the chat at https://gitter.im/qqtop/NimFinLib](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/qqtop/NimFinLib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Financial Library for Nim 
==========================
(Work in Progress)


Note: 
       Unfortunately, as of Nov 1 2017 Yahoo decided to take their finance api endpoints off air , which at an instant 
       removes our ability to automatically pull in delayed data for stocks/indexes and currencies. 
       
       Testing with data via free apikey from Alpha Vantage , which looks promising but requires major refactoring. 
       Basic data fetching and display is now working.
       
       The indicator API does return data for some markets like USA,UK , but not for Germany or Hongkong.
       


| Library    | Status      | Version | License        | OS     | Compiler       |
|------------|-------------|---------|----------------|--------|----------------|
| nimFinLib  | Development | 0.3.0.x | MIT opensource | Linux  | Nim >= 0.17.x  |




Data gathering and calculations support 
----------------------------------------

                          
              Alpha Vantage Api support               ----> testing since Nov 2017
              
              Planned 
              
              Dataframe like structure for easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations
              
              Ema and other indicators calculation
                      
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
      nimmetal    ok
     

Requirements
------------
     
           
      nimcx         nimble install nimcx
      
      nimdataframe  nimble install https://github.com/qqtop/nimdataframe.git
      
          
 
Installation 
------------
  
       
      nimble install nimFinLib 
      
      Note : it is always a good idea to remove old packages from the .nimble/pkgs dir 
      
             as version numbers may not be updated often and always pull the latest nimcx from nimble.

![Image](http://qqtop.github.io/nfT53-1.png?raw=true)

![Image](http://qqtop.github.io/nfT53-2.png?raw=true)

![Image](http://qqtop.github.io/nfT53-3.png?raw=true)
Example screen from nfT53.nim


![Image](http://qqtop.github.io/nfT55.png?raw=true)
Example screen from nfT55.nim  displaying SMA,WMA,EMA Indicator data


             
Below of what it used to look like until Nov 1 2017

![Image](http://qqtop.github.io/nfT50.png?raw=true)
Example screen from nfT50.nim



![Image](http://qqtop.github.io/minifin1.png?raw=true)
Example screen from minifin.nim             
             
             
             
             
             
NOTE : 
  
     Improvements may be made at any time.              
     Forking ,testing, suggestions ,ideas are welcome.
     This is development code , hence use at your own risk.
     
     Tested openSuse TumbleWeed
              

![Image](http://qqtop.github.io/qqtop-small.png?raw=true)
