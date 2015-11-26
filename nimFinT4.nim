import os,terminal,strfmt,times
import nimFinLib,libFinHk,cx

# nimFinT4.nim
#
# this example shows usage of function hkRandomPortfolio from libFinHk
# every run creates a new portfolio . Errors may occure if stock
# selected is very new and/or insufficient datapoints available from yahoo
# Portfolios can be processed for further usage
#
# compile : nim c -r -d:release nimFinT4
#

echo ()
msgy() do : echo "###############################################"
msgy() do : echo "# Testing nimFinLib                  nimFinT4 #"
msgy() do : echo "###############################################"
echo ()
# create a random HK stock portfolio with 5 stocks and default start,end dates
var somePf = hkRandomPortfolio(5)
decho(2)
# somePf now holds a Nf object and a seq[int],we only need the Nf object
# anything else will be taken care of automatically
var myPf = somePf[0]
msgg() do: echo "Portfolio Name    : ",myPf.nx
showQuoteTableHk(myPf)
showStocksTable(myPf)

when isMainModule:
  # show time elapsed for this run
  when declared(libFinHk):
      decho(2)
      msgb() do : echo "{:<15}{} {} - {}".fmt("Library     : ","qqTop libFinHk : ",LIBFINHKVERSION,year(getDateStr()))
  doFinish()
