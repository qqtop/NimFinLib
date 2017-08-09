import os,nimFinLib
import nimcx 
# show latest stock quotes , with stock codes passed in from commandline

if paramCount() > 0:
   showCurrentStocks(paramStr(1))
   decho(2)
else:
   printLn("Usage :",peru)
   printLn("example2  IBM+BP.L+AAPL",peru)
   echo()
quit 0
