import nimcx , nimdataframe

# av_currencies
# 
# a simple utility which displays current world and digital currencies 
# available via Alpha Vantage API
# 
# 2018-04-26
# 


cleanscreen()
let ufo =  "https://www.alphavantage.co/physical_currency_list/"    
var ndf9 = createDataFrame(ufo,hasHeader = true)

let ufo2 =  "https://www.alphavantage.co/digital_currency_list/"    
var ndf10 = createDataFrame(ufo2,hasHeader = true)

ndf9 = dfDefaultSetup(ndf9)   # basic setup
ndf9.colwidths = @[15,30]     
ndf9.colcolors = @[gold,pastelblue]
echo()
showDf(ndf9,
   rows  = ndf9.rowcount - 1,   # header
   cols  = toNimis(toSeq(1..ndf9.colcount)),                       
   colwd = ndf9.colwidths,
   colcolors = ndf9.colcolors,
   showFrame = true,
   framecolor = dodgerblue,
   showHeader = true,
   leftalignflag = false,
   xpos = 3) 
decho(3)
printLnBiCol("Data Source : " & ufo)
#showDataframeInfo(ndf9)

# digital currencies
# # this df is very long so lets try to split it into 3
# 
ndf10 = dfDefaultSetup(ndf10)   # basic setup
ndf10.colwidths = @[15,30]     
ndf10.colcolors = @[dodgerblue,pastelblue]
echo()

showdf(ndf10,
   rows  = ndf10.rowcount - 1,   # header
   cols  = toNimis(toSeq(1..ndf10.colcount)),                       
   colwd = ndf10.colwidths,
   colcolors = ndf10.colcolors,
   showFrame = true,
   framecolor = dodgerblue,
   showHeader = true,
   #headertext = @[],   # hasheader
   leftalignflag = false,
   xpos = 3) 
decho(2)

printLnBiCol("Data Source : " & ufo2)
#showDataframeInfo(ndf10)
doFinish()
