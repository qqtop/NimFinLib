# NimFinLib
Financial Library for Nim language


Program.: nimFinLib  

Status..: Development - alpha

License.: MIT opensource  

Version.: 0.2

Compiler: nim development branch (nim 0.11.3 or better)

Description: A basic library for financial calculations with Nim

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


nimFinTxx are test programs to show use of the library .


example1.nim 
------------

```nimrod         

import nimFinLib,times,strfmt,strutils

# show latest stock quotes
showCurrentStocks("IBM+BP.L+0001.HK")
decho(2)

# get latest historic data for a stock
var ibm = initDf()
ibm = getsymbol2("0386.HK","2000-01-01",getDateStr())

# show recent 5 historical data rows
showhistdata(ibm,5)

# show data between 2 dates incl.
showhistdata(ibm,"2015-01-12","2015-01-19")

# show recent 5 returns based on closing price
showdailyReturnsCl(ibm,5)     
decho(3)


# show stock name and latest adjusted close
msgg() do: echo "{:<8} {:<11} {:>15}".fmt("Code","Date","Adj.Close") 
echo  "{:<8} {:<11} {:>15}".fmt(ibm.stock,ibm.date.last,ibm.adjc.last)
decho(1)


# show some forex data

showCurrentForex(@["EURUSD","GBPHKD","CADEUR","AUDNZD"])
decho(3)
```





NOTE : 
  
     Improvements may be made at any time.              
     Forking , suggestions ,ideas are welcome .
     
     Executables - if any - here will have been build to run on linux 64
     and tested on Ubuntu 14.04 LTS and opensuse 13.2
              
              
              
              
