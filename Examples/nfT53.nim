import nimcx,nimdataframe,nimFinLib
# nfT53   initial demo for new nimFinLib


let apikey = "demo"

var stockset = newSeq[string]()
if apikey == "demo": stockset = @["MSFT"]
else:  stockset = @["0386.HK","0880.HK","0005.HK","0939.HK","0127.HK"]   
#stockset = @["RIO","CHL","BAS.DE","BP.L","ORCL"] 
           
             
    
proc main() = 
   cleanScreen()
   decho(2) 
   hdx(printLnBiCol("  nimFinLib   example : nfT54.nim   display stock data in a nimdataframe "))
   decho(2)
   for x in stockset: 
      var ndf9 = showStocksDf(x,apikey = apikey)  
      #showDataframeinfo(ndf9)  # ok
      dfShowColumnStats(ndf9,@[3,4,5])
   decho(2)
   #for x in stockset: showOriginalStockDf(x,rows = 1000,apikey = apikey)   #ok
   decho(2)       
   printBiCol(fmtx(["","",],"Data Source : " , " TIME_SERIES_DAILY_ADJUSTED  by Alpha Vantage"),colleft=slategray,colright=pastelwhite,sep=":",xpos = 3,false,{styleReverse})       
   #showRawData()  # ok
   
main()
doFinish()

   
   
 
