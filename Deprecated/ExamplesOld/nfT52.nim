import os,terminal,sequtils,times,math,stats,unicode,tables
import nimFinLib,nimcx

# comment next line if tests concerning libFinHk not required
import libFinHk
# uncomment next line for nimprofiler 
#import nimProf


## nfT52.nim
##
## Master Testing Suite of nimFinLib2  the current development version
##
## compile with
## nim c --deadcodeelim:on -d:release --opt:size -d:ssl --gc:boehm nfT52
##
## compile with profiler  --> uncomment import nimprof line above
## nim c -d:ssl --profiler:on --stackTrace:on nfT52
## then run prog and check file: profile_results.txt
##
## if using valgrind
## 
## nim -d:release --debugger:native c nfT52
## valgrind --tool=callgrind ./nfT52
## kcachegrind


echo()
superheader(" Testing nimFinLib  ")
echo()

# if yahoo is down or temporarily changes the conn string this may not work until we get it running again
# symbols holds a list of yahoo type stock codes
var symbols1  = @["0001.HK","0386.HK","0880.HK","0555.HK"]
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
var indexes = @["^GSPC","^HSI"]
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

var stockpool = initPool()   # holds all history data for each stock fetched
var indexpool = initPool()   # holds index history data

#[ the pools are empty , so now load the pools with data based
   on above provided symbol lists , of course this symbols can
   come from a database or text file
   note: getSymbol2 use below , this gets the yahoo historical data
]#

for symbx in symbols:
    stockpool.add(getSymbol2(symbx,startDate,endDate))
echo()

# also load the indexpool
for symbx in indexes:
    indexpool.add(getSymbol2(symbx,startDate,endDate))
echo()

# setup a new account structure
var account     = initAccount()
var portfolio   = initPortfolio()
var stockdata   = initStocks()

# stockdata holds a Stocks object that has all historical data of a single stock
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
echo()
superheader(" Tests for Account , Portfolio ,Stocks types ")
echo()

# access the first portfolio inside of account and show name of this portfolio
echo account.pf[0].nx
# of course this works too
# echo account.pf.last.nx
# note : first , last maybe confusing in the beginning
# last = most recent , first = oldest

# access the first stock in the first portfolio in account and show some data
echo "Name    : ",account.pf[0].dx[0].stock
echo "Open    : ",account.pf[0].dx[0].open.seqlast
echo "High    : ",account.pf[0].dx[0].high.seqlast
echo "Low     : ",account.pf[0].dx[0].low.seqlast
echo "Close   : ",account.pf[0].dx[0].close.seqlast
echo "Volume  : ",account.pf[0].dx[0].vol.seqlast
echo "AdjClose: ",account.pf[0].dx[0].adjc.seqlast
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
var data = account.pf.seqlast.dx.seqlast
echo()
echo "Using shortcut to display most recent open value"
echo data.open.seqlast
decho(2) # print 2 blank lines

echo "Show hist. stock data between 2 dates incl. if available"
showhistdata(data,"2015-10-12","2015-11-15")
echo()

echo()
superheader(" Tests for dailyReturns ")
echo()


# now we can use our data for some basic calculations
# we show the most recent 5 dailyreturns for data based on close price
printLn("Most recent 5 dailyreturns based on close price",yellowgreen)
showdailyReturnsCl(data,5)

# we show the most recent 5 dailyreturns for data based on adjusted close price
echo()
printLn("Most recent 5 dailyreturns based on adjc price",yellow)
showdailyReturnsAdCl(data,5)


echo()
printLn("Show tail 2 rows = most recent dailyreturns based on adjc",yellowgreen)
# if we need the actual returnseries for further use we need to save it
# Note : we need to pass the desired data column
var rets = dailyreturns(data.adjc)
# display last 2 lines of our rets series
for x in 0.. <rets.seqtail(2).len :
   echo data.date[x],"  ",rets[x]

# we also can use the convenient show proc to display data
showdailyReturnsAdCl(data,2)

echo()
# we can show the sum of dailyreturns
echo "DailyReturns sum based on Close Price     : ",Rune(ord(11593))," ",sumdailyReturnsCl(data)
echo "DailyReturns sum based on AdjClose Price  : ",Rune(ord(11593))," ",sumdailyReturnsAdCl(data)

echo()
superheader(" Tests for timeseries ")
echo()

