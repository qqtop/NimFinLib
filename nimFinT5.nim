import os,terminal,sequtils,strutils,times,math,unicode,tables,strfmt,random
import nimFinLib

# Master Testing of nimFinLib do not delete
# compile with 
# nim c -d:release -d:speed -d:ssl nimFinT5


var start = epochTime()      


##############
# TESTING    #
##############


# symbols holds a list of yahoo type stock codes
var symbols1  = @["0386.HK","0880.HK","0555.HK"]
# some more symbol sets for testing for actual running always use symbols
var symbols2 = @["0386.HK","0005.HK","0880.HK","3311.HK","3688.HK","2727.HK","3337.HK","3968.HK"]  # some stock code
var symbols3 = @["1766.HK","0386.HK","0880.HK","0555.HK"]
var symbols4 = @["SNP","SBUX","IBM","BP.L"]
var symbols5 = @["AFK", "ASHR", "ECH", "EGPT",
             "EIDO", "EIRL", "EIS", "ENZL",
             "EPHE", "EPI", "EPOL", "EPU",
             "EWA", "EWC", "EWD", "EWG",
             "EWH", "EWI", "EWJ", "EWK",
             "EWL", "EWM", "EWN", "EWO",
             "EWP", "EWQ", "EWS", "EWT",
             "EWU", "EWW", "EWY", "EWZ",
             "EZA", "FM", "FRN", "FXI",
             "GAF", "GULF", "GREK", "GXG",
             "IDX", "MCHI", "MES", "NORW",
             "QQQ", "RSX", "THD", "TUR",
             "VNM", "TLT"]


var symbols = symbols3


# make sure the list is unique
symbols = deduplicate(symbols) 
# indexes holds a list of yahoo type index codes
var indexes = @["SPY","^HSI"]  
# make sure the list is unique
indexes = deduplicate(indexes)
 
# for testing we use same start,end date but of course
# they could be different for each stock  
var 
   startDate = "2014-01-01"
   endDate   = getDateStr()
   #endDate = "2015-01-01"  

# pools holds a list of symbols of interest , thee can be any number of pools
# like etf pool ukpool , uspool , etc here we have 2 pools
var
  stockpool     = newSeq[Df]()       # holds all history data for each stock fetched
  indexpool     = newSeq[Df]()       # holds index history data
  
stockpool = @[]
indexpool = @[]


# load the pools with data
for symbx in symbols:
    stockpool.add(getSymbol2(symbx,startDate,endDate))
echo()  
# also load the indexpool 
for symbx in indexes:
    indexpool.add(getSymbol2(symbx,startDate,endDate))
echo() 

# setup a new account structure
     
var account    : Pf
var portfolio  : Nf
var stockdata  : Df

# initialize 
account   = initPf(account)
portfolio = initNf(portfolio)
stockdata = initDf(stockdata)
# stockdata holds a Df object that has all historical data of a single stock 
# here we use the first stock in stockpool , for many stocks
# we wud iterate over stockpool to load all
#stockdata = stockpool[0] 
# create a portfolio and add a single stockdata object
portfolio.nx = "TestPortfolio"
for stockdata in stockpool:  
   portfolio.dx.add(stockdata)  
# add the just created portfolio to account, an object which holds all porfolios
account.pf.add(portfolio)


# now we can access our data 
# access the first portfolio inside of account and show name of this portfolio
echo account.pf[0].nx 
# access the first stock in the first portfolio in account and show some data
echo "Name    : ",account.pf[0].dx[0].stock
echo "Open    : ",account.pf[0].dx[0].open.last
echo "High    : ",account.pf[0].dx[0].high.last
echo "Low     : ",account.pf[0].dx[0].low.last
echo "Close   : ",account.pf[0].dx[0].close.last
echo "Volume  : ",account.pf[0].dx[0].vol.last
echo "AdjClose: ",account.pf[0].dx[0].adjc.last
echo "StDevCl : ",account.pf[0].dx[0].rc[0].standardDeviation 
echo "StDevClA: ",account.pf[0].dx[0].rca[0].standardDeviation
# alternative way to work with the stock data 
# to save some writing is like so
var data = account.pf[0].dx[0]
echo()
echo "Using shortcut to display most recent open value"
echo data.open.last
echo()

# now we can use our data for some basic calculations
# we show the most recent 5 dailyreturns for data based on close price
msgy() do: echo "Most recent 5 dailyreturns based on close price"
showdailyReturnsCl(data,5) 

# we show the most recent 5 dailyreturns for data based on adjusted close price
echo()
msgy() do: echo "Most recent 5 dailyreturns based on adjc price"
showdailyReturnsAdCl(data,5)

# if we need the actual returnseries for further use here based on adjusted close
# Note : we need to pass the desired data column
echo ()
msgy() do: echo "Show tail 2 rows = most recent dailyreturns based on adjc"
var rets = dailyreturns(data.adjc)
# display last 2 lines of our rets series
for x in 0.. <rets.tail(2).len :
   echo data.date[x],"  ",rets[x]  

# we also can use the show proc 
showdailyReturnsAdCl(data,2)  
 
echo () 
# we can show sum of dailyreturns
echo "DailyReturns sum based on Close Price     : ",Rune(ord(11593))," ",sumdailyReturnsCl(data)
echo "DailyReturns sum based on AdjClose Price  : ",Rune(ord(11593))," ",sumdailyReturnsAdCl(data)


