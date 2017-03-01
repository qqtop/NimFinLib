import cx,nimFinLib

# Example program for using stock and index display routines
# Run in a full terminal window size 80 x 40 column/rows
# Font      : monospace 
# Font Size : 9

cleanscreen()
showCurrentIDX("^HSI+^GSPC+^FTSE+^GDAXI+^FCHI+^N225+^JKSE",xpos = 5 ,header = true)
decho(2)
showCurrentSTX("SNP+BP.L+0001.HK+AAPL+0027.HK+BAS.DE+MIE1.F",xpos = 5,header = true)
curdn(5)
doFinish()   