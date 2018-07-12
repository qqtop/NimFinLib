
##::
##
## Program     : nimFinLib
##
## Status      : Development    
##
## License     : MIT opensource
##
## Version     : 0.3.0.1
##
## Compiler    : nim 0.18.x  dev branch
##
##
## Description : A basic library for financial data display and calculations 
## 
##               using data from Alpha Vantage API
##
##               Currency , Stock and Index 
##
##               Kitco Metal Prices  
##
##               Dataframe like objects for easy working with current and historical data 
##
##               EMA,SMA,WMA,RSI,WILLR,BBANDS Indicator   #  may not yet be available for all stocks/markets
##
##               Returns calculations
##
##               Data display procs 
##               
##               Simple plotting available via gnuplot
##               
##               Dataframe save/reload complete with display parameters
##
##               Dataframe rotation  
##               
##               Portfolio management ( Random portfolio , User portfolio )
##                            
##               
## Project     :  https://github.com/qqtop/NimFinLib
##
## Tested on   :  Linux
##
## ProjectStart: 2015-06-05 
## 
## Latest      : 2018-07-17
##     
## Todo        : anything not yet done
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
## Notes       :
## 
##               nimFinlib is being developed utilizing nimcx.nim module and nimdataframe.nim
##
##               to improve coloring of data and positioning of output.
## 
##
## Funding     :     Here are the options :
##     
##                   You are happy             ==> send BTC to : 194KWgEcRXHGW5YzH1nGqN75WbfzTs92Xk
##                   
##                   You are not happy         ==> send BTC to : 194KWgEcRXHGW5YzH1nGqN75WbfzTs92Xk
##                 
##                   You wish to donate        ==> send BTC to : 194KWgEcRXHGW5YzH1nGqN75WbfzTs92Xk
##                                       
##                   You do not wish to donate ==> send BTC to : 194KWgEcRXHGW5YzH1nGqN75WbfzTs92Xk
##                                

import os,nimcx,nimdataframe,parseutils,net,tables,parsecsv,algorithm,math,unicode,stats     
import nre except toSeq
import av_utils
export av_utils

let NIMFINLIBVERSION* = "0.3.0.1"   

# temporary holding place for data fetched from alphavantage , change directory as required by your setup below
var avtempdata* = "/dev/shm/avdata.csv"    

const
      tail* = "tail"
      head* = "head"
      all*  = "all"  

type

  Portfolio* {.inheritable.} = object
        ## Portfolio type
        ## 
        ## holds one portfolio with all relevant historic stocks data
        ## 
        pfname* : string       ## nx  holds portfolio name  e.g. MyGetRichPortfolio
        pfdata* : seq[Stocks]  ## dx  holds all stocks with historical data


  Account*  = object
        ## Account type
        ## 
        ## holds all portfolios similar to a master account
        ## 
        ## portfolios are Portfolio objects
        ## 
        apf* : seq[Portfolio]  ## pf holds all Portfolio type portfolios for an account

  
  Stocks* {.inheritable.} = object of Portfolio
        ## Stocks type
        ## 
        ## holds individual stocks history data and RunningStat for ohlcva columns
        ## 
        ## even more items may be added like full company name etc in the future
        ## 
        ## items are stock code, ohlcva, rc and rca .
        ## 
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
          
proc getData22*(url:string,timeout:int = 20000):auto =
  ## getData
  ## 
  ## 
  ## 
  var zclitiming = epochTime()
  var mytimeout = timeout
  try:
       var zcli = newHttpClient(timeout = mytimeout)  # 20 secs
       result = zcli.getcontent(url)   # orig test data
       
  except :
       currentLine()
       printLnErrorMsg(url & " ") 
       printLnBErrorMsg("Content could not be fetched at this time. Try later.")
       printLnErrorMsg(getCurrentExceptionMsg())
       printLnInfoMsg("Timeout", "default = $1 secs" % ff2(mytimeout div 1000,2))
       printLnInfoMsg("Timing ", ff2(epochTime() - zclitiming,2))
       decho(2)
       discard()
      
