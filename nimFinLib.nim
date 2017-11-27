
##::
##
## Program     : nimFinLib
##
## Status      : Development    
##
## License     : MIT opensource
##
## Version     : 0.3.0.0
##
## Compiler    : nim 0.17.x  dev branch
##
##
## Description : A basic library for financial calculations with Nim 
## 
##               using data from Alpha Vantage API
##
##               Currency , Stock and Index 
##
##               Kitco Metal Prices  
##
##               Dataframe like objects for easy working with current and historical data 
##
##               EMA,SMA,WMA,RSI,WILLR,BBANDS Indicator   # Note may not be available for all stocks/markets
##
##               Returns calculations
##
##               Data display procs 
##               
##               Simple plotting (planned )
##               
##               Dataframe save/reload complete with display parameters
##
##               Dataframe rotation  
##               
##               Portfolio management ( Random portfolio , User portfolio )
##               
##               
##               
## Project     :  https://github.com/qqtop/NimFinLib
##
## Tested on   :  Linux
##
## ProjectStart: 2015-06-05 
## 
## Latest      : 2017-11-27
##
## NOTE        : 
##                              
## 
## Todo        : too much to state here , but working on it
##               
##
## Programming : qqTop
##
##
## Installation:
##
##
##               nimble install nimcx
##
##               nimble install https://github.com/qqtop/nimdataframe.git
##
##               nimble install nimFinLib 
##
##                       
##
## Notes       :
## 
##               nimFinlib is being developed utilizing nimcx.nim module and nimdataframe.nim
##
##               to improve coloring of data and positioning of output.
## 
##
## Funding     : If you are happy or unhappy send any amount of bitcoins you like to a nice wallet :
##              
##               194KWgEcRXHGW5YzH1nGqN75WbfzTs92Xk
##                     
##                     

import
       os,nimcx,nimdataframe,parseutils,net,tables,parsecsv,algorithm,math,unicode,stats    
import nre except toSeq

let NIMFINLIBVERSION* = "0.3.0.0"


# for currencies
#var callavcur  = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=CNY&to_currency=HKD&apikey=$1" % [apikey]

# temporary holding place for data fetched from alphavantage , change directory as required below
var avtempdata* = "/dev/shm/avdata.csv"    

const
      tail* = "tail"
      head* = "head"
      all*  = "all"  

type

  Portfolio* {.inheritable.} = object
        ## Portfolio type
        ## holds one portfolio with all relevant historic stocks data
        nx* : string       ## nx  holds portfolio name  e.g. MyGetRichPortfolio
        dx* : seq[Stocks]  ## dx  holds all stocks with historical data


  Account*  = object
        ## Account type
        ## holds all portfolios similar to a master account
        ## portfolios are Portfolio objects
        pf* : seq[Portfolio]  ## pf holds all Portfolio type portfolios for an account

  
  Stocks* {.inheritable.} = object of Portfolio
        ## Stocks type
        ## holds individual stocks history data and RunningStat for ohlcva columns
        ## even more items may be added like full company name etc in the future
        ## items are stock code, ohlcva, rc and rca .
        stock* : string            ## yahoo style stock code ok with alpha vantage api
        date*  : seq[string]
        open*  : seq[float]
        high*  : seq[float]
        low*   : seq[float]
        close* : seq[float]
        vol*   : seq[float]        ## volume
        adjc*  : seq[float]        ## adjusted close price
        ro*    : seq[Runningstat]  ## RunningStat for open price
        rh*    : seq[Runningstat]  ## RunningStat for high price
        rl*    : seq[Runningstat]  ## RunningStat for low price
        rc*    : seq[Runningstat]  ## RunningStat for close price
        rv*    : seq[Runningstat]  ## RunningStat for volume price
        rca*   : seq[Runningstat]  ## RunningStat for adjusted close price

      
       
var mflag = 0  # used in metal
          
proc getData22*(url:string):auto =
  ## getData
  ## 
 
  try:
       var zcli = newHttpClient()
       result  = zcli.getcontent(url)   # orig test data
  except :
       currentLine()
       printLnBiCol("Error : " & url & " content could not be fetched . Retry with -d:ssl",red,bblack,":",0,true,{}) 
       printLn(getCurrentExceptionMsg(),red,xpos = 9)
       doFinish()            
      
      
proc avDatafectcher*(stckcode:string,mode:string = "compact",apikey:string):bool =
   ## avDatafectcher
   ## fetches data from alphavantage 
   ## default = compact   abt 100 records if available
   ## option  = full      all available records
   ## Note : first row is real time if markets are open
   ## data will be written into /dev/shm/avdata.csv  .. 
   ## /dev/shm temporary filesystem location may not be available on every distribution
   ## change accordingly or write to a disc location
   ## 
   result = true
   var callav = ""
   
   if apikey == "demo":
       callav = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=MSFT&apikey=demo&datatype=csv"
   
   elif toLowerAscii(mode) == "compact":
       callav = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=$1&outputsize=compact&apikey=$2&datatype=csv" % [stckcode,apikey]
   elif toLowerAscii(mode) == "full":
       callav = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=$1&outputsize=compact&apikey=$2&datatype=csv" % [stckcode,apikey]
   else:
       currentLine()
       printLnBiCol("Error :  Wrong mode specified . Use compact or full only",colLeft=red)
       echo()
       result = false
       
   
   if result == true:
      var avdata = getData22(callav)
      try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)
           
      except:
          currentline()
          printLnBiCol("Error : Could not write to  " & avtempdata ,colLeft=red)
          echo()
          doFinish()
           