# this returns a date column and one of the ohlcva data columns
println("\nTest timeseries - show recent 5 rows for $1\n" % data.stock,yellow)
# available headers
var htable = {"o": "Open", "h": "High","l":"Low","c":"Close","v":"Volume","a":"Adj.Close"}.toTable
var ohlcva = "a"  # here we choose adjclose column
var ts = data.timeseries(ohlcva)
# once we have the timeseries it can be displayed with the showTimeseries function
printLn( "Head",yellow)
showTimeseries(ts,htable[ohlcva],head,5) # newest on top
printLn("Tail",yellow)
showTimeseries(ts,htable[ohlcva],tail,5) # oldest on bottom
# to see all rows
#printLn("All",yellow)
#showTimeseries(ts,htable[ohlcva],all,5) # also available , the 5 here has no effect

echo()
# testing utility procs
var ts1 = $(ts.dd.seqhead(1)[0])
var ts2 = $(ts.tx.seqhead(1)[0])
printLn("Timeseries display test ",lime)
printLn(fmtx(["","","<10","",""],"seqfirst   ",spaces(3),ts.dd.seqfirst   ,spaces(2) ,ts.tx.seqfirst)  ,yellow)
printLn(fmtx(["","","<10","",""],"head(1) ",spaces(3),ts1,spaces(2) ,ts2),yellow)
printLn(fmtx(["","","<10","",""],"seqlast    ",spaces(3),ts.dd.seqlast   ,spaces(2),ts.tx.seqlast),yellow)
printLn(fmtx(["","","<10","",""],"tail(1) ",spaces(3),$(ts.dd.seqtail(1)[0]),spaces(2),$(ts.tx.seqtail(1)[0])),yellow)


# if we use an orderedtable we also can get a nicely formated display
# so a table with its many options can be a good choice too
# http://nim-lang.org/docs/tables.html#OrderedTable
# for reference:
# echo()
# printLn("Test OrderedTable",yellow)
# println("{:<11} {:>11} ".fmt("Date",htable[ohlcva]),yellowgreen)
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


echo()
superheader(" Tests for ema (exponential moving average)  ")
echo()

# for ema  we need a df object and number of days , maybe 22  <-- N
# we get back a Ts object
# Note we need min 5 * N days of data points
# this meets R quantmod output 100%
var ndays = 22
var ema22 = ema(data,ndays)
echo "EMA for : ", data.stock
showEma(ema22,5)


echo()
superheader(" Tests for statistics on Stocks type         ")
echo()

# remember that : data = account.pf[0].dx[0]
# so we can get all the statistics for this stock like so

var ohlcvaSet    = @[data.ro[0],data.rh[0],data.rl[0],data.rc[0],data.rv[0],data.rca[0]]
var ohlcvaheader = @["Open","High","Low","Close","Volume","Adj.Close"]

for x in 0.. <ohlcvaSet.len:
     aline()
     printLn("Stats for : " & data.stock & " based on " & ohlcvaheader[x],green)
     statistics(ohlcvaSet[x])

decho(2)
echo "Show full statistics - standard display"
showStatistics(data)

echo "Show full statistics - transposed display"
showStatisticsT(data)

# these tests work with statistics.nim
when declared(statistics.quantile):
    echo()
    superheader(" Tests for quantile , kurtosis & skewness   ")
    echo()
    echo "0.25  : ",abs(quantile(data.open, 0.25))
    echo "0.50  : ",abs(quantile(data.open, 0.5))
    echo "0.75  : ",abs(quantile(data.open, 0.75))
    echo "1.00  : ",abs(quantile(data.open, 1.0))
    decho(2)
    echo "Kurtosis open  : ", kurtosis(data.open)
    echo "Kurtosis close : ", kurtosis(data.close)
    decho(2)
    echo "Skewness open  : ", skewness(data.open)
    echo "Skewness close : ", skewness(data.close)



echo()
superheader(" Tests for date and logistic helper procs  ")
echo()

if ts.dd.len > 0:
    var s = ts.dd.min  # note we use the date series from the timeseries test above
    var e = ts.dd.max

    printLn(" Interval Information\n",peru)
    echo "Date Range : ", s,"  -  ",e
    echo "Years      : ", nimcx.intervalyears(s,e)
    echo "Months     : ", nimcx.intervalmonths(s,e)
    echo "Weeks      : ", nimcx.intervalweeks(s,e)
    echo "Days       : ", nimcx.intervaldays(s,e)
    echo "Hours      : ", nimcx.intervalhours(s,e)
    echo "Mins       : ", nimcx.intervalmins(s,e)
    echo "Secs       : ", nimcx.intervalsecs(s,e)

    echo()
    echo "Extract items from date string ",s
    echo nimcx.year(s)," ",nimcx.month(s)," ",nimcx.day(s)
    decho(2)


