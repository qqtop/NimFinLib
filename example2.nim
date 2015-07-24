import os,nimFinLib

# show latest stock quotes , with stock codes passed in from commandline

if paramCount() > 0:
   showCurrentStocks(paramStr(1))
   decho(2)
else:
   msgy() do :
              echo "Usage :"
              echo "example2  IBM+BP.L+AAPL"
              echo()
quit 0