proc showRawData*() =
     ## showRawData
     ## 
     ## displays raw data currently in avtempdata  
     ## 
     nimcat(avtempdata)  
     

proc showOriginalStockDf*(stckcode:string,xpos:int = 3,rows:int = 3,header:bool = false,apikey:string = "demo"):nimdf {.discardable.} =
   ## showOriginalStockData
   ## 
   ## first data row maybe realtime if markets online
   ## here we always fetch fresh data 
   ## 
   if not avDatafectcher(stckcode,"compact",apikey): doFinish()
   else:    
      
        var ndf1 = createDataFrame(avtempdata,cols = 7,hasHeader = true) 
        ndf1.colwidths = @[13,10,10,10,10,10,11]         # change the default columnwidths created in dfDefaultSetup
        
        # how to access a certain value from the df lets get  row 1 col 1
        #echo parsefloat(ndf9.df[0][1])
        #echo parsefloat(ndf9.df[0][4])

        # calc the percentage change from last day close to current real time close
        var yday = parsefloat(ndf1.df[2][5])   # last close
        var tday = parseFloat(ndf1.df[1][5])   # current close
        var pctchange = ((yday / tday) - 1.0) * -100.0 
        var actchange = tday - yday
        var tdayopen = parseFloat(ndf1.df[1][2])

        # set up df colors we only change close and adjusted close 
        if   yday < tday == true: ndf1.colcolors = @[pastelgreen,pastelpink,lightblue,goldenrod,lime,lime,white]  
        elif yday > tday == true: ndf1.colcolors = @[pastelgreen,pastelpink,lightblue,goldenrod,truetomato,truetomato,white]
        else:  ndf1.colcolors = @[pastelgreen,pastelpink,dodgerblue,gold,skyblue,skyblue,white]
        ndf1.colheaders = @["timestamp","open","high","low","close","adjclose" ,"volume"]
        
        printLnBiCol("Original Data  : " & spaces(1) & stckcode,xpos = xpos)
        showDf(ndf1,
            rows = rows,  #if there is a header we need 2 rows ,if there is no header and the header is passed in 1 row 
                          #of course we can show more rows like here show last three dates 1 row is realtime if markets open
            cols =  toNimis(toSeq(1..ndf1.colcount)),                       
            colwd = ndf1.colwidths,
            colcolors = ndf1.colcolors,
            showFrame =  true,
            framecolor = blue,
            showHeader = true,
            #headertext = ndf1.colheaders,  # not needed as we have headers in the incoming csv file
            leftalignflag = false,
            xpos = xpos) 
        echo()
        result = ndf1     
        
