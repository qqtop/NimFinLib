import nimFinLib,cx,strutils,times

# example6 
# 
# shows how to use ema function
# 

var ibm = initStocks()
ibm = getsymbol2("ibm","2000-01-01",getDateStr())
var ndays = 22
var ema22 = ema(ibm,ndays)

decho(2)

println("Latest 5 EMA for : " & ibm.stock,peru)
showEma(ema22,5) # shows ema table with newest on top

decho(2)

println("Oldest EMA  and Newest EMA  $1 days" % $ndays,peru)
printlnbicol(ema22.dd.seqlast  & " :  " & $ema22.tx.seqlast)   # oldest last in seq
printlnbicol(ema22.dd.seqfirst & " :  " & $ema22.tx.seqfirst)  # newest first in seq
             
             
doFinish()             