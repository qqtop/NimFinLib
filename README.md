# NimFinLib

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![Join the chat at https://gitter.im/qqtop/NimFinLib](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/qqtop/NimFinLib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Financial Library for Nim 
==========================
(Work in Progress)


Note:  As of Nov 1 2017 Yahoo decided to take even these Api endpoints off air , which at an instant 
       removes our ability to automatically pull in delayed data for stocks/indexes and currencies. 
       Some functionallity may still be available and manually download data may work too.
              
       Currently testing with data via apikey from Alpha Vantage , but we ran into access limiting after hitting the
       the api a couple of times . A further issue is that multiple data series cannot be pulled in one request,
       which makes the process slow. A test with currency data from Alpha Vantage for 7 currency pairs here took 10 secs
       to return the data from their realtime exchange rate feed.
       
       So, do not hold your breath for too long. With Yahoo Finance Api in demise you are witnessing the end of a good thing.
   
   
Below of what it used to look like until Nov 1 2017

![Image](http://qqtop.github.io/nfT50.png?raw=true)
Example screen from nfT50.nim


```nimrod        

# nfT50.nim
# Example program for using stock and index display routines
# needs to be run in a full terminal window
# best results in bash konsole with
# font : hack
# font : size 8
# background color black
# 
import nimcx,nimFinLib
cleanscreen()
curset()
curdn(1)
showCurrentIDX("^HSI+^GSPC+^FTSE+^GDAXI+^FCHI+^N225+^JKSE",xpos = 5 ,header = true)
curset()
curdn(1)
showCurrentSTX("IBM+BP.L+0001.HK+0027.HK+SNP+AAPL+BAS.DE",xpos = 72,header = true)
curdn(5)
doFinish()   

```


![Image](http://qqtop.github.io/minifin1.png?raw=true)
Example screen from minifin.nim



| Library    | Status      | Version | License        | OS     | Compiler       |
|------------|-------------|---------|----------------|--------|----------------|
| nimFinLib  | Development | 0.2.8.x | MIT opensource | Linux  | Nim >= 0.17.x  |




Data gathering and calculations support 
----------------------------------------

              Yahoo historical stock data             <---- currently off line since Nov 2017
              
              Yahoo current quotes and forex rates    <---- currently off line since Nov 2017
              
              Dataframe like structure for easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations
              
              Ema calculation
              
              Date manipulations
              
              Kitco Metal Prices
              
              
API Docs
--------

      http://qqtop.github.io/nimFinLib.html

      for a library pertaining to Hongkong Stocks see

      http://qqtop.github.io/libFinHk.html
      

Tests and Examples
------------------

      nimFinTxx   are test programs to show use of the library .
      
      examplex    short examples 
      
      minifin     small application showing index,stock,currency and metal data
      
      nfT52       the main raw testing suite
      
      nfT50       stock and index display test
      
      testMe      automated example1      
      

Requirements
------------

            
           
      nimcx     nimble install nimcx
      
      strfmt    nimble install strfmt   (optional as a basic format engine available in cx)
           
 
Installation 
------------

      nimble install nimFinLib 
      
      Note : it is always a good idea to remove old packages from the .nimble/pkgs dir 
      
             as version numbers may not be updated often. 


example1.nim 


```nimrod         
import nimFinLib,times,strfmt,strutils
from nimcx import decho,cecholn,peru

# show latest stock quotes
showCurrentStocks("IBM+BP.L+0001.HK")
decho(2)

# get latest historic data for a stock
var ibm = initStocks()
ibm = getsymbol2("IBM","2000-01-01",getDateStr())

# show 5 historical data rows
showhistdata(ibm,5)

# show data between 2 dates incl.
showhistdata(ibm,"2015-01-12","2015-01-19")

# show recent 5 returns based on closing price
showdailyReturnsCl(ibm,5)
decho(3)

# show EMA 14 days
showEMA(ema(ibm,14),5)
decho(3)

# show stock name and latest adjusted close
cecholn(peru,"{:<8} {:<11} {:>15}".fmt("Code","Date","Adj.Close"))
echo  "{:<8} {:<11} {:>15}".fmt(ibm.stock,ibm.date.seqlast,ibm.adjc.seqlast)
decho(1)

# show some forex data

showCurrentForex(@["EURUSD","GBPHKD","CADEUR","AUDNZD"])
decho(3)

```


Want to try ? 

     Get the file testMe.nim and put it into a new directory
     then execute this :
              
         nim c -r -d:ssl testMe
       
      
     

NOTE : 
  
     Improvements may be made at any time.              
     Forking ,testing, suggestions ,ideas are welcome.
     This is development code , hence use at your own risk.
     
     Tested on openSuse Leap42.1 , openSuse TumbleWeed
              

![Image](http://qqtop.github.io/qqtop-small.png?raw=true)