proc avDatafetcher*(stckcode:string,mode:string = "compact",apikey:string):bool =
   ## avDatafetcher
   ## 
   ## fetches data from alphavantage 
   ## 
   ## default = compact   will fetch abt 100 records if available
   ## 
   ## option  = full      all available records
   ## 
   ## Note : first row is real time if markets are open
   ## 
   ## data will be written into /dev/shm/avdata.csv  .. 
   ## 
   ## /dev/shm temporary filesystem location may not be available on every distribution
   ## 
   ## change accordingly or write to a disc location
   ## 
   ## this is the best data fetcher for worldwide markets as of 2018-01 others may work too
   ## 
   ## but currently seem more US focused. it returns av_daily_adjusted_csv
   ## 
   result = true
   var callav = ""
   
   if apikey == "demo":
       callav = av_daily_adjusted_csv  
       #callav = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=MSFT&apikey=demo&datatype=csv"
   
   elif toLowerAscii(mode) == "compact":
       #callav = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=$1&outputsize=compact&apikey=$2&datatype=csv" % [stckcode,apikey]
       callav = getcallavda(stckcode,apikey)   # calling the proc in av_utils
   elif toLowerAscii(mode) == "full":
       #callav = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=$1&outputsize=full&apikey=$2&datatype=csv" % [stckcode,apikey]
       callav = getcallavdafull(stckcode,apikey)
       
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
          printLnErrorMsg("Could not write to  " & avtempdata)
          echo()
          doFinish()

         
proc avDataFetcherIntraday*(stckcode:string,mode:string = "compact",apikey:string):bool =
   ## avDataFetcherIntraday
   ## 
   ## fetches data from alphavantage 
   ## 
   ## default = compact   abt 100 records if available
   ## 
   ## option  = full      all available records
   ## 
   ## Note : first row is real time if markets are open
   ## 
   ## data will be written into /dev/shm/avdata.csv  .. 
   ## 
   ## /dev/shm temporary filesystem location may not be available on every distribution
   ## 
   ## change accordingly or write to a disc location
   ## 
   ## works occassionally with non US stocks but mostly not ...
   ## 
   result = true
   var callav = ""
   
   if apikey == "demo":
       callav = av_intraday_1m_csv  
       #callav = "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=MSFT&interval=1min&apikey=demo&datatype=csv"
                 
   elif toLowerAscii(mode) == "compact":
       callav = "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$1&interval=1min&outputsize=compact&apikey=$2&datatype=csv" % [stckcode,apikey]
   elif toLowerAscii(mode) == "full":
       callav = "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$1&interval=1min&outputsize=full&apikey=$2&datatype=csv" % [stckcode,apikey]
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
     printLnInfoMsg("Info","End of RawData")
        
proc showOriginalStockDf*(stckcode:string,xpos:int = 3,rows:int = 3,header:bool = false,apikey:string = "demo"):nimdf {.discardable.} =
   ## showOriginalStockData 
   ## 
   ## using TIME_SERIES_INTRADAY 1 min  DATA   # this will be selectable in the future in respect of time_series and interval
   ## 
   ## first data row maybe realtime if markets online , we always fetch fresh data 
   ## 
   var okflag = true
   if not avDatafetcherIntraday(stckcode,"compact",apikey): doFinish()
   else:
          withFile(txt2,avtempdata, fmRead):
              var line = ""
              while txt2.readLine(line):
                 if line.contains("Invalid API call.") == true:
                    printLnBiCol("[AV  Error Message] : Invalid API call. Please retry or visit the documentation for TIME_SERIES_INTRADAY.", colLeft = red,xpos = 3)
                    printLnBiCol("[NIMFINLIB Message] : Data currently not available for : " & stckcode, colLeft = red,xpos = 3)
                    okflag = false
              
   if okflag == true:    
      
        var ndf1 = createDataFrame(avtempdata,cols = 7,hasHeader = true) 
        ndf1.colwidths = @[20,10,10,10,10,11]      # change the default columnwidths created in dfDefaultSetup
        
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
        ndf1.status = true
        result = ndf1
   else:
        # we create a dummy dataframe to pass the status out of the proc
        var ndf1 = newNimDf()
        ndf1.status = false
        result = ndf1
        
        
