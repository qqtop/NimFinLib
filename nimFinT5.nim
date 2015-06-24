import os,terminal,sequtils,strutils,times,math,unicode,tables,strfmt,random
import nimFinLib

# Master Testing Suite of nimFinLib 
# 
# compile with 
# nim c --deadcodeelim:on -d:release --opt:size -d:ssl nimFinT5


var start = epochTime()      

echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Testing nimFinLib                           #"
msgy() do : echo "###############################################"
echo ()


# symbols holds a list of yahoo type stock codes
var symbols1  = @["0386.HK","0880.HK","0555.HK"]
# some more symbol sets for testing always use symbols
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

# select one of the lists or use your own
var symbols = symbols1

# make sure the list is unique
symbols = deduplicate(symbols) 
# indexes holds a list of yahoo type index codes
# and maybe used as 'risk free' in var. calculations like sharpe etc.
var indexes = @["SPY","^HSI"]  
# make sure the list is unique
indexes = deduplicate(indexes)
 
# for testing we use same start,end date but of course
# they could be different for each stock  
var 
   startDate = "2014-01-01"
   endDate   = getDateStr()
   #endDate = "2015-01-01"  

# set up some lists to hold stock codes , let's call them pools
# pools hold a list of symbols of interest , there can be any number of pools
# like etfpool ,ukpool , uspool , etc here we have 2 pools

var stockpool = initPool()             # holds all history data for each stock fetched
var indexpool = initPool()             # holds index history data

# the pools are empty , so now load the pools with data based
# on above provided symbol lists , of course this symbols can
# come from a database or text file
# note: getSymbol2 use below , this gets the yahoo historical data
for symbx in symbols:
    stockpool.add(getSymbol2(symbx,startDate,endDate))
echo()  

# also load the indexpool 
for symbx in indexes:
    indexpool.add(getSymbol2(symbx,startDate,endDate))
echo() 

# setup a new account structure 
var account     = initPf()
var portfolio   = initNf()
var stockdata   = initDf()

# stockdata holds a Df object that has all historical data of a single stock 
# we can use the first stock in stockpool like so: 
# stockdata = stockpool[0] 
  
# for multiple stocks we iterate over stockpool to load all

# create a portfolio and add a single stockdata object
portfolio.nx = "TestPortfolio"    # nx holds the relevant portfolio name
for stockdata in stockpool:  
    portfolio.dx.add(stockdata)   # dx holds the historical data series
    
# add the just created portfolio to account, an object which holds all portfolios
account.pf.add(portfolio)

# now all is set and data can be used 
echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Tests for Pf , Nf ,Df types                 #"
msgy() do : echo "###############################################"
echo ()

# access the first portfolio inside of account and show name of this portfolio
echo account.pf[0].nx 
# of course this works too
# echo account.pf.last.nx
# note : first , last maybe confusing in the beginning 
# last = most recent , first = oldest

# access the first stock in the first portfolio in account and show some data
echo "Name    : ",account.pf[0].dx[0].stock
echo "Open    : ",account.pf[0].dx[0].open.last
echo "High    : ",account.pf[0].dx[0].high.last
echo "Low     : ",account.pf[0].dx[0].low.last
echo "Close   : ",account.pf[0].dx[0].close.last
echo "Volume  : ",account.pf[0].dx[0].vol.last
echo "AdjClose: ",account.pf[0].dx[0].adjc.last
echo "StDevOp : ",account.pf[0].dx[0].ro[0].standardDeviation 
echo "StDevHi : ",account.pf[0].dx[0].rh[0].standardDeviation 
echo "StDevLo : ",account.pf[0].dx[0].rl[0].standardDeviation 
echo "StDevCl : ",account.pf[0].dx[0].rc[0].standardDeviation 
echo "StDevVo : ",account.pf[0].dx[0].rv[0].standardDeviation 
echo "StDevClA: ",account.pf[0].dx[0].rca[0].standardDeviation
# alternative way to work with the stock data 
# and to save some writing 
# note last ==> last in from the left or from top
# so we also can write :  
# data = account.pf[0].dx[0] or
var data = account.pf.last.dx.last  
echo()
echo "Using shortcut to display most recent open value"
echo data.open.last
decho(2) # print 2 blank lines

