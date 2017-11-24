import nimcx,nimdataframe,nimFinLib
# nfT53   initial demo for new nimFinLib
# see nimFinLib for more information , a temp file will be stored in the tempfs at dev/shm
# status : ok 2017-11-24

let apikey = "demo"       # if you have apikey from alphavantage insert here and alternative stockset will be used

var stockset = newSeq[string]()
if apikey == "demo": stockset = @["MSFT"]
else:  stockset =  @["RIO","CHL","BAS.DE","BP.L","ORCL"]  
#stockset = @["0386.HK","0880.HK","0005.HK","0939.HK","0127.HK"]            
             
    
proc main() = 
   cleanScreen()
   decho(2) 
   hdx(printLnBiCol("  nimFinLib   example : nfT53.nim   display stock data in a nimdataframe "))
   decho(2)
   for x in 0..<stockset.len: 
      var ndf9 = showStocksDf(stockset[x],apikey = apikey)  
      showDataframeinfo(ndf9)              # ok
      dfShowColumnStats(ndf9,@[3,4,5,6])   # ok     note count of cols starts with 1
      dfsave(ndf9,"ndf9-" & stockset[x] & ".csv",quiet = false)        # save the current dataframe and show saving results
      showOriginalStockDf(stockset[x],rows = 1000,apikey = apikey)   # ok
   decho(2)
   for x in 0..<stockset.len:
      printlnBiCol("Load testing : " & "ndf9-" & stockset[x] & ".csv",xpos=3)
      echo()
      var ndf10 = dfLoad("ndf9-" & stockset[x] & ".csv")
      showLocalStocksDf(ndf10,xpos = 3)       # <--- using showLocalStocksDf as we have loaded data via dfLoad
      echo()
      
   decho(2)       
   printBiCol(fmtx(["","",],"Data Source : " , " TIME_SERIES_DAILY_ADJUSTED  by Alpha Vantage"),colleft=slategray,colright=pastelwhite,sep=":",xpos = 3,false,{styleReverse})       
   
      
main()
doFinish()

   

   
   
 
