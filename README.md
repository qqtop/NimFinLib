# NimFinLib
Financial Library for Nim language


Program.: nimFinLib  

Status..: Development - alpha

License.: MIT opensource  

Version.: 0.2

Compiler: nim development branch (nim 0.11.3 or better)

Description: A basic library for financial calculations with Nim

              Yahoo historical stock data
              
              Yahoo current quotes
              
              Dataframe like structure for easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations
              
              Ema calculation
              
              Date manipulations
              
              
              
              
API Docs
--------

http://qqtop.github.io/nimFinLib.html


nimFinTxx are test programs to show use of the library .


example1.nim 
------------

```nimrod         

import nimFinLib,times

# instead of hello world 

# show latest stock quotes
showCurrentStocks("IBM+BP.L+0001.HK")
echo()
echo()

# get latest historic data for a stock
var ibm : Df
ibm = getsymbol2("IBM","2014-01-01",getDateStr())

# show recent 5 returns based on closing price
showdailyReturnsCl(ibm,5)     
echo()
echo()

# show stock name and latest adjusted close
echo ibm.stock ,"     ",ibm.date.last,"    ",ibm.adjc.last
echo()
echo()
```





NOTE : 
  
     Improvements may be made at any time.              
     Forking , suggestions ,ideas are welcome .
     
     Executables - if any - here will have been build to run on linux 64
     and tested on Ubuntu 14.04 LTS and opensuse 13.2
              
              
              
              
