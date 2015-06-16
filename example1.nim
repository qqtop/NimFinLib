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