echo "Show hist. stock data between 2 dates incl. if available"
showhistdata(data,"2015-04-12","2015-05-10")
echo()

echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Tests for dailyReturns                      #"
msgy() do : echo "###############################################"
echo ()


# now we can use our data for some basic calculations
# we show the most recent 5 dailyreturns for data based on close price
msgy() do: echo "Most recent 5 dailyreturns based on close price"
showdailyReturnsCl(data,5) 

# we show the most recent 5 dailyreturns for data based on adjusted close price
echo()
msgy() do: echo "Most recent 5 dailyreturns based on adjc price"
showdailyReturnsAdCl(data,5)


echo ()
msgy() do: echo "Show tail 2 rows = most recent dailyreturns based on adjc"
# if we need the actual returnseries for further use we need to save it
# Note : we need to pass the desired data column  
var rets = dailyreturns(data.adjc)
# display last 2 lines of our rets series
for x in 0.. <rets.tail(2).len :
   echo data.date[x],"  ",rets[x]  

# we also can use the convenient show proc to display data
showdailyReturnsAdCl(data,2)  
 
echo () 
# we can show the sum of dailyreturns
echo "DailyReturns sum based on Close Price     : ",Rune(ord(11593))," ",sumdailyReturnsCl(data)
echo "DailyReturns sum based on AdjClose Price  : ",Rune(ord(11593))," ",sumdailyReturnsAdCl(data)

echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Tests for timeseries                        #"
msgy() do : echo "###############################################"
echo () 
 
# this returns a date column and one of the ohlcva data columns 
msgy() do : echo "\nTest timeseries - show recent 5 rows for $1\n" % data.stock
# available headers  
var htable = {"o": "Open", "h": "High","l":"Low","c":"Close","v":"Volume","a":"Adj.Close"}.toTable 
var ohlcva = "a"  # here we choose adjclose column 
var ts = data.timeseries(ohlcva)
# once we have the timeseries it can be displayed with the showTimeseries function
msgy() do : echo "Head"
showTimeseries(ts,htable[ohlcva],"head",5) # newest on top
msgy() do : echo "Tail"
showTimeseries(ts,htable[ohlcva],"tail",5) # oldest on bottom
# to see all rows
#msgy() do : echo "All"
#showTimeseries(ts,htable[ohlcva],"all",5) # also available , the 5 here has no effect

echo()
# testing utility procs
msgg() do : echo "Timeseries display test "
msgy() do : echo "{}  {:<10} {}".fmt("first   ",ts.dd.first,ts.tx.first)
msgy() do : echo "{}  {:<10} {}".fmt("head(1) ",ts.dd.head(1),ts.tx.head(1))
msgy() do : echo "{}  {:<10} {}".fmt("last    ",ts.dd.last,ts.tx.last)
msgy() do : echo "{}  {:<10} {}".fmt("tail(1) ",ts.dd.tail(1),ts.tx.tail(1))


# if we use an orderedtable we also can get a nicely formated display
# so a table with its many options can be a good choice too
# http://nim-lang.org/docs/tables.html#OrderedTable
# for reference:
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


echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Tests for ema (exponential moving average)  #"
msgy() do : echo "###############################################"
echo () 
 
# for ema  we need a df object and number of days , maybe 22  <-- N
# we get back a Ts object  
# Note we need min 5 * N days of data points
# this meets R quantmod output 100%
var ndays = 22
var ema22 = ema(data,ndays)
echo "EMA for : ", data.stock
showEma(ema22,5)


echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Tests for statistics on Df type             #"
msgy() do : echo "###############################################"
echo () 
 
# remember that : data = account.pf[0].dx[0] 
# so we can get all the statistics for this stock like so

var ohlcvaSet    = @[data.ro[0],data.rh[0],data.rl[0],data.rc[0],data.rv[0],data.rca[0]]
var ohlcvaheader = @["Open","High","Low","Close","Volume","Adj.Close"]

for x in 0.. <ohlcvaSet.len:
     echo aline
     msgg() do : echo "Stats for : ", data.stock ," based on ", ohlcvaheader[x]
     statistics(ohlcvaSet[x])


echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Tests for date and logistic helper procs    #"
msgy() do : echo "###############################################"
echo ()
 
var s = ts.dd.min  # note we use the date series from the timeseries test above
var e = ts.dd.max
 
msgy() do: echo "\nInterval Information\n"
echo s,"  -  ",e
echo "Years      : ", intervalyears(s,e)
echo "Months     : ", intervalmonths(s,e)
echo "Weeks      : ", intervalweeks(s,e)
echo "Days       : ", intervaldays(s,e)
echo "Hours      : ", intervalhours(s,e)
echo "Mins       : ", intervalmins(s,e)
echo "Secs       : ", intervalsecs(s,e)

echo ()
echo "Extract items from date string ",s
echo s.year," ",s.month," ",s.day
decho(2)


echo "Test validDate proc"
var somedates = @["2015-05-10","2015-02-29","3000-15-10","1899-12-31","2018-12-31","2016-02-29",
                 "2017-02-29","2018-02-29","2019-02-29","2019-01-02",getDateStr()]
for sd in somedates:
  if validDate(sd) == true:
      msgg() do: echo "{:<11} {}".fmt(sd,"true")
  else:
      msgr() do: echo "{:<11} {}".fmt(sd,"false")
echo()


echo "Test plusDays and minusDays proc "
var indate = getDateStr()
echo "Indate     : ", indate
echo "Outdate +7 : ", plusDays(indate,7)
echo "Outdate -7 : ", minusdays(indate,7) 
echo()

msgy() do : echo "Testing logistics functions"
# logisticf maps values to between 0 and 1
# logistic_derivative is the derivative for gradient optm. use

var a = 5
echo "{:>15} {:>15} {:>15}".fmt("Value","logisticf","logistic_derivative")
for x in -a.. a:
  var xx = random.random() * 1.8
  echo "{:>15.f14} {:>15.f14} {:>15.f14}".fmt(xx,logisticf(xx),logisticf_derivative(xx))



echo ()
msgy() do : echo "############################################"
msgy() do : echo "# Tests for Current Stocks and Indexes     #"
msgy() do : echo "############################################"
echo ()

# we can pass a single stock code or multiple stockcodes like so IBM+BP.L+ORCL
# stockDf is a helper proc to convert a Df.stock object to a string 
# this may be deprecated in the future
 
# we can pass some stocks  
showCurrentStocks("AAPL+IBM+BP.L")

# we also can pass all stocks in a portfolio and display the latest quotes
# here we use the first portfolio in account
showCurrentStocks(account.pf[0])

# here just passing a single code (index)
var idx : string = indexpool[0].stock  
showCurrentIndexes(idx)

# here passing in our indexpool a  seq[Df] type 
showCurrentIndexes(indexpool)          
  

echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Tests for Forex rates                       #"
msgy() do : echo "###############################################"
echo () 

# look at "current" exchange rates as supplied from yahoo
echo()
msgy() do : echo "Yahoo Exchange Rates"
var checkcurrencies = @["EURUSD","GBPUSD","GBPHKD","JPYUSD","AUDUSD","EURHKD","JPYHKD","CNYHKD"]
showCurrentForex(checkcurrencies)


# if the exchange rates are needed for further processing
# use the getcurrentForex proc  , we receive a Cf type for unpacking
var curs = getCurrentForex(@["EURUSD","EURHKD"])
echo()
echo "Current EURUSD Rate : ","{:<8}".fmt(curs.ra.last)
echo "Current EURHKD Rate : ","{:<8}".fmt(curs.ra.first)
echo()

echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Testing sleepy                              #"
msgy() do : echo "###############################################"
echo () 

msgy() do : echo "Going to sleep for 2.5 secs"
sleepy(2.5)
msgg() do : echo "Ready for work again"

# how to see whats going on inside an object 
#echo repr(t1)

 
when isMainModule:
  # show time elapsed for this run
  echo ()
  msgc() do: echo "Elapsed           : ",epochTime() - start," secs\n"
  msgg() do: echo "nimlibFin Version : ",VERSION 
  echo()
  echo()
  system.addQuitProc(resetAttributes)
  # some system stats
  GC_fullCollect()
  # we can see what GC has to say
  #echo GC_getStatistics()
  quit 0    
  