import nimFinLib,times,strfmt,cx

# nimFinLib simple tests
# here we just use the Stocks object

var z : Stocks
z = getsymbol2("1766.HK","2014-01-01",getDateStr())

var ix: Stocks
ix = getsymbol2("^HSI","2014-01-01",getDateStr())

# calc a 22 day ema
var ndays = 22
var ema22 = ema(z,ndays)
showEma(ema22,5)

# show returns closing price
showdailyReturnsCl(z,5)

echo()
msgy() do: echo "Close prices for ",z.stock
var dada = timeseries(z,"c")
# show it
showTimeseries(dada,"Close-HEAD","head",5)
showTimeseries(dada,"Close-TAIL","tail",5)

showCurrentStocks(z.stock)
