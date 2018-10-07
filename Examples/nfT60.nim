import nimcx
import nimFinLib
import nimdataframe

#
# example nfT60.nim
# 
# shows use of avDataFetcherGlobal function
# stocks or indexes can be requested 
# https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=^OMX&apikey=

let apikey = ""
if apikey == "":
  printLnErrorMsg("Valid API key required. Visit : https://www.alphavantage.co  to get one ")
  echo()
  doByeBye()
  echo()
  quit(0)
  
  
let stockset = @["0386.HK","SNP","BAS.DE","BP.L"]


#here we use the second usage of the avDataFetcherGlobal function to get all data in a seq of stock or index codes
printLnInfoMsg("Test for ","""avDataFetcherGlobal(stockset,"compact",apikey = apikey)""")
echo()
discard avDataFetcherGlobal(stockset,"compact",apikey = apikey)
#showRawdata()  # displays what actually was fetched this data resides in /dev/shm/avdata
#echo()
 
# create a nice df with the fetched data
var ndf1 = createDataFrame(avtempdata,cols = 10,hasHeader = true) 
ndf1.colwidths = @[10,10,10,10,10,15,15,10,10,10]     

# for convenience we load the df.cols into seqs
# anotherway is var myretcol = getcoldata(ndf1,6)  # 

# need to massage the df like so
#symbol,open,high,low,price,volume,latestDay,previousClose,change,changePercent

# start from row 1 as there is a header
# the avDataFetcherGlobal returns a header row and a data row
# we got 10 columns confirm this by running showRawdata()
# we also know that the df looks like this : ndf1.df[row][column]
# hence we attach our data like so
# 
var symbolcol = newSeq[string]()
for x in 1 ..< ndf1.rowcount: symbolcol.add(ndf1.df[x][0])
doassert symbolcol == getcoldata(ndf1,1)  # note the getcoldata first col == 1 
  
var opencol = newSeq[float]()
for x in 1 ..< ndf1.rowcount: opencol.add(parseFloat(ndf1.df[x][1])) 
  
var highcol = newSeq[float]()
for x in 1 ..< ndf1.rowcount: highcol.add(parseFloat(ndf1.df[x][2])) 
  
var lowcol = newSeq[float]()
for x in 1 ..< ndf1.rowcount: lowcol.add(parseFloat(ndf1.df[x][3]))   
  
var pricecol = newSeq[float]()
for x in 1 ..< ndf1.rowcount: pricecol.add(parseFloat(ndf1.df[x][4]))   

var volumecol = newSeq[float]()
for x in 1 ..< ndf1.rowcount: volumecol.add(parseFloat(ndf1.df[x][5]))
        
var latestDaycol = newSeq[string]()
for x in 1 ..< ndf1.rowcount: latestDaycol.add(ndf1.df[x][6])

var prevclosecol = newSeq[float]()
for x in 1 ..< ndf1.rowcount: prevclosecol.add(parseFloat(ndf1.df[x][7]))
  
var changecol = newSeq[float]()
for x in 1 ..< ndf1.rowcount: changecol.add(parseFloat(ndf1.df[x][8]))  
  
var changepctcol = newSeq[string]()
for x in 1 ..< ndf1.rowcount: changepctcol.add(ndf1.df[x][9])
  
# lets see what we got 
curup(4)
showDf(ndf1,
        rows = ndf1.rowcount,
        cols =  toNimis(toSeq(1..ndf1.colcount)),                       
        colwd = ndf1.colwidths,
        colcolors = ndf1.colcolors,
        showFrame =  true,
        framecolor = skyblue,
        showHeader = true,
        headertext = ndf1.colheaders,
        leftalignflag = false,
        xpos = 3) 
        
decho(2) 
doFinish()         
