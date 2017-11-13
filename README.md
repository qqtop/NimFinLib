# NimFinLib

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![Join the chat at https://gitter.im/qqtop/NimFinLib](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/qqtop/NimFinLib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Financial Library for Nim 
==========================
(Work in Progress)


Note: 
       As of Nov 1 2017 Yahoo decided to take their finance api endpoints off air , which at an instant 
       removes our ability to automatically pull in delayed data for stocks/indexes and currencies. 
       Some functionallity may still be available and manually download data may work too.
       Currently testing with data via free apikey from Alpha Vantage , we ran into access limiting after hitting the
       api a couple of times .Multiple data points/series still can not be pulled in one request,
       which makes the process rather slow. A test with 8 currency pairs took 11 secs to return the data from their
       realtime exchange rate feed. See nimexratesE1.nim
       With Yahoo Finance Api currently in demise you are witnessing the end of a good thing.
   
   
Below of what it used to look like until Nov 1 2017

![Image](http://qqtop.github.io/nfT50.png?raw=true)
Example screen from nfT50.nim



![Image](http://qqtop.github.io/minifin1.png?raw=true)
Example screen from minifin.nim



| Library    | Status      | Version | License        | OS     | Compiler       |
|------------|-------------|---------|----------------|--------|----------------|
| nimFinLib  | Development | 0.2.8.x | MIT opensource | Linux  | Nim >= 0.17.x  |




Data gathering and calculations support 
----------------------------------------

              Yahoo historical stock data             <---- off line since Nov 2017
              
              Yahoo current quotes and forex rates    <---- off line since Nov 2017
              
              Alpha Vantage Api support               ----> testing since Nov 2017
              
              Dataframe like structure for easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations
              
              Ema calculation
              
              Date manipulations
              
              Kitco Metal Prices                      -----> working ok
              
              
API Docs
--------

      http://qqtop.github.io/nimFinLib.html

      for a library pertaining to Hongkong Stocks see

      http://qqtop.github.io/libFinHk.html
      

Tests and Examples
------------------

      nimFinTxx     are test programs to show use of the library (to be reworked)
      
      nimexratesE1  ok with api key
      
      minifin       small application showing index,stock,currency and metal data  (to be reworked)
      
      nfT52         the main raw testing suite     (to be reworked)
      
      nfT50         stock and index display test   (to be reworked)
      
          
      

Requirements
------------

            
           
      nimcx     nimble install nimcx
      
      strfmt    nimble install strfmt   (optional as a basic format engine available in cx)
           
 
Installation 
------------

      nimble install nimFinLib 
      
      Note : it is always a good idea to remove old packages from the .nimble/pkgs dir 
      
             as version numbers may not be updated often and always pull the latest nimcx from nimble.


NOTE : 
  
     Improvements may be made at any time.              
     Forking ,testing, suggestions ,ideas are welcome.
     This is development code , hence use at your own risk.
     
     Tested openSuse TumbleWeed
              

![Image](http://qqtop.github.io/qqtop-small.png?raw=true)
