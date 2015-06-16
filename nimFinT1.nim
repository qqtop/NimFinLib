import nimFinLib,times,strfmt

# nimFinLib simple tests
# here we just use the Df object

var z : Df
z = getsymbol2("1766.HK","2014-01-01",getDateStr())

var ix:Df
ix = getsymbol2("^HSI","2014-01-01",getDateStr())

# calc a 22 day ema    
var ndays = 22
var ema22 = ema(z,ndays)
showEma(ema22,5)

# show returns closing price
showdailyReturnsCl(z,5)     

# RSI still under development current values are borked
var RSI = rsi(z,22)
echo "RSI for : ",stockDf(z)
showRsi(RSI,5)

echo()
msgy() do: echo "Close prices for ",z.stock
var dada = timeseries(z,"c")
# show it
showTimeseries(dada,"Close-HEAD","head",5)
showTimeseries(dada,"Close-TAIL","tail",5)

#showcurrentStocks(z.stock)

# we are still a bit off quantmod
echo " Sharpe std.dev  : " ,sharpe(z,ix)