printLn(" Test validDate proc\n",peru)
var somedates = @["2015-05-10","2015-02-29","3000-15-10","1899-12-31","2018-12-31","2016-02-29",
                 "2017-02-29","2018-02-29","2019-02-29","2019-01-02",getDateStr()]
for sd in somedates:
  if nimcx.validDate(sd) == true:
      printLn(fmtx(["<11","",""],sd,spaces(1),"true"),yellowgreen)
  else:
      printLn(fmtx(["<11","",""],sd,spaces(1),"false"),truetomato)
echo()


printLn(" Test plusDays and minusDays proc \n",peru)
var indate = getDateStr()
printLnBiCol("Indate     : " & indate)
printLnBiCol("Outdate +7 : " & nimcx.plusDays(indate,7))
printLnBiCol("Outdate -7 : " & nimcx.minusdays(indate,7))
echo()

printLn(" Testing logistics functions\n",peru)
# logisticf maps values to between 0 and 1
# logistic_derivative is the derivative for gradient optm. use

var a = 5
printLn(fmtx([">15","", ">15" ,"",">15"],"Value",spaces(1),"logisticf",spaces(3),"logistic_derivative"),yellowgreen)
for x in -a.. a:
  var xx = getRandomFloat() * 1.8
  echo(fmtx([">15.14f","",">15.14f","",">15.14f"],xx,spaces(1),logisticf(xx),spaces(3),logisticf_derivative(xx)))



echo()
superheader(" Tests for Current Stocks and Indexes  - Wide View")
echo()

# we can pass a single stock code or multiple stockcodes like so IBM+BP.L+ORCL

# we can pass some stocks from around the world
showCurrentStocks("AAPL+IBM+BP.L+BAS.DE+TEST.DE")

# we also can pass all stocks in a portfolio and display the latest quotes
# here we use the first portfolio in account
showCurrentStocks(account.pf[0])

# here just passing a single code (index)
var idx : string = indexpool[0].stock
showCurrentIndexes(idx)

# here passing in our indexpool a  seq[Stocks] type
showCurrentIndexes(indexpool)



echo()
superheader(" Tests for Current Stocks and Indexes  - Compact View")
echo()

# we can pass some stocks from around the world
showCurrentSTX("AAPL+IBM+BP.L+BAS.DE")
# we also can pass all stocks in a portfolio and display the latest quotes
# here we use the first portfolio in account
showCurrentSTX(account.pf[0])
decho(2)



echo "Passing a single code (index) \n"
idx = indexpool[0].stock
showCurrentIDX(idx)
decho(2)

echo "Passing in our indexpool a  seq[Stocks] type\n"
showCurrentIDX(indexpool)
decho(2)


echo()
superheader(" Testing getSymbol3 - Additional stock info ")
echo()

var symb = "AAPL"
var sx = getSymbol3(symb)
decho(2)
println("Stock Code : " & symb,yellow)
aline()
showStockdatatable(sx)
decho(2)


echo()
superHeader(" Tests for Forex rates ")
echo()

# look at "current" exchange rates as supplied from yahoo
echo()
printLn("Yahoo Exchange Rates",peru)
var checkcurrencies = @["EURUSD","GBPUSD","GBPHKD","JPYUSD","AUDUSD","EURHKD","JPYHKD","CNYHKD"]
showCurrentForex(checkcurrencies)


# if the exchange rates are needed for further processing
# use the getcurrentForex proc  , we receive a Cf type for unpacking
var curs = getCurrentForex(@["EURUSD","EURHKD"])
echo()
echo("Current EURUSD Rate : ",fmtx(["<8"],curs.ra.seqlast))
echo("Current EURHKD Rate : ",fmtx(["<8"],curs.ra.seqfirst))
echo()



echo()
superHeader(" Test for Kitco Metal Prices ")
showKitcoMetal()
echo()


echo()
superheader(" Testing Utility Procs ")
echo()

var FV : float = 10000
var PV : float = 0.0
var r  : float = 0.0625
var m  : int   = 2
var t  : int   = 12

echo "Test  : presentValue "
PV = presentValue(FV,r,m,t)
echo PV

PV = presentValue(FV,0.0625,2.0,12.0)
echo PV

echo()
echo "Test  : presentValueFV"

PV = presentValueFV(FV,0.0625,10)
echo PV

PV = presentValueFV(FV,0.0625,10.0)
echo PV

