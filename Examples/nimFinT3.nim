import os,terminal,strfmt,times,strutils
import nimFinLib,libFinHk,cx


# nimFinT3.nim
#
# an example to show usage of nimFinLib and libFinHk

# here we setup an account called master and load it with a portfolio
# called hkportfolio which contains historical hongkong stocks data,
# then we display some statistics and information
# the first time it may take a few seconds as the stockcodes
# will need to be scraped and will be saved to hkex.csv in the current working dir.
#


echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Testing nimFinLib                  nimFinT3 #"
msgy() do : echo "###############################################"
echo ()

var hkpool      = initPool()
var master      = initAccount()
var hkportfolio = initPortfolio()
#lets use 500 days of historic data
var startDate = minusDays(getDateStr(),500)
var endDate   = getDateStr()

# hkexcodes has info about stockcodes,companynames,boardlots of the HongKong Stock Exchange
var hkexcodes = initHKEX()
# name the portfolio
hkportfolio.nx = "HKPortfolio"
# we take first 5 stockcodes from hkexcodes
# and load stocks with relevant historical data into hkpool
for x in 0.. <30:
    # need to convert to hkex code format into yhoo format
    var astock = hkexToYhoo(hkexcodes[0][x])
    hkpool.add(getSymbol2(astock,startDate,endDate))


# load data into the portfolio
for stocksdata in hkpool:
     hkportfolio.dx.add(stocksdata)

# add portfolio to master
master.pf.add(hkportfolio)

# now we add a second portfolio of some HK stockcodes
var bigMoney = initPortfolio()
bigMoney.nx = "bigMoneyPortfolio"

#var bigMSymbols  = @["00386","00880","00005"]         # HKEX style
var bigMSymbolsY = @["0386.HK","0880.HK","1766.HK","0555.HK","3888.HK"]   # yahoo style


for x in bigMSymbolsY:
   var z: Stocks
   if x.endswith(".HK"):
      z = getSymbol2(x,startDate,endDate)
   else:
      z = getSymbol2(hkexToYhoo(x),startDate,endDate)
   bigMoney.dx.add(z)

master.pf.add(bigMoney)

# now lets see some data
# currently there are only 2 portfolios in our master

for x in 0.. <master.pf.len:
      echo()
      printLn(master.pf[x].nx,yellowgreen)
      showQuoteTableHk(master.pf[x])
      showStocksTable(master.pf[x])

# so with these few lines of code we have a setup to any number of
# portfolios for which we can show stats,quote,names and historic data

when isMainModule:
    when declared(libFinHk):
        decho(2)
        msgb() do : echo "{:<15}{} {} - {}".fmt("Library     : ","qqTop libFinHk : ",LIBFINHKVERSION,year(getDateStr()))
    doFinish()
