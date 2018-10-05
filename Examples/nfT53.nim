import nimcx
import nimdataframe
import nimFinLib

# nfT53   initial demo for new nimFinLib
# see nimFinLib for more information , a temp file will be stored in the tempfs at dev/shm
# temp file location can be changed in nimFinLib if needed
# Note : the demo apikey may only work so often , get your own free apikey for better experience
#        api may return funny data for time series if market is closed or api hid to fast 
#        standard call-frequency limit 5 requests per minute for free apikey 
# 
# status : ok 2018-10-05

let apikey = "demo"       # if you have apikey from alphavantage insert here and alternative stockset will be used

var stockset = newSeq[string]()
if apikey == "demo": stockset = @["MSFT"]
else:  stockset =  @["RIO","BAS.DE","BP.L","SNP"]  
       #stockset = @["0386.HK","0880.HK","0005.HK","0939.HK","1113.HK"]            
            
    
proc main() = 
   cleanScreen()
   #decho(2) 
   hdx(printLnBiCol("  nimFinLib - Example : nfT53.nim   Display stock data in a nimdataframe "))
   #decho(2)
   
   for x in 0..<stockset.len: 
      var ndf9 = showStocksDf(stockset[x],apikey = apikey)  
      showDataframeInfo(ndf9)              # ok
      dfShowColumnStats(df = ndf9,desiredcols = @[3,4,5,6],xpos = 3)   # ok     note count of cols starts with 1
      dfsave(ndf9,"ndf9-" & stockset[x] & ".csv",quiet = false)        # save the current dataframe and show saving results
      showrawdata()
      showOriginalStockDf(stockset[x],rows = 100,apikey = apikey)   # ok
      
      
   decho(1)
   for x in 0..<stockset.len:
      printlnBiCol("Load testing : " & "ndf9-" & stockset[x] & ".csv",xpos=3)
      echo()
      var ndf10 = dfLoad("ndf9-" & stockset[x] & ".csv")
      showLocalStocksDf(ndf10,xpos = 3)       # <--- using showLocalStocksDf as we have reloaded saved data via dfLoad
      echo()
      
   decho(1)       
   printBiCol(fmtx(["","",],"Data Source : " , " TIME_SERIES_DAILY_ADJUSTED  by Alpha Vantage"),colleft=slategray,colright=pastelwhite,sep=":",xpos = 3,false,{styleReverse})       
   
      
main()
doFinish()

   

   
   
 