when declared(libFinHk):
        echo()
        superheader(" Testing HKEX related procs  requires libFinHk ")
        echo()


        var hxc = initHKEX()
        # at this stage three lists are available for work in hxc
        if hxc.len > 0:
          # # we can show all 1500+ stocks too ..
          # printLn("Full List of Hongkong Stock Exchange MainBoard Listed Stocks") # show all
          # for x in 0.. <hxc[0].len :
          #   try:
          #      echo "{:<5} {:<7} {:<22}  {:>6}".fmt(x + 1,hxc[0][x],hxc[1][x],hxc[2][x])
          #   except:
          #      echo "Problem with ",x

          echo()
          printLn("Top 50  List of Hongkong Stock Exchange MainBoard Listed Stocks",green)
          printLn(fmtx(["<5","<7", "<22",  "<10"],"No.","Code ","Name  ","BoardLot"),cyan)
          for x in 0.. <50 :
            try:
               echo(fmtx(["<5","","<7","","<22","",">6"],x + 1,spaces(1),hxc[0][x],spaces(1),hxc[1][x],spaces(1),hxc[2][x]))
            except:
               printLn("Problem with item in hkex.csv" & $x,truetomato)

          echo()
          printLn("Bottom 10  List of Hongkong Stock Exchange MainBoard Listed Stocks",green)
          for x in hxc[0].len-10.. <hxc[0].len :
             try:
                echo(fmtx(["<5","","<7","","<22","",">6"],x + 1,spaces(1),hxc[0][x],spaces(1),hxc[1][x],spaces(1),hxc[2][x]))
             except:
                println("Problem with item in hkex.csv" & $x,red)

        else:
             # in case of parsing errors due to issues with the website we return some message
             printLn("An error has occured and no valid result set was returned",red)


        printLn("Test for hkexToYhoo - show bottom 10 codes converted to yahoo format",yellow)
        if hxc.len > 1:
           for x in (hxc[0].len - 10).. <hxc[0].len :
                 echo(fmtx(["<7","",""],hxc[0][x]," --->  ",hkexToYhoo(hxc[0][x])))


        echo()
        superheader(" Create a Random Portfolio with 10 stocks   ")
        echo()

        # lets create a portfolio with 10 random hongkong stocks
        # get available stock codes  alternatively you can use the
        # hkRndportfolio function from libFinHk.nim  for example see nimFinT7.nim
        # 
        let hkexcodes = initHKEX()
        # hkexcodes now holds three seqs namely : stockcodes,companynames,boardlots
        # for easier reading we can introduce constants
        const
           stockcodes   = 0
           companynames = 1
           boardlots    = 2

        # we need a place to put the random stocks to be selected from hkexcodes
        # lets call it randomstockpool
        var randomstockpool = initPool()
        
        var rc = 0
        while rc < 10:
                  # get a random number between 1 and max no of items in hkexcodes[0]
                  var rdn = getRndInt(1,hkexcodes[stockcodes].len)
                  
                  # pick the stock with index number rdn from hxc[stockcodes]
                  # and convert to yahoo format then add it to a pool called randomstockpool
                  var arandomstock = hkexToYhoo(hxc[stockcodes][rdn])
                  
                  var astartDate = "2014-01-01"
                  var aendDate = getDatestr()
                  
                  #load the historic data for arandomstock into our randomstockpool
                  if arandomstock.startswith("    ") == true:
                        discard
                  else:
                        var dxz = getSymbol2(arandomstock,astartDate,aendDate)
                        if dxz.stock.startswith("Error") == false:   # effect of errstflag in nimFinLib
                          if dxz.stock.startswith("    ") == false:
                              randomstockpool.add(dxz)
                              doassert randomstockpool.seqfirst.stock == dxz.stock
                              inc rc
                    
    

        # at this stage the historic data is ready to be used
        # create a portfolio named rpf and call it RandomTestPortfolio
        var rpf = initPortfolio()
        # rpf.nx holds the relevant portfolio name
        rpf.nx = "RandomTestPortfolio"
        # rpf.dx will hold the relevant historic data for all stocks
        # here we load all data in our randomstockpool into the new portfolio
        rpf.dx = randomstockpool                             
        decho(2)
        printLn("\nshowQuoteTableHk\n",salmon)
        showQuoteTableHk(rpf)
        printLn("\nshowStocksTable\n",salmon)
        showStocksTable(rpf)

        # for another more automated example see nimFinT3.nim and nimFinT4.nim



when isMainModule:
  # show time elapsed for this run
  when declared(libFinHk):
      decho(2)
      printLn(fmtx(["<15","","","",""],"Library     : ","qqTop libFinHk : ",LIBFINHKVERSION," - ",nimcx.year(getDateStr())),brightblack)
  nimcx.doFinish()
