import os,terminal,strfmt,times
import nimFinLib,libFinHk

# nimFinT4.nim
#
# this example shows usage of function hkRandomPortfolio from libFinHk
# every run creates a new portfolio .
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

# somePf now holds a Nf object and a seq[int]
var myPf = somePf[0]
var myseq = somePf[1]

# see if the data tables display
decho(2)
msgg() do: echo "Portfolio Name    : ",myPf.nx

showQuoteTableHk(myPf,myseq)
showDfTable(myPf)


when isMainModule:
  # show time elapsed for this run
  when declared(libFinHk):
      decho(2)
      msgb() do : echo "{:<15}{} {} - {}".fmt("Library     : ","qqTop libFinHk : ",LIBFINHKVERSION,year(getDateStr()))
  doFinish()