# Testing timeseries  basically this returns 
# one of the ohlcva data seqs with a date column
msgy() do : echo "\nTest timeseries - show recent 5 rows for $1\n" % data.stock

# available headers  
var htable = {"o": "Open", "h": "High","l":"Low","c":"Close","v":"Volume","a":"Adj.Close"}.toTable 
var ohlcva = "a"  # here we choose adjclose column 
var ts = data.timeseries(ohlcva)
msgy() do : echo "Head"
showTimeseries(ts,htable[ohlcva],"head",5) # newest on top
msgy() do : echo "Tail"
showTimeseries(ts,htable[ohlcva],"tail",5) # oldest on bottom
#msgy() do : echo "All"
#showTimeseries(ts,htable[ohlcva],"all",5) # also available , the days rows has no effect


# if we use an orderedtable we get the same effect
# so a table with its many options can be a good choice too
# http://nim-lang.org/docs/tables.html#OrderedTable
# keep here for reference
# echo ()
# msgy() do : echo"Test OrderedTable"
# msgg() do : echo "{:<11} {:>11} ".fmt("Date",htable[ohlcva]) 
# # init table
# var atable = initOrderedTable[string, float]()
# # load table
# 
# for x in 0.. <10:
#    atable.add(ts.dd[x], ts.tx[x])
# # display table
# for date,val in atable:
#     echo "{:<11} {:>11} ".fmt(date,val)
# echo "Keys : ",atable.len  


# testing ema
# for ema  we need a df object and number of days , maybe 22  <-- N
# we get back a Ts object  
# Note we need min 5 * N days of data points
# this meets R quantmod output 100%
echo ()
var ndays = 22
var ema22 = ema(data,ndays)
showEma(ema22,5)

# testing rsi
# does not yet line up with quantmod 
# # Note rsi comes in as Ts with newest value at bottom
# our displayroutine shows top down
echo ()
msgg() do : echo "{:<11} {:>11} ".fmt("Date","RSI (ema 14)") 
var arsi = rsi(data,ndays)
showRsi(arsi,5)

# testing utility functions on Rsi 
msgg() do : echo "\nRSI series display test "
msgy() do : echo "{}  {:<10} {}".fmt("first   ",arsi.dd.first,arsi.tx.first)
msgy() do : echo "{}  {:<10} {}".fmt("head(1) ",arsi.dd.head(1),arsi.tx.head(1))
msgy() do : echo "{}  {:<10} {}".fmt("last    ",arsi.dd.last,arsi.tx.last)
msgy() do : echo "{}  {:<10} {}".fmt("tail(1) ",arsi.dd.tail(1),arsi.tx.tail(1))

# remember that : data = account.pf[0].dx[0] 
# so we can get the statistics for this stock as
echo ()
msgy() do : echo "Stats for : ", data.stock , " based on close price"
statistics(data.rc[0])


############################# 
# Tests for helper procs    #
#############################

# test date routines
 
var s     = ts.dd.min  # note we use the date series from the timeseries test above
var e     = ts.dd.max
 
msgy() do: echo "\nInterval Information\n"
echo s,"  -  ",e
echo "Years      : ", intervalyears(s,e)
echo "Months     : ", intervalmonths(s,e)
echo "Weeks      : ", intervalweeks(s,e)
echo "Days       : ", intervaldays(s,e)
echo "Hours      : ", intervalhours(s,e)
echo "Mins       : ", intervalmins(s,e)
echo "Secs       : ", intervalsecs(s,e)

echo s.year," ",s.month," ",s.day


# testing logistics functions
# logisticf maps values to between 0 and 1
# logistic_derivative is the derivative for gradient optm. use

var a = 5
echo "{:>15} {:>15} {:>15}".fmt("Value","logisticf","logistic_derivative")
for x in -a.. a:
  var xx = random.random() * 1.8
  echo "{:>15.f14} {:>15.f14} {:>15.f14}".fmt(xx,logisticf(xx),logistic_derivative(xx))




# how to see whats going on inside the object 
#echo repr(t1)


############################################
# Tests for Current Stocks and Indexes     #
############################################
# we can pass a single stock code or multiple stockcodes like so IBM+BP.L+ORCL

# example for single stock ,index
# aha is a helper proc to conver a Df.stock object to a string without 
# this the compiler burps

# below is ok but not nice 
# aha and the xs generating loop shud be in the lib
# so what we want is to call showCurrentStocks(account.pf[0].dx) 
# which wud be much cleaner , without the preprocessing stuff here
# maybe allow for both solutions 
# aha proc moved to lib is ok

# produce a string of one or more stock codes coming from a Nf object
# which holds all stocks in a portfolio
var xs = ""
for x in 0.. <account.pf[0].dx.len:
    # need to pass multiple code like so code+code+ , an initial + is also ok apparently
    # stockDf proc does some required type massaging by nim and gets
    # the stock name from a Df object
    xs = xs & "+" & stockDf(account.pf[0].dx[x])  
  
showCurrentStocks(xs)

var idx : string = indexpool[0].stock  # here just passing a single code (index)
showCurrentIndexes(idx)

 
# show time of this run
msgc() do: echo "\nElapsed  : ",epochTime() - start," secs\n\n"

when isMainModule:
  system.addQuitProc(resetAttributes)
  # some system stats
  GC_fullCollect()
  # for development we can see what gc is doing
  #echo GC_getStatistics()
  
  quit 0    