proc showStocksDf*(stckcode:string,xpos:int = 3,header:bool = false,apikey:string = "demo"):nimdf {.discardable.} =
     ## showStocksDf
     ## 
     ## a display routine with some more information
     ## data is freshly downloaded
     ## 
      
     if not avDatafectcher(stckcode,"compact",apikey): doFinish()
     else:    
               
        var ndf9 = createDataFrame(avtempdata,cols = 7,hasHeader = true)
        
        # here we start to add a new column not found in ndf9 (the original data received)
        # we want it to be the first col of our df and in all rows has the stock code stckcode passed in above
        # the way to do this is 
        var mynewcol:nimss = @[]
        for x in 0..<ndf9.rowcount-1: mynewcol.add(stckcode) 
        # obviously we could add any old thing but for now we want stckcode
        # now just lets make a new df with mynewcol as first col and all other cols from ndf9 df
        # makeNimDf looses the header from ndf9 and we pass in a new header for our cols
        
        ndf9 = makeNimDf(mynewcol,getColData(ndf9,1),getColData(ndf9,2),getColData(ndf9,3),getColData(ndf9,4),
                            getColData(ndf9,5),getColData(ndf9,6),getColData(ndf9,7),hasHeader=true)
        #dfsave(ndf9,"ndf9.csv")  # used in debugging for checking what we get here
        ndf9.colwidths = @[8,13,10,10,10,10,10,11]         # change the default columnwidths created in dfDefaultSetup
        # how to access a certain value from the df lets get  row 1 col 1
        #echo parsefloat(ndf9.df[0][1])
        #echo parsefloat(ndf9.df[0][4])
        
        # calc the percentage change from last day close to current real time close
        var yday = parsefloat(ndf9.df[1][5])   # last close
        var tday = parseFloat(ndf9.df[0][5])   # current close
        var pctchange = ((yday / tday) - 1.0) * -100.0 
        var actchange = tday - yday
        var tdayopen = parseFloat(ndf9.df[0][2])
        
        # set up df colors we only change close and adjusted close 
        if   yday < tday == true: ndf9.colcolors = @[lightgrey,pastelgreen,pastelpink,lightblue,goldenrod,lime,lime,white]  
        elif yday > tday == true: ndf9.colcolors = @[lightgrey,pastelgreen,pastelpink,lightblue,goldenrod,truetomato,truetomato,white]
        else:  ndf9.colcolors = @[lightgrey,pastelgreen,pastelpink,dodgerblue,gold,skyblue,skyblue,white]
        ndf9.colheaders = @["code","timestamp","open", "high", "low", "close","adjclose" ,"volume"]
        
        # start to show something
            
        # we show a line with stock code,change pct ,change and last close
        # followed by the df with 3 rows of data (in compact mode abt 100 rows ,in full mode maybe thousands of rows ,here we use compact)
        printBiCol(fmtx(["",">11",],"Code :" , stckcode),colleft=olivedrab,colright=lightgrey,sep=":",xpos = xpos,false,{styleReverse})
        
        if pctchange > 0.0:
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colright=white,sep="%",xpos = xpos  + 22,false,{styleReverse})
        elif pctchange < 0.0:
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colleft=truetomato,colright=white,sep="%",xpos = xpos + 22,false,{styleReverse}) 
        else :
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colleft=skyblue,colright=white,sep="%",xpos = xpos + 22,false,{styleReverse})     
        
        
        if actchange > 0.0:
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colright=white,xpos = xpos + 42,false,{styleReverse})
        elif pctchange < 0.0:
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colleft=truetomato,colright=white,xpos = xpos + 42,false,{styleReverse}) 
        else :
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colleft=skyblue,colright=white,xpos = xpos + 42,false,{styleReverse})     
        

        if pctchange > 0.0:
                printLnBiCol(fmtx(["",">9",],"Last : " , ndf9.df[0][5]),colright=white,xpos = xpos + 62,false,{styleReverse})
        elif pctchange < 0.0:
                printLnBiCol(fmtx(["",">9",],"Last : " , ndf9.df[0][5]),colleft=truetomato,colright=white,xpos = xpos + 62,false,{styleReverse}) 
        else :
                printLnBiCol(fmtx(["",">9",],"Last : " , ndf9.df[0][5]),colleft=skyblue,colright=white,xpos = xpos + 62,false,{styleReverse})     
                    

        showDf(ndf9,
            rows = 3,  #if there is a header we need 2 rows ,if there is no header and header is passed in 1 row 
                        #of course we can show more rows like here show last three dates 1 row is realtime if markets open
            cols =  toNimis(toSeq(1..ndf9.colcount)),                       
            colwd = ndf9.colwidths,
            colcolors = ndf9.colcolors,
            showFrame =  true,
            framecolor = blue,
            showHeader = true,
            headertext = ndf9.colheaders,
            leftalignflag = false,
            xpos = xpos) 
        decho(2)
        result = ndf9
        
  
proc showLocalStocksDf*(ndf9:nimdf,xpos:int = 3):nimdf {.discardable.} =
        ## showLocalStocksDf
        ## 
        ## used to display a df which already exists or has been loaded via dfLoad
        ## with all parameters pre specified
        ## 
        ## 

        # calc the percentage change from last day close to current real time close
        var yday = parsefloat(ndf9.df[1][5])   # last close
        var tday = parseFloat(ndf9.df[0][5])   # current close
        var pctchange = ((yday / tday) - 1.0) * -100.0 
        var actchange = tday - yday
        var tdayopen = parseFloat(ndf9.df[0][2])
        
        # set up df colors we only change close and adjusted close 
        if   yday < tday == true: ndf9.colcolors = @[lightgrey,pastelgreen,pastelpink,lightblue,goldenrod,lime,lime,white]  
        elif yday > tday == true: ndf9.colcolors = @[lightgrey,pastelgreen,pastelpink,lightblue,goldenrod,truetomato,truetomato,white]
        else:  ndf9.colcolors = @[lightgrey,pastelgreen,pastelpink,dodgerblue,gold,skyblue,skyblue,white]
        ndf9.colheaders = @["code","timestamp","open", "high", "low", "close","adjclose" ,"volume"]
        
        # start to show something
            
        # we show a line with stock code,change pct ,change and last close
        # followed by the df with 3 rows of data (in compact mode abt 100 rows ,in full mode maybe thousands of rows ,here we use compact)
        printBiCol(fmtx(["",">11",],"Code :" , ndf9.df[0][1]),colleft=olivedrab,colright=lightgrey,sep=":",xpos = xpos,false,{styleReverse})
        
        if pctchange > 0.0:
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colright=white,sep="%",xpos = xpos  + 22,false,{styleReverse})
        elif pctchange < 0.0:
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colleft=truetomato,colright=white,sep="%",xpos = xpos + 22,false,{styleReverse}) 
        else :
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colleft=skyblue,colright=white,sep="%",xpos = xpos + 22,false,{styleReverse})     
        
        
        if actchange > 0.0:
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colright=white,xpos = xpos + 42,false,{styleReverse})
        elif pctchange < 0.0:
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colleft=truetomato,colright=white,xpos = xpos + 42,false,{styleReverse}) 
        else :
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colleft=skyblue,colright=white,xpos = xpos + 42,false,{styleReverse})     
        

        if pctchange > 0.0:
                printLnBiCol(fmtx(["",">9",],"Last : " , ndf9.df[0][5]),colright=white,xpos = xpos + 62,false,{styleReverse})
        elif pctchange < 0.0:
                printLnBiCol(fmtx(["",">9",],"Last : " , ndf9.df[0][5]),colleft=truetomato,colright=white,xpos = xpos + 62,false,{styleReverse}) 
        else :
                printLnBiCol(fmtx(["",">9",],"Last : " , ndf9.df[0][5]),colleft=skyblue,colright=white,xpos = xpos + 62,false,{styleReverse})                   

        showDf(ndf9,
            rows = 3,  #if there is a header we need 2 rows ,if there is no header and header is passed in 1 row 
                        #of course we can show more rows like here show last three dates 1 row is realtime if markets open
            cols =  toNimis(toSeq(1..ndf9.colcount)),                       
            colwd = ndf9.colwidths,
            colcolors = ndf9.colcolors,
            showFrame =  true,
            framecolor = blue,
            showHeader = true,
            headertext = ndf9.colheaders,
            leftalignflag = false,
            xpos = xpos) 
        decho(2)
        result = ndf9  

        