proc showStocksDf*(stckcode: string,
                   rows    : int = 3,
                   xpos    : int = 3,
                   header  : bool = false,
                   mode    : string = "compact",   # indicating mode for api call compact , full 
                   infodf  : bool = true,          # show a current details dataframe
                   apikey  : string = "demo") : nimdf {.discardable.} =
     ## showStocksDf
     ## 
     ## a display routine with some more information
     ## 
     ## data is freshly downloaded
     ## 
     var okflag = true
     var ct  = newCxtimer("fetchTimer1") 
     ct.startTimer
     if not avDatafetcher(stckcode,mode,apikey): 
       ct.stopTimer
       okflag = false
     
     else:  
        # data has been fetched ok
        ct.stopTimer
        #saveTimerResults(ct) 
        
        withFile(txt2,avtempdata, fmRead):
              var line = ""
              while txt2.readLine(line):
                 if line.contains("Invalid API call.") == true:
                    decho(2)
                    printLnBiCol("[Error            ] : Request may have timed out . Try again later.", colleft = red ,xpos = 3)
                    printLnBiCol("[AV  Error Message] : Invalid API call. Please retry or visit the documentation for TIME_SERIES_INTRADAY.", colLeft = red,xpos = 3)
                    printLnBiCol("[NIMFINLIB Message] : Data currently not available for : " & stckcode, colLeft = red,xpos = 3)
                    okflag = false
                    
                    
     if okflag == true:    
        
        var ndf9 = createDataFrame(avtempdata,cols = 7,hasHeader = true)
        
        # here we start to add a new column not found in ndf9 (the original data received)
        # we want it to be the first col of our df and in all rows has the stock code stckcode passed in above
        # the way to do this is 
        var mynewcol:nimss = @[]
        for x in 0..<ndf9.rowcount-1: mynewcol.add(stckcode) 
        # obviously we could add any old thing but for now we want stckcode
        # now just lets make a new df with mynewcol as first col and all other cols from ndf9 df
        # makeNimDf forgets the header from ndf9 hence we pass in a new header for our cols
        
        ndf9 = makeNimDf(mynewcol,getColData(ndf9,1),getColData(ndf9,2),getColData(ndf9,3),getColData(ndf9,4),
                            getColData(ndf9,5),getColData(ndf9,6),getColData(ndf9,7),status = true,hasHeader=true)
        #dfsave(ndf9,"ndf9.csv")  # used in debugging for checking what we get here
        ndf9.colwidths = @[12,14,10,10,10,10,10,11]         # change the default columnwidths created in dfDefaultSetup
        # how to access a certain value from the df lets get  row 1 col 1
        #echo parsefloat(ndf9.df[0][1])
        #echo parsefloat(ndf9.df[0][4])
        
        # calc the percentage change from last day close to current real time close
        var yday  = parsefloat(ndf9.df[1][5])   # last close
        var tdayo = parseFloat(ndf9.df[0][2])   # current open
        var tdayh = parseFloat(ndf9.df[0][3])   # current high
        var tdayl = parseFloat(ndf9.df[0][4])   # current low
        var tday  = parseFloat(ndf9.df[0][5])   # current close
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
        
        
        if stckcode.startswith("^") == true:
            printBiCol(fmtx(["",">11",],"Index:" , stckcode),colleft=darkturquoise,colright=lightgrey,sep=":",xpos = xpos + 1,false,{styleReverse})
        else:
            printBiCol(fmtx(["",">11",],"Code :" , stckcode),colleft=lightcoral,colright=lightgrey,sep=":",xpos = xpos + 1,false,{styleReverse})
        
        if pctchange > 0.0:
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colright=white,sep="%",xpos = xpos + 20,false,{styleReverse})
        elif pctchange < 0.0:
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colleft=truetomato,colright=white,sep="%",xpos = xpos + 20,false,{styleReverse}) 
        else :
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colleft=skyblue,colright=white,sep="%",xpos = xpos + 20,false,{styleReverse})            
        
        if actchange > 0.0:
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colright=white,xpos = xpos + 40,false,{styleReverse})
        elif pctchange < 0.0:
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colleft=truetomato,colright=white,xpos = xpos + 40,false,{styleReverse}) 
        else :
                printBiCol(fmtx(["",">9"],"Change : ",ff(actchange,6)),colleft=skyblue,colright=white,xpos = xpos + 40,false,{styleReverse})     
        

        if pctchange > 0.0:
                printBiCol(fmtx(["","<9"],"Last  : " , ndf9.df[0][5]),colright=white,xpos = xpos + 60,false,{styleReverse})
        elif pctchange < 0.0:
                printBiCol(fmtx(["","<9"],"Last  : " , ndf9.df[0][5]),colleft=truetomato,colright=white,xpos = xpos + 60,false,{styleReverse}) 
        else :
                printBiCol(fmtx(["","<9"],"Last  : " , ndf9.df[0][5]),colleft=skyblue,colright=white,xpos = xpos + 60,false,{styleReverse})     
        
        printLnBiCol("Timing: " & $ff(ct.duration,4) & " sec",colleft=lightslategray,colright=pastelwhite,xpos = xpos + 79,false,{styleReverse})
        
        if pctchange > 0.0:
           printBiCol("State: " & uparrow,colleft=lightsteelblue,colright=lime,xpos = xpos + 1,false,{styleReverse})
        elif pctchange < 0.0:
           printBiCol("State: " & downarrow,colleft=lightsteelblue,colright=red,xpos = xpos + 1,false,{styleReverse})
        else:
           printBiCol("State: " & lrarrow,colleft=lightsteelblue,colright=skyblue,xpos = xpos + 1,false,{styleReverse})
        
        # we check if date and and date of first row and our time == same , to indicate old data displayed
        if strip(ndf9.df[0][1],true,true) == strip(cxtoday(),true,true) :
              printBiCol("Age: New",colleft=lightsteelblue,colright=yellowgreen,xpos = xpos + 10,false,{styleReverse})
        else:
              printBiCol("Age: Old",colleft=lightsteelblue,colright=red,xpos = xpos + 10,false,{styleReverse})
        
        
        printBiCol("Time   : " & ($now()).replace("T"," ") & spaces(4),colleft=lightsteelblue,colright=pastelwhite,xpos = xpos + 20,false,{styleReverse})

        var dayrange = ff(tdayl,4) & " - " & ff(tdayh,4) 
        printLnBiCol(fmtx(["","<$1" % [$29]],"Range : " , dayrange),colleft=aquamarine,colright=pastelwhite,xpos = xpos + 60,false,{styleReverse})                   
        
        if infodf == true :  # also show the dataframe
          showDf(ndf9,
            rows = rows,  #if there is a header we need 2 rows ,if there is no header and header is passed in 1 row 
                          #of course we can show more rows like here show last three dates 1 row is realtime if markets open
            cols =  toNimis(toSeq(1..ndf9.colcount)),                       
            colwd = ndf9.colwidths,
            colcolors = ndf9.colcolors,
            showFrame =  true,
            framecolor = aqua,
            showHeader = true,
            headertext = ndf9.colheaders,
            leftalignflag = false,
            xpos = xpos)
            
        decho(2)
        result = ndf9
     else:
        # we create a dummy dataframe to pass the status out of the proc
        var ndf9 = newNimDf()
        ndf9.status = false
        result = ndf9   
  
