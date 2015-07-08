import os,terminal,strfmt,times
import nimFinLib


# nimFinT3.nim
#
# an example to show usage of nimFinLib
# here we setup an account called master and load it with a portfolio
# called hkportfolio which contains historical hongkong stocks data,
# then we display some statistics and information
# the first time it may take a few seconds as the stockcodes
# will need to be scraped and will be saved to hkex.csv .
#


echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Testing nimFinLib                           #"
msgy() do : echo "###############################################"
echo ()

var hkpool    = initPool()
var master    = initPf()
var hkportfolio = initNf()
#lets use 500 days of historic data
var startDate = minusDays(getDateStr(),500)
var endDate   = getDateStr()
var stockseq  = newSeq[int]()
# hkexcodes has info about stockcodes,companynames,boardlots of the HongKong Stock Exchange
var hkexcodes = initHKEX()
# name the portfolio
hkportfolio.nx = "Portfolio"
# we take first 5 stockcodes from hkexcodes
# and load stocks with relevant historical data into hkpool
for x in 0.. <5:
    # need to convert to yhoo format
    var astock = hkexToYhoo(hkexcodes[0][x])
    hkpool.add(getSymbol2(astock,startDate,endDate))
    # keep track of the item no
    stockseq.add(x)

# load data into the portfolio
for stocksdata in hkpool:
     hkportfolio.dx.add(stocksdata)

# add portfolio to master
master.pf.add(hkportfolio)

# now lets see some data
# currently there is only 1 portfolio in our master

for x in 0.. <master.pf.len:
   showQuoteTable(master.pf[x],stockseq)
   showDfTable(master.pf[x])


when isMainModule:
  doFinish()