### Indicators
      
proc getavSMA*(stckcode:string,interval:string = "15min",timeperiod:string = "10",seriestype:string="close",apikey:string,xpos:int = 3,savequiet:bool = true,dfinfo:bool = false) =
    ## getavSMA
    ## fetches data from alphavantage 
    ## Note : first row is real time if markets are open
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## timeperiod : time_period=60, time_period=200  etc.
    ## seriestype : close, open, high, low
   
    var callavsma = ""
   
    if apikey == "demo":
      callavsma = "https://www.alphavantage.co/query?function=SMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
    else:
      callavsma = "https://www.alphavantage.co/query?function=SMA&symbol=$1&interval=$2&time_period=$3&series_type=$4&apikey=$5" % [stckcode,interval,timeperiod,seriestype,apikey]
  
    let avdata = getData22(callavsma)  # get the sma data
    
    try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)        
    except:
          currentline()
          printLnBiCol("Error : Could not write to  " & avtempdata ,colLeft=red)
          echo()
          doFinish()
          
    #showrawdata()
    #echo callavsma
    
    var indicator = "SMA"
    let jsonNode = parseJson(avdata)
    block jsonMeta:
        try:
            printLnBiCol("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            decho(1)
        except:
            printLnBiCol("[Error Message] : " & stckcode  & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos) 
            
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var smadate = newnimss()
        var sma = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            smadate.add(strip(x))
            sma.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfSma =  makeNimDf(smadate,sma,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
        ndfsma.colwidths  = @[17,10]
        ndfsma.colcolors  = @[violet,pastelgreen]
        ndfsma.colHeaders = @["Date",indicator]
        showDf(ndfSma,
            rows = 10,       
            cols =  @[1,2],                       
            colwd = ndfsma.colwidths,
            colcolors = ndfsma.colcolors,
            showFrame =  true,
            framecolor = skyblue,
            showHeader = true,
            headertext = ndfsma.colHeaders,  
            leftalignflag = false,
            xpos = xpos) 
        echo()
        if dfinfo == true:
            showDataframeInfo(ndfSma)
        if savequiet == true:    
            dfSave(ndfsma,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=true)   # save the df       
        else:
            dfSave(ndfsma,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=false)   # save the df  
      
            
proc getavWMA*(stckcode:string,interval:string = "15min",timeperiod:string = "10",seriestype:string="close",apikey:string,xpos:int = 3,savequiet:bool = true,dfinfo:bool = false) =
    ## getavWMA
    ## fetches data from alphavantage 
    ## Note : first row is real time if markets are open
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## timeperiod : time_period=60, time_period=200  etc.
    ## seriestype : close, open, high, low
   
    var callavwma = ""
   
    if apikey == "demo":
      callavwma = "https://www.alphavantage.co/query?function=WMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
    else:
      callavwma = "https://www.alphavantage.co/query?function=WMA&symbol=$1&interval=$2&time_period=$3&series_type=$4&apikey=$5" % [stckcode,interval,timeperiod,seriestype,apikey]
  
    let avdata = getData22(callavwma)  # get the wma data
    
    try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)        
    except:
          currentline()
          printLnBiCol("Error : Could not write to  " & avtempdata ,colLeft=red)
          echo()
          doFinish()
          
    #showrawdata()
    #echo callavwma
    
    var indicator = "WMA"
    let jsonNode = parseJson(avdata)
    block jsonMeta:
        try:
            printLnBiCol("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol("[Error Message] : " & stckcode  & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos) 
            
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var wmadate = newnimss()
        var wma = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            wmadate.add(strip(x))
            wma.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfWma =  makeNimDf(wmadate,wma,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
        ndfwma.colwidths  = @[17,10]
        ndfwma.colcolors  = @[violet,pastelgreen]
        ndfwma.colHeaders = @["Date",indicator]
        showDf(ndfWma,
            rows = 10,       
            cols =  @[1,2],                       
            colwd = ndfwma.colwidths,
            colcolors = ndfwma.colcolors,
            showFrame =  true,
            framecolor = skyblue,
            showHeader = true,
            headertext = ndfwma.colHeaders,  
            leftalignflag = false,
            xpos = xpos) 
        echo()
        if dfinfo == true:
            showDataframeInfo(ndfWma)
        if savequiet == true:    
            dfSave(ndfwma,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=true)   # save the df       
        else:
            dfSave(ndfwma,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=false)   # save the df  
 
 
proc getavEMA*(stckcode:string,interval:string = "15min",timeperiod:string = "10",seriestype:string="close",apikey:string,xpos:int = 3,savequiet:bool = true,dfinfo:bool = false) =
    ## getavEMA
    ## fetches data from alphavantage 
    ## Note : first row is real time if markets are open
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## timeperiod : time_period=60, time_period=200  etc.
    ## seriestype : close, open, high, low
   
    var callavema = ""
   
    if apikey == "demo":
      callavema = "https://www.alphavantage.co/query?function=EMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
    else:
      callavema = "https://www.alphavantage.co/query?function=EMA&symbol=$1&interval=$2&time_period=$3&series_type=$4&apikey=$5" % [stckcode,interval,timeperiod,seriestype,apikey]
  
    let avdata = getData22(callavema)  # get the ema data
    
    try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)        
    except:
          currentline()
          printLnBiCol("Error : Could not write to  " & avtempdata ,colLeft=red)
          echo()
          doFinish()
          
    #showrawdata()
    #echo callavema
    
    var indicator = "EMA"
    let jsonNode = parseJson(avdata)
    block jsonMeta:
        try:
            printLnBiCol("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol("[Error Message] : " & stckcode  & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos) 
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var emadate = newnimss()
        var ema = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            emadate.add(strip(x))
            ema.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfEma =  makeNimDf(emadate,ema,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
        ndfema.colwidths  = @[17,10]
        ndfema.colcolors  = @[violet,pastelgreen]
        ndfema.colHeaders = @["Date",indicator]
        showDf(ndfEma,
            rows = 10,       
            cols =  @[1,2],                       
            colwd = ndfema.colwidths,
            colcolors = ndfema.colcolors,
            showFrame =  true,
            framecolor = skyblue,
            showHeader = true,
            headertext = ndfema.colHeaders,  
            leftalignflag = false,
            xpos = xpos) 
        echo()
        if dfinfo == true:
            showDataframeInfo(ndfEma)
        if savequiet == true:    
            dfSave(ndfema,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=true)   # save the df       
        else:
            dfSave(ndfema,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=false)   # save the df     

 
proc getavRSI*(stckcode:string,interval:string = "15min",timeperiod:string = "10",seriestype:string="close",apikey:string,xpos:int = 3,savequiet:bool = true,dfinfo:bool = false) =
    ## getavRSI
    ## fetches data from alphavantage 
    ## Note : first row is real time if markets are open
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## timeperiod : time_period=60, time_period=200  etc.
    ## seriestype : close, open, high, low
   
    var callavrsi = ""
   
    if apikey == "demo":
      callavrsi = "https://www.alphavantage.co/query?function=RSI&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
    else:
      callavrsi = "https://www.alphavantage.co/query?function=RSI&symbol=$1&interval=$2&time_period=$3&series_type=$4&apikey=$5" % [stckcode,interval,timeperiod,seriestype,apikey]
  
    let avdata = getData22(callavrsi)  # get the rsi data
    
    try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)        
    except:
          currentline()
          printLnBiCol("Error : Could not write to  " & avtempdata ,colLeft=red)
          echo()
          doFinish()
          
    #showrawdata()
    #echo callavrsi
    
    var indicator = "RSI"
    let jsonNode = parseJson(avdata)
    block jsonMeta:
        try:
            printLnBiCol("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol("[Error Message] : " & stckcode  & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos) 
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var rsidate = newnimss()
        var rsi = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            rsidate.add(strip(x))
            rsi.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfRsi =  makeNimDf(rsidate,rsi,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
        ndfrsi.colwidths  = @[17,10]
        ndfrsi.colcolors  = @[violet,pastelgreen]
        ndfrsi.colHeaders = @["Date",indicator]
        showDf(ndfRsi,
            rows = 10,       
            cols =  @[1,2],                       
            colwd = ndfrsi.colwidths,
            colcolors = ndfrsi.colcolors,
            showFrame =  true,
            framecolor = skyblue,
            showHeader = true,
            headertext = ndfrsi.colHeaders,  
            leftalignflag = false,
            xpos = xpos) 
        echo()
        if dfinfo == true:
            showDataframeInfo(ndfRsi)
        if savequiet == true:    
            dfSave(ndfrsi,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=true)   # save the df       
        else:
            dfSave(ndfrsi,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=false)   # save the df     

 
proc getavWILLR*(stckcode:string,interval:string = "15min",timeperiod:string = "10",seriestype:string="close",apikey:string,xpos:int = 3,savequiet:bool = true,dfinfo:bool = false) =
    ## getavWILLR
    ## fetches data from alphavantage 
    ## Note : first row is real time if markets are open
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## timeperiod : time_period=60, time_period=200  etc.
    ## seriestype : close, open, high, low
   
    var callavwillr = ""
   
    if apikey == "demo":
      callavwillr = "https://www.alphavantage.co/query?function=WILLR&symbol=MSFT&interval=15min&time_period=10&apikey=demo"
    else:
      callavwillr = "https://www.alphavantage.co/query?function=WILLR&symbol=$1&interval=$2&time_period=$3&series_type=$4&apikey=$5" % [stckcode,interval,timeperiod,seriestype,apikey]
  
    let avdata = getData22(callavwillr)  # get the willr data
    
    try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)        
    except:
          currentline()
          printLnBiCol("Error : Could not write to  " & avtempdata ,colLeft=red)
          echo()
          doFinish()
          
    #showrawdata()
    #echo callavwillr
    
    var indicator = "WILLR"
    let jsonNode = parseJson(avdata)
    block jsonMeta:
        try:
            printLnBiCol("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol("[Error Message] : " & stckcode  & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos) 
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var willrdate = newnimss()
        var willr = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            willrdate.add(strip(x))
            willr.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfWillr =  makeNimDf(willrdate,willr,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
        ndfwillr.colwidths  = @[17,10]
        ndfwillr.colcolors  = @[violet,pastelgreen]
        ndfwillr.colHeaders = @["Date",indicator]
        showDf(ndfWillr,
            rows = 10,       
            cols =  @[1,2],                       
            colwd = ndfwillr.colwidths,
            colcolors = ndfwillr.colcolors,
            showFrame =  true,
            framecolor = skyblue,
            showHeader = true,
            headertext = ndfwillr.colHeaders,  
            leftalignflag = false,
            xpos = xpos) 
        echo()
        if dfinfo == true:
            showDataframeInfo(ndfWillr)
        if savequiet == true:    
            dfSave(ndfwillr,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=true)   # save the df       
        else:
            dfSave(ndfwillr,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=false)   # save the df     

            

proc getavBBANDS*(stckcode:string,interval:string = "15min",timeperiod:string = "10",seriestype:string="close",apikey:string,xpos:int = 3,savequiet:bool = true,dfinfo:bool = false) =
    ## getavBBANDS
    ## fetches data from alphavantage 
    ## Note : first row is real time if markets are open
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## timeperiod : time_period=60, time_period=200  etc.
    ## seriestype : close, open, high, low
    ## default params implemented here see  --->  https://www.alphavantage.co/documentation/
   
    var callavbbands = ""
   
    if apikey == "demo":
      callavbbands = "https://www.alphavantage.co/query?function=BBANDS&symbol=MSFT&interval=15min&time_period=10&apikey=demo"
    else:
      callavbbands = "https://www.alphavantage.co/query?function=BBANDS&symbol=$1&interval=$2&time_period=$3&series_type=$4&apikey=$5" % [stckcode,interval,timeperiod,seriestype,apikey]
  
    let avdata = getData22(callavbbands)  # get the bbands data
    
    try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)        
    except:
          currentline()
          printLnBiCol("Error : Could not write to  " & avtempdata ,colLeft=red)
          echo()
          doFinish()
          
    #showrawdata()
    #echo callavbbands
    
    var indicator = "BBANDS"
    let jsonNode = parseJson(avdata)
    block jsonMeta:
        try:
            printLnBiCol("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol("UpperBand : " & $jsonNode["Meta Data"]["6.1: Deviation multiplier for upper band"].getInt(),xpos = xpos) 
            printLnBiCol("LowerBand : " & $jsonNode["Meta Data"]["6.2: Deviation multiplier for lower band"].getInt(),xpos = xpos) 
            printLnBiCol("MA Type   : " & $jsonNode["Meta Data"]["6.3: MA Type"].getInt(),xpos = xpos) 
            printLnBiCol("SeriesType: " & jsonNode["Meta Data"]["7: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol("TimeZone  : " & jsonNode["Meta Data"]["8: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol("[Error Message] : " & stckcode  & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos)     
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var bbandsdate = newnimss()
        var bbandsupper  = newnimss()
        var bbandslower  = newnimss()
        var bbandsmiddle = newnimss()
        
        for x,y in pairs(z):        # load the future columns of the dataframe
            bbandsdate.add(strip(x))
            bbandsupper.add(strip(jsonNode[nsi][x]["Real Upper Band"].getStr())) 
            bbandslower.add(strip(jsonNode[nsi][x]["Real Lower Band"].getStr())) 
            bbandsmiddle.add(strip(jsonNode[nsi][x]["Real Middle Band"].getStr())) 
            
        var ndfBBands =  makeNimDf(bbandsdate,bbandsupper,bbandslower,bbandsmiddle,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
        ndfbbands.colwidths  = @[17,14,14,14]
        ndfbbands.colcolors  = @[violet,pastelgreen,pastelblue,pastelpink]
        ndfbbands.colHeaders = @["Date",indicator & "-upper",indicator & "-lower",indicator & "-middle"]
        showDf(ndfBBands,
            rows = 10,       
            cols =  @[1,2,3,4],                       
            colwd = ndfbbands.colwidths,
            colcolors = ndfbbands.colcolors,
            showFrame =  true,
            framecolor = skyblue,
            showHeader = true,
            headertext = ndfbbands.colHeaders,  
            leftalignflag = false,
            xpos = xpos) 
        echo()
        if dfinfo == true:
            showDataframeInfo(ndfBBands)
        if savequiet == true:    
            dfSave(ndfbbands,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=true)   # save the df       
        else:
            dfSave(ndfbbands,stckcode & "-" & indicator.toLowerAscii() & ".csv",quiet=false)   # save the df     

                   
            
            
            
### end indicators        
        
        
#var flag = 0
template metal(dc:int):typed =
    ## metal
    ## 
    ## utility template to display Kitco metal data
    ## 
    ## used by showKitcoMetal
    ## 
    
    if ktd[x].startswith(dl) == true:
      printLn(ktd[x] & "---",yellowgreen,xpos = xpos - 2 )
      
    elif find(ktd[x],"Asia / Europe") > 0:
       print(spaces(2) & strip(ktd[x],true,true),white,xpos = xpos)
       mflag = 1
       
    elif find(ktd[x],"New York") > 0:
       print(spaces(2) & strip(ktd[x],true,true),white,xpos = xpos)
       mflag = 2
       
    elif find(ktd[x],opn) > 0 :
        if mflag == 1:
           printLn(fmtx([">48"],"MARKET IS OPEN"),lime)
        elif mflag == 2:
           printLn(fmtx([">53"],"MARKET IS OPEN"),lime)
           
    elif find(ktd[x],cls) > 0:
        if mflag == 1:
          printLn(fmtx([">46"],"MARKET IS CLOSED"),red)
        elif mflag == 2:
          printLn(fmtx([">51"],"MARKET IS CLOSED"),red)
              
    elif find(ktd[x],"Update") > 0:
        print(spaces(3))
        printLnBicol(strip(ktd[x]) & " New York Time",colLeft=gray,colright=gray,sep="Last Update ",xpos = xpos + 1,false,{styleReverse})                    

    else:
           
          if dc < 36:
               try:
                 var ks = ktd[x].split(" ")
                 if ktd[x].contains("Metals") == true:
                    printLn(ktd[x],white,xpos = xpos - 1)
                 else: 
                    
                    kss = @[]
                    if ks.len > 0:
                      for x in 0..<ks.len:
                        if ks[x].len > 0:
                          kss.add(ks[x].strip(false,true))
                      if kss[0].startswith("Gold") or kss[0].startswith("Silver") or kss[0].startswith("Platinum") or kss[0].startswith("Palladium") == true:                    
                          if dc > 18 :
                                  
                                if parsefloat(kss[3]) > 0.00 :
                                    print(spaces(4) & uparrow,lime,xpos = 1)
                                elif  parsefloat(kss[3]) == 0.00:
                                    print(spaces(4) & leftrightarrow,dodgerblue,xpos = 1)
                                else:
                                    print(spaces(4) & downarrow,red,xpos = 1)                            
                                
                          else: 
                                if parsefloat(kss[3]) > 0.00 :
                                    print(spaces(4) & uparrow,lime,xpos = 1)
                                elif  parsefloat(kss[3]) == 0.00:
                                    print(spaces(4) & leftrightarrow,dodgerblue,xpos = 1)
                                else:
                                    print(spaces(4) & downarrow,red,xpos = 1)
                                
                                                         
                          printLn(fmtx(["<9",">11",">12",">10",">8",">10",">10"],kss[0],kss[1],kss[2],kss[3],kss[4],kss[5],kss[6]))                  
          
               except:
                  discard


proc showKitcoMetal*(xpos:int = 1) =
    ## showKitcoMetal
    ## 
    ## 
    ## get and display kitco metal prices
    ## 
    ## 
    ##  
    let dl  = "   ----------------------------------------------------------------------"
    let cls = "CLOSED"
    let opn = "OPEN" 
  
    var dc  = 0 # data counter
    var kss = newSeq[string]()
    #printLn("Gold,Silver,Platinum Spot price : New York and Asia / Europe ",peru,xpos = xpos)
    var kt = ""
    try:
            let zcli = newHttpClient()
            kt = zcli.getContent("http://www.kitco.com/texten/texten.html")

            var kts = splitlines(kt)
            var ktd = newSeq[string]()
                  
            var nymarket = false
            var asiaeuropemarket = false
              
            var addflag = false 
            for ktl in kts:
              
                if find(ktl,"File created on ") > 0:
                    addflag = false 
              
                if find(ktl,"New York") > 0:
                    addflag = true
                                  
                if addflag == true: 
                    ktd.add(ktl)
                  
          
            # now scan for closed metal markets
            var lc = 0
            for s in ktd:
                inc lc
                if find(s,cls) > 0:
                  if lc < 5:
                        nymarket = false
                  elif lc > 10:
                        asiaeuropemarket = false
                if find(s,opn) > 0:
                    if lc < 5:
                        nymarket = true
                    elif lc > 10:
                        asiaeuropemarket = true
        
            if nymarket == false and asiaeuropemarket == false:
                  printLn("All Metal Markets Closed or Data outdated/unavailable",truetomato,xpos = xpos + 2)
                  for x in 13.. 25 : 
                     dc = 6
                     metal(dc)   
                      
            elif nymarket == true and asiaeuropemarket == true:
                  # both open we show new york gold       
                  dc = 0
                  for x in 0.. ktd.len - 18: 
                    inc dc
                    metal(dc)                                       
          
            elif nymarket == true and asiaeuropemarket == false:
                # ny  open we show new york gold       
                  dc = 0
                  for x in 0..<ktd.len - 18: 
                    inc dc
                    metal(dc)                                                                     

            elif nymarket == false and asiaeuropemarket == true:
                  # asiaeuropemarket  open we show asiaeuropemarket gold       
                  dc = 0
                  for x in 13.. 25:  # <ktd.len:
                    inc dc
                    metal(dc)  
            else :
                  discard
                  
    except HttpRequestError:
          printLn("Kitco Data temporary unavailable : " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except ValueError:
          discard
    except OSError:
          discard
    except OverflowError:
          discard
    except  TimeoutError:
         printLn("TimeoutError : " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except  ProtocolError:
         printLn("Protocol Error : " & getCurrentExceptionMsg()  & " at : " & $getLocalTime(getTime()),truetomato,xpos = xpos)
    except :
         discard
    finally:
         discard         

# utility procs

proc presentValue*[T](FV: T,r:T,m:int,t:int):float =
     ## presentValue
     ##
     ## Present Value Calculation for a Lump Sum Investment
     ##
     ## Future Value (FV)
     ##   is the future value sum of an investment that you want to find a present value for
     ## Number of Periods (t)
     ##   commonly this will be number of years but periods can be any time unit.
     ##   Use int or floats for partial periods such as months for
     ##   example, 7.5 years is 7 yr 6 mo.
     ## Interest Rate (R)
     ##   is the annual nominal interest rate or "stated rate" in percent.
     ##   r = R/100, the interest rate in integer or floats
     ## Compounding (m)
     ##   is the number of times compounding occurs per period. If a period is a year
     ##   then annually=1, quarterly=4, monthly=12, daily = 365, etc.
     ## Rate (i)
     ##   i = (r/m); interest rate per compounding period.
     ## Total Number of Periods (n)
     ##   n = mt; is the total number of compounding periods for the life of the investment.
     ## Present Value (PV)
     ##   the calculated present value of your future value amount
     ##
     ## From http://www.CalculatorSoup.com - Online Calculator Resource.
     ##
     ## .. code-block:: nim
     ##    var FV : float = 10000
     ##    var PV : float = 0.0
     ##    var r  : float = 0.0625
     ##    var m  : int   = 2
     ##    var t  : int   = 12
     ##
     ##    PV = presentValue(FV,r,m,t)
     ##    echo PV
     ##


     var z = 1.0 + r.float / m.float
     var s = m.float * t.float
     result = FV / pow(z,s)


proc presentValue*(FV: float,r:float,m:float,t:float):float =
     ## presentValue
     ##
     ## Present Value Calculation for a Lump Sum Investment
     ##
     ## .. code-block:: nim
     ##      PV = presentValue(FV,0.0925,2.0,12.0)
     ##      echo PV

     var z = 1.0 + r / m
     var s = m * t
     result = FV / pow(z,s)


proc presentValueFV*(FV:float,i:float,n:int):float =
     ## presentValueFV
     ##
     ## the present value of a future sum at a periodic
     ## interest rate i where n is the number of periods in the future.
     ##
     ## .. code-block:: nim
     ##    PV = presentValueFV(FV,0.0625,10)
     ##    echo PV


     var zz = 1.0 + i
     result = FV / (pow(zz,n.float))


proc presentValueFV*(FV:float,i:float,n:float):float =

     ## .. code-block:: nim
     ##    PV = presentValueFV(FV,0.0625,20.5)
     ##    echo PV

     var zz = 1.0 + i
     result = FV / (pow(zz,n.float))         
         
         
#------------------------------------------------------------------------------------------
# End of nimFinLib
#------------------------------------------------------------------------------------------
