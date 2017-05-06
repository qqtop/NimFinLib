import cx,nimFinLib

# nfT50.nim
# Example program for using stock and index display routines
# needs to be run in a full terminal window
# best results in bash konsole with
# font : hack
# font : size 8
# background color black
# 
cleanscreen()
curset()
curdn(1)
showCurrentIDX("^HSI+^GSPC+^FTSE+^GDAXI+^FCHI+^N225+^JKSE",xpos = 5 ,header = true)
curset()
curdn(1)
showCurrentSTX("IBM+BP.L+0001.HK+0027.HK+SNP+AAPL+BAS.DE",xpos = 72,header = true)
curdn(5)
doFinish()  
