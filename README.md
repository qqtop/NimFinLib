# NimFinLib

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![Join the chat at https://gitter.im/qqtop/NimFinLib](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/qqtop/NimFinLib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Financial Library for Nim 
==========================



![Image](http://qqtop.github.io/nfT50.png?raw=true)
Example screen from nfT50.nim


```nimrod        

import cx,nimFinLib

# nfT50.nim
# Example program for using stock and index display routines
# needs to be run in a full terminal window

cleanscreen()
curset()
curdn(1)
showCurrentIDX("^HSI+^GSPC+^FTSE+^GDAXI+^FCHI+^N225+^JKSE",xpos = 5 ,header = true)
curset()
curup(1)
showCurrentSTX("IBM+BP.L+0001.HK+0027.HK+AAPL+BAS.DE+MIE1.F",xpos = 72,header = true)
curdn(5)
doFinish()  

```


![Image](http://qqtop.github.io/minifin1.png?raw=true)
Example screen from minifin.nim



| Library    | Status      | Version | License        | OS     | Compiler       |
|------------|-------------|---------|----------------|--------|----------------|
| nimFinLib  | Development | 0.2.7.x | MIT opensource | Linux  | Nim >= 0.15    |




Data gathering and calculations support 
----------------------------------------

              Yahoo historical stock data
              
              Yahoo current quotes and forex rates
              
              Dataframe like structure for easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations
              
              Ema calculation
              
              Date manipulations
              
              
              
              
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

            
      random    nimble install random
      
      cx        nimble install https://github.com/qqtop/NimCx.git
      
      strfmt    nimble install strfmt   (optional as a basic format engine available in cx)
           
 
Installation 
------------

      nimble install nimFinLib 
      
      Note : it is always a good idea to remove old packages from the .nimble/pkgs dir 
      
             as version numbers may not be updated often. 


example1.nim 


```nimrod         
import nimFinLib,times,strutils
from cx import decho,cecholn,peru,fmtx

# show latest stock quotes
showCurrentStocks("IBM+BP.L+0001.HK")
decho(2)

# get latest historic data for a stock
var ibm = initStocks()
ibm = getsymbol2("IBM","2000-01-01",getDateStr())

# show recent 5 historical data rows
showhistdata(ibm,5)

# show data between 2 dates incl.
showhistdata(ibm,"2015-01-12","2015-01-19")

# show recent 5 returns based on closing price
showdailyReturnsCl(ibm,5)
decho(3)


# show stock name and latest adjusted close
cecholn(peru,fmtx(["<8","<11",">15"],"Code ","Date ","Adj.Close"))
echo  fmtx(["<8","","<11","",">15"],ibm.stock,spaces(1),ibm.date.last,spaces(1),ibm.adjc.last)
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
     
     Tested Ubuntu 14.04 LTS , openSuse 13.2 , openSuse Leap42.1 ,openSuse TumbleWeed
              

![Image](http://qqtop.github.io/qqtop-small.png?raw=true)