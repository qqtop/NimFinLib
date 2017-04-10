import os,terminal,strfmt,times
import nimFinLib,libFinHk,cx

# nimFinT7.nim
#
# this example shows usage of function hkRandomPortfolio from libFinHk
# every run creates a new portfolio . Errors may occure if stock
# selected is very new and/or insufficient datapoints available from yahoo
# Portfolios can be processed for further usage
#
# we try to follow value of portfolio over time and state value at closing price
# based on nimFinT4.nim
#
# compile : nim c -r -d:release nimFinT7
# may or may not run depending on availability of random stock data
# in case of old hkex.csv  delete it , it will be automatically recreated

echo()
hdx(printLn("Testing nimFinLib                  nimFinT7",yellowgreen,xpos = 8),width = 60)
echo()
# create a random HK stock portfolio with 5 stocks and default start,end dates
var myPf = hkRandomPortfolio(2,"2016-01-05",getdateStr())[0]
decho(2)
# myPf now holds a Nf object and a seq[int],we only need the Nf object
# anything else will be taken care of automatically
printLn("Portfolio Name    : " & myPf.nx,yellowgreen)
showQuoteTableHk(myPf)
showStocksTable(myPf)

echo(myPf.dx)