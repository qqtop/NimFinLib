import cx,nimFinLib,libFinHk

# Example nimFinT5   for Hongkong stocks only
# show use of var routines
# 
# Assuming we buy 1 share each day for n days 
# and sell after exactly yrs years after buying in what wud be the p/l
# costs disregarded

var mystockcode = "0386.HK"   # yahoo stock code
var n   = 25      # transactions for n days 
var yrs = 6       # buying in years ago 

var myD = initStocks()
myD = getSymbol2(mystockcode,minusdays(getDateStr(),365 * yrs),getDateStr())
var mydT = timeseries(myD,"a") # adjusted close
var boardlot = getBoardlot(myD)
      
println("Data for : " & myD.stock & " " & getCompanyName(myD),lime)
println("Boardlot : " & boardlot,peru)
echo()

println("Buying  1 share every day for " & $n & " days")
println("After " & $yrs & " years")
println("Selling 1 share every day for " & $n & " days")
echo()

println(fmtx(["",">30"],"Buy","Sell"),salmon,styled={styleUnderscore})
showTimeSeries(mydT,"AdjClose","tail",th - 2)            # current ,th is terminalheight
curup(th - 1)
showTimeSeries(mydT,"AdjClose","head",th - 2,xpos = 30)  # historical

if n > th :
  println("Displaying only rows which fit into current terminal height",peru)

decho(2)
var tail = newseq[float]()
var head = newseq[float]()
var headday = newseq[string]()
var tailday = newseq[string]()

# tail --  buy in sequence
for x in (mydT.tx.len - n).. <mydT.tx.len:
        tail.add(mydT.tx[x])
        tailday.add(mydT.dd[x])
        
# head --  sell out sequence       
for x in 0.. <n:
        head.add(mydT.tx[x]) 
        headday.add(mydT.dd[x])

#echo tailday.min  # first buy day 
#echo headday.max  # last sell day 
  
var pl = 0.0   
println(fmtx(["",">23",">10",">10",">15"],"Day : ","Buy Date / Sell Date","Buy","Sell","P/L"),salmon,styled={styleUnderscore})

for x in 0.. <n:
  
    var rs = head[x] - tail[x]
    pl = pl + rs
         
    if rs >= 0:
       println(fmtx(["",">23",">10",">10",">15"],"Day : ",tailday[x] & "/" & headday[x],ff2(tail[x],4),ff2(head[x],4),ff2(rs,4)),yellowgreen)
    else:
       println(fmtx(["",">23",">10",">10",">15"],"Day : ",tailday[x] & "/" & headday[x],ff2(tail[x],4),ff2(head[x],4),ff2(rs,4)),red)

echo()    
if pl > 0 :
    printlnbicol("Profit / 1 Share trading    : " & ff2(pl,2))
    printlnbicol("Profit / 1 Boardlot trading : " & ff2(pl * parsefloat(boardlot),2))
else:
    printlnbicol("Loss   / 1 Share trading    : " & ff2(pl,2),":",red)
    printlnbicol("Profit / 1 Boardlot trading : " & ff2(pl * parsefloat(boardlot),2))   

doFinishHk()
