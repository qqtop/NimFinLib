import cx,nimFinLib

# Example program for using stock and index display routines
# needs to be run in a full terminal window

cleanscreen()
curset()
curdn(1)
showCurrentIDX("^HSI+^GSPC+^FTSE+^GDAXI+^FCHI+^N225+^JKSE",xpos = 5 ,header = true)
curset()
curup(1)
showCurrentSTX("IBM+BP.L+0001.HK+0027.HK+AAPL+BAS.DE+MIE1.F",xpos = 72,header = true)
curdn(5)
doFinish()   