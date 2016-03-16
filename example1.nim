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