proc showLocalStocksDf*(ndf9:nimdf,xpos:int = 3):nimdf {.discardable.} =
        ## showLocalStocksDf
        ## 
        ## used to display a df which already exists or has been loaded via dfLoad
        ## 
        ## with all parameters pre specified
        ## 
        ## 

        # calc the percentage change from last day close to current real time close
        var yday  = parsefloat(ndf9.df[1][5])   # last close   yday =  ndf9.df[1][5].map(parseFloat)
        var tdayo = parseFloat(ndf9.df[0][2])  # current open
        var tdayh = parseFloat(ndf9.df[0][3])   # current high
        var tdayl = parseFloat(ndf9.df[0][4])   # current low
        var tday  = parseFloat(ndf9.df[0][5])   # current close
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
                printBiCol(fmtx(["",">9"],"Change % ",ff(pctchange,5)),colright=white,sep="%",xpos = xpos + 22,false,{styleReverse})
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
                printLnBiCol(fmtx(["",">9"],"Last : " , ndf9.df[0][5]),colright=white,xpos = xpos + 62,false,{styleReverse})
        elif pctchange < 0.0:
                printLnBiCol(fmtx(["",">9"],"Last : " , ndf9.df[0][5]),colleft=truetomato,colright=white,xpos = xpos + 62,false,{styleReverse}) 
        else :
                printLnBiCol(fmtx(["",">9"],"Last : " , ndf9.df[0][5]),colleft=skyblue,colright=white,xpos = xpos + 62,false,{styleReverse})                   

                              
        printLnBiCol(fmtx(["","<$1" % [$29]],"Range : " , ff(tdayl,4) & " - " & ff(tdayh,4)),colleft=skyblue,colright=white,xpos = xpos + 82,false,{styleReverse})                   
          
         
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
    ## 
    ## fetches data from alphavantage 
    ## 
    ## Note : first row is real time if markets are open
    ## 
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## 
    ## timeperiod : time_period=60, time_period=200  etc.
    ## 
    ## seriestype : close, open, high, low
    ## 
   
    var callavsma = ""
   
    if apikey == "demo":
      callavsma = av_sma 
      #callavsma = "https://www.alphavantage.co/query?function=SMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
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
            printLnBiCol2("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol2("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol2("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol2("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol2("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol2("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol2("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            decho(1)
        except:
            printLnBiCol("[Error Message] : " & stckcode & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
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

        var ndfSma =  makeNimDf(smadate,sma,status = true,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
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
    ## 
    ## fetches data from alphavantage 
    ## 
    ## Note : first row is real time if markets are open
    ## 
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## 
    ## timeperiod : time_period=60, time_period=200  etc.
    ## 
    ## seriestype : close, open, high, low
    ## 
   
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
            printLnBiCol2("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol2("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol2("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol2("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol2("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol2("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol2("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol("[Error Message] : " & stckcode & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
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

        var ndfWma =  makeNimDf(wmadate,wma,status = true,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
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
    ## 
    ## fetches data from alphavantage 
    ## 
    ## Note : first row is real time if markets are open
    ## 
    ## interval   : 1min, 5min, 15min, 30min, 60min, daily, weekly, monthly
    ## 
    ## timeperiod : time_period=60, time_period=200  etc.
    ## 
    ## seriestype : close, open, high, low
    ## 
   
    var callavema = ""
   
    if apikey == "demo":
      callavema = av_ema 
      #callavema = "https://www.alphavantage.co/query?function=EMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
    else:
      callavema = "https://www.alphavantage.co/query?function=EMA&symbol=$1&interval=$2&time_period=$3&series_type=$4&apikey=$5" % [stckcode,interval,timeperiod,seriestype,apikey]
  
    let avdata = getData22(callavema)  # get the ema data
    
    try:
          withFile(txt2,avtempdata, fmWrite):
              txt2.write(avdata)        
    except:
          currentline()
          printLnErrorMsg("Could not write to  " & avtempdata)
          echo()
          doFinish()
          
    #showrawdata()
    #echo callavema
    
    var indicator = "EMA"
    let jsonNode = parseJson(avdata)
    block jsonMeta:
        try:
            printLnBiCol2("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol2("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol2("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol2("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol2("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol2("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol2("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnErrorMsg(stckcode & " - " & indicator & " data unavailable",xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnErrorMsg("Invalid API call. No valid json data returned.",xpos = xpos) 
            else:    
                printLnErrorMsg(jerror,xpos = xpos)
            printLnInfoMsg("Indicator data for some stocks / markets may not be available",xpos = xpos) 
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var emadate = newnimss()
        var ema = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            emadate.add(strip(x))
            ema.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfEma =  makeNimDf(emadate,ema,status = true,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
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
            printLnBiCol2("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol2("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol2("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol2("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol2("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol2("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol2("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol2("[Error Message] : " & stckcode & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol2("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol2(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol2("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos) 
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var rsidate = newnimss()
        var rsi = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            rsidate.add(strip(x))
            rsi.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfRsi =  makeNimDf(rsidate,rsi,status = true,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
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
    ## getavWILLR("MSFT","15min","10","close",apikey = apikey, 3, true, false) 
    
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
            printLnBiCol2("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol2("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol2("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol2("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol2("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol2("SeriesType: " & jsonNode["Meta Data"]["6: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol2("TimeZone  : " & jsonNode["Meta Data"]["7: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol2("[Error Message] : " & stckcode & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol2("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol2(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos) 
            break jsonMeta
        
        var nsi = "Technical Analysis: $1" % indicator
        var z = jsonNode[nsi]
        var willrdate = newnimss()
        var willr = newnimss()
        for x,y in pairs(z):        # load the future columns of the dataframe
            willrdate.add(strip(x))
            willr.add(strip(jsonNode[nsi][x][indicator].getStr())) 

        var ndfWillr =  makeNimDf(willrdate,willr,status = true,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
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
            printLnBiCol2("Code      : " & jsonNode["Meta Data"]["1: Symbol"].getStr(),xpos = xpos)      
            printLnBiCol2("Indicator : " & jsonNode["Meta Data"]["2: Indicator"].getStr(),xpos = xpos) 
            printLnBiCol2("Last      : " & jsonNode["Meta Data"]["3: Last Refreshed"].getStr(),xpos = xpos) 
            printLnBiCol2("Interval  : " & jsonNode["Meta Data"]["4: Interval"].getStr(),xpos = xpos) 
            printLnBiCol2("TimePeriod: " & $jsonNode["Meta Data"]["5: Time Period"].getInt(),xpos = xpos) 
            printLnBiCol2("UpperBand : " & $jsonNode["Meta Data"]["6.1: Deviation multiplier for upper band"].getInt(),xpos = xpos) 
            printLnBiCol2("LowerBand : " & $jsonNode["Meta Data"]["6.2: Deviation multiplier for lower band"].getInt(),xpos = xpos) 
            printLnBiCol2("MA Type   : " & $jsonNode["Meta Data"]["6.3: MA Type"].getInt(),xpos = xpos) 
            printLnBiCol2("SeriesType: " & jsonNode["Meta Data"]["7: Series Type"].getStr(),xpos = xpos) 
            printLnBiCol2("TimeZone  : " & jsonNode["Meta Data"]["8: Time Zone"].getStr(),xpos = xpos) 
            echo()
        except: 
            printLnBiCol("[Error Message] : " & stckcode & " - " & indicator & " data unavailable",colLeft=red,xpos = xpos)
            var jerror = jsonNode["Error Message"].getStr()
            if jerror.len + xpos > tw - 5:
                printLnBiCol2("Invalid API call. No valid json data returned.",colLeft = red,sep = "Invalid API call.",xpos = xpos) 
            else:    
                printLnBiCol2(jerror,colLeft = red,sep = "Invalid API call.",xpos = xpos)
            printLnBiCol2("[Note]          : Indicator data for some stocks / markets may not be available",colLeft=peru,xpos = xpos)     
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
            
        var ndfBBands =  makeNimDf(bbandsdate,bbandsupper,bbandslower,bbandsmiddle,status = true,hasHeader = true)  # tell makeNimDf that we will have a header , which will be passed in
        
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
template metal(dc:int,xpos:int):typed =
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
                                    print(spaces(4) & uparrow,lime,xpos = xpos - 3)
                                elif parsefloat(kss[3]) == 0.00:
                                    print(spaces(4) & leftrightarrow,dodgerblue,xpos = xpos - 3)
                                else:
                                    print(spaces(4) & downarrow,red,xpos = xpos - 3)                            
                                
                          else: 
                                if parsefloat(kss[3]) > 0.00 :
                                    print(spaces(4) & uparrow,lime,xpos = xpos - 3)
                                elif parsefloat(kss[3]) == 0.00:
                                    print(spaces(4) & leftrightarrow,dodgerblue,xpos = xpos - 3)
                                else:
                                    print(spaces(4) & downarrow,red,xpos = xpos - 3)
                                
                                                         
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
    # printLn("Gold,Silver,Platinum Spot price : New York and Asia / Europe ",peru,xpos = xpos)
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
                     metal(dc,xpos)   
                      
            elif nymarket == true and asiaeuropemarket == true:
                  # both open we show new york gold       
                  dc = 0
                  for x in 0.. ktd.len - 18: 
                    inc dc
                    metal(dc,xpos = xpos)                                       
          
            elif nymarket == true and asiaeuropemarket == false:
                # ny  open we show new york gold       
                  dc = 0
                  for x in 0..<ktd.len - 18: 
                    inc dc
                    metal(dc,xpos)                                                                     

            elif nymarket == false and asiaeuropemarket == true:
                  # asiaeuropemarket  open we show asiaeuropemarket gold       
                  dc = 0
                  for x in 13.. 25:  # <ktd.len:
                    inc dc
                    metal(dc,xpos)  
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
         printLn("Protocol Error : " & getCurrentExceptionMsg() & " at : " & $now(),truetomato,xpos = xpos)
    except :
         discard
    finally:
         discard         

# utility procs and indicators

# experimental

# since indicators from the Alpha vantage API work sometimes , but not always
# some handrolled indicators are provided here some may come from this python repo
# https://github.com/kylejusticemagnuson/pyti/tree/master/pyti

proc williams_percent_r*(close_data:seq[float]):seq[float] =

    #     """
    #     Williams %R.
    #     Formula:
    #     wr = (HighestHigh - close / HighestHigh - LowestLow) * -100
    #     """
    result = newSeq[float]()
    var highest_high = max(close_data)
    var lowest_low   = min(close_data)
    for close in close_data:
       result.add ((highest_high - close) / (highest_high - lowest_low)) * -100.0 

proc dailyReturns*(self:seq[string]):nimss =
    ## dailyReturns
    ##
    ## daily returns calculation gives same results as dailyReturns in R / quantmod
    ##
    var k = 1
    var lgx = newSeq[string]()
    for z in 1+k..<self.len:
        var lga = (1-(parseFloat(self[z]) / parseFloat(self[z-k])))
        lgx.add(ff(lga,5))   # this will give us returns with 5 dec pplplaces for display
    result = tonimss(lgx)



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
