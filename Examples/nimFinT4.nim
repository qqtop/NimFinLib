import os,terminal,strfmt,times
import nimFinLib,libFinHk,cx

# nimFinT4.nim
#
# this example shows usage of function quickPortfolioHk from libFinHk
# every run creates a new portfolio . Errors may occure if stock
# selected is very new and/or insufficient datapoints available from yahoo
# Portfolios can be processed for further usage
#
# compile : nim c -r -d:release nimFinT4
#

echo ()
printLn("# Testing nimFinLib                  nimFinT4 #",yellowgreen)
echo ()
# create a random HK stock portfolio with 5 stocks and default start,end dates
var myPf = quickPortfolioHk(5)
decho(2)
# myPf now holds a Nf object and a seq[int],we only need the Nf object
# anything else will be taken care of automatically
printLn("Portfolio Name    : " & myPf.nx,yellowgreen)
showQuoteTableHk(myPf)
showStocksTable(myPf)

# further processing:
# myPf.nx holds the name of the portfolio
# myPf.dx holds the datapoints


when declared(libFinHk):
   printLn("Test for    : ",truetomato)
   printLnBiCol("{:<15}{} - {}".fmt("Library     : libFinHk ",LIBFINHKVERSION,year(getDateStr())))
doFinish()
