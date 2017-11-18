import nimcx,nimFinLib

# example7
# showing timeseries usage and ema head and tail display
# show adj. close price , 5 rows head and tail 374 days apart

var myD = initStocks()
var mystockcode = "0386.HK"

myD = getSymbol2(mystockcode,minusdays(getDateStr(),374),getDateStr())
var mydT = timeseries(myD,"a") # adjusted close

curup(1)
echo()

print(" Current Data ",salmon)
print("Historic Data ",pink,xpos = 35)
printLnBiCol("Code : " & mystockcode,xpos = 55)
hlineln(70)

showTimeSeries(mydT,"AdjClose",head,5)
curup(6)
showTimeSeries(mydT,"AdjClose",tail,5,xpos = 30)

showEMA(ema(myD),5,head,xpos = 1)
curup(7) 
showEMA(ema(myD),5,tail,xpos = 30)

doFinish()
