
##::
##
## Program     : nimFinLib
##
## Status      : Alpha   - Development Rewrite for Alpha Vantage API   
##
## License     : MIT opensource
##
## Version     : 0.3.0.0
##
## Compiler    : nim 0.17+  dev branch
##
##
## Description : A basic library for financial calculations with Nim
##
##               Currency , Stock and Index Data from Alpha Vantage
##
##               Kitco Metal Prices  
##
##
##               Dataframe like objects for easy working with historical data and dataseries
##
##               Returns calculations
##
##               Ema calculation
##
##               Date manipulations
##
##               Data display procs
##
##               
## Project     :  https://github.com/qqtop/NimFinLib
##
## Tested on   :  Linux
##
## ProjectStart: 2015-06-05 
## 
## Latest      : 2017-11-24
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
## Funding     : If you are happy send any amount of bitcoins you like to a nice wallet :
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
   ## first line maybe realtime if markets online
   ## here we always fetch fresh data
   ## 
   if not avDatafectcher(stckcode,"compact",apikey): doFinish()
   else:    
      
        var ndf1 = createDataFrame(avtempdata,cols = 7,hasHeader = true) 
        ndf1.colwidths = @[8,13,10,10,10,10,10,11]         # change the default columnwidths created in dfDefaultSetup
        
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
        if   yday < tday == true: ndf1.colcolors = @[lightgrey,pastelgreen,pastelpink,lightblue,goldenrod,lime,lime,white]  
        elif yday > tday == true: ndf1.colcolors = @[lightgrey,pastelgreen,pastelpink,lightblue,goldenrod,truetomato,truetomato,white]
        else:  ndf1.colcolors = @[lightgrey,pastelgreen,pastelpink,dodgerblue,gold,skyblue,skyblue,white]
        ndf1.colheaders = @["code","timestamp","open", "high", "low", "close","adjclose" ,"volume"]
        
        echo("Original data ndf1 " & stckcode)
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
            xpos = 3) 
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
            xpos = 3) 
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
            xpos = 3) 
        decho(2)
        result = ndf9  
 
  
#------------------------------------------------------------------------------------------
# End of nimFinLib
#------------------------------------------------------------------------------------------
