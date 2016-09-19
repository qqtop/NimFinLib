import cx,nimFinLib,libFinHk

# Example nimFinT6   for Hongkong stocks only
# show use of var routines
# 
# How to use Stocks and Stockdata types
 

var mystockcode = "0386.HK"   # yahoo stock code

# Stocks type
var myD = initStocks()
myD = getSymbol2(mystockcode,minusdays(getDateStr(),365),getDateStr())  
var boardlot = getBoardlot(myD)
var comp = getCompanyName(myD)

# Stockdata type
var myD2 = getSymbol3(mystockcode)  


echo clearline
printlnbicol("Code     : " & myD.stock)  
printlnBiCol("Company  : " & comp)
printlnBiCol("Boardlot : " & boardlot)
printlnBiCol("Date     : " & myD.date[0])  # most recent date on yahoo

printlnBiCol("Cur.Price: " & ff2(myD2.price,4) & "  Moving Avg. 50 days: " & ff2(myD2.movingavg50day,4))
var costperboardlot = myD2.price * parseFloat(boardlot)
printlnBiCol("Cost     : " & ff2(costperboardlot,2) & " per boardlot")

doFinishHk()       

