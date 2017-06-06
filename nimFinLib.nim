
##::
##
## Program     : nimFinLib
##
## Status      : Development
##
## License     : MIT opensource
##
## Version     : 0.2.8.5
##
## Compiler    : nim 0.17+  dev branch
##
##
## Description : A basic library for financial calculations with Nim
##
##               Yahoo historical stock data    
##
##               Yahoo additional stock data    
##
##               Yahoo current stock quotes           
##
##               Yahoo forex rates        
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
## Latest      : 2017-06-05
##
## ToDo        : NOTE : Due to changes in Yahoo endpoints data quality may be impacted
##                      Some data has holes and adj.close seems not to be correct for splits or dividends
##                      in some cases so all data has to be taken with a grain of salt .. or whatever.
##                      Yahoo being sold to Verizon so expect hick-ups ...
## 
##                      getsymbol2 fetching hisorical data has been fixed as of 2017-06-03
##                      and is currently working.
## 
##               Ratios , Covariance , Correlation , Plotting advanced functions etc.
##               
##
## Programming : qqTop
##
## Contributors: reactorMonk
##
## Installation:
##
##
##               nimble install nimcx
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
##               nimFinlib is being developed utilizing cx.nim module
##
##               to improve coloring of data and positioning of output.
##
##               Terminals tested : bash,xterm,st.
##
##               strfmt  is now optional , a simple fmtengine was implemented in cx.nim
##               
##               as strfmt is often broken due to changes in the evolving compiler
##               
##               of course if it works again you also can use strfmt library
##               
##               and all/most documentation samples shown use it.
##               
##               nfT50 and nfT52 samples have been changed to the fmtengine
##               
##               see cx.nim proc fmtx  .
##
##               It is assumed that terminal color is black background
##
##               and white text. Other color schemes may not show all output.
##               
##               also read notes about terminal compability in cx.nim
##               
##               Best results with terminals supporting truecolor.
##                
##               It is also expected that you have unicode libraries installed
##               
##               if you see some unexpected chars then this libraries may be missing
##               

##
## Tests       : 
## 
##               For comprehensive tests and example usage see examples and
## 
##               nfT50.nim      - passed ok 2017-06-06
##               
##               nfT52.nim      - passed ok 2017-06-06
##               
##               minifin.nim    - ok
## 
##
##

import

       os,cx,strutils,parseutils,sequtils,httpclient,net,
       terminal,times,tables, parsecsv,streams,
       algorithm,math,unicode,stats,unicode
       
import nre except toSeq

let NIMFINLIBVERSION* = "0.2.8.5"

let yahoourl*    = "http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm"
let yahoocururl* = "https://finance.yahoo.com/webservice/v1/symbols/allcurrencies/quote?format=json"


const
      tail* = "tail"
      head* = "head"
      all*  = "all"  

type
  

  Portfolio* {.inheritable.} = object
        ## Portfolio type
        ## holds one portfolio with all relevant historic stocks data
        nx* : string   ## nx  holds portfolio name  e.g. MyGetRichPortfolio
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
        stock* : string            ## yahoo style stock code
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

  
  Stockdata*  {.inheritable.} = object
        ## Stockdata type
        ## holds additional stock data and statistics as currently available from yahoo
        ##
        price*            : float
        change*           : float
        volume*           : float
        avgdailyvol*      : float
        market*           : string
        marketcap*        : string
        bookvalue*        : float
        ebitda*           : string
        dividendpershare* : float
        dividendperyield* : float
        earningspershare* : float
        week52high*       : float
        week52low*        : float
        movingavg50day*   : float
        movingavg200day*  : float
        priceearingratio* : float
        priceearninggrowthratio* : float
        pricesalesratio*  : float
        pricebookratio*   : float
        shortratio*       : float


  
  Ts* {.inheritable.} = object
       ## Ts type
       ## is a simple timeseries object which can hold one
       ## column of any OHLCVA data and corresponding dates

       dd* : seq[string]  # date
       tx* : seq[float]   # data

  
  Currencies* {.inheritable.} = object
       ## Currencies type
       ## a simple object to hold current currency data

       cu* : seq[string]  # currency code pair e.g. EURUSD
       ra* : seq[float]   # relevant rate  e.g 1.354


 
  YHobject* {.inheritable.} = object
        ## YHobject type
        ## a simple object to hold certain yahoo stock data 
        ## 
        ## 
        stcode*   : string
        stname*   : string
        stmarket* : string
        stprice*  : string
        stchange* : string
        stopen*   : string
        sthigh*   : string
        stvolume* : string
        strange*  : string
        stdate*   : string
        sttime*   : string

        
var supererrorflag = false        
        
proc initTs*():Ts=
     ## initTs
     ##
     ## init a timeseries object
     var ats : Ts
     ats.dd = @[]
     ats.tx = @[]
     result = ats
     
     
     

proc timeSeries*[T](self:T,ty:string): Ts =
     ## timeseries
     ## returns a Ts type date and one data column based on ty selection
     ## input usually is a Stocks object and a string , if a string is in ohlcva
     ## the relevant series will be extracted from the Stocks object
     ##
     ## usage exmple :
     ##
     ## .. code-block:: nim
     ##
     ##    timeseries(myStocksObject,"o")
     ##
     ##
     ## this would return dates in dd and open prices in ts
     ##
     var ts:Ts
     ts.dd = self.date
     case ty
     of "o": ts.tx = self.open
     of "h": ts.tx = self.high
     of "l": ts.tx = self.low
     of "c": ts.tx = self.close
     of "v": ts.tx = self.vol
     of "a": ts.tx = self.adjc
     else  : discard 
     return ts


proc timeSeriesHead*(ats:Ts,n:int = 5):Ts =
     ## timeSeriesHead
     ## 
     ## returns a timeseries with n elements of the newest data
     ## 
     var nats = initTs() 
     for x in 0.. <n:
         nats.dd.add($(ats.dd[x]))
         nats.tx.add(ats.tx[x])
     result = nats


proc timeSeriesTail*(ats:Ts,n:int = 5):Ts =
     ## timeSeriesTail
     ## 
     ## returns a timeseries with n elements of the oldest data
     ## 
     var nats = initTs()
     for x in (ats.tx.len - n).. <ats.tx.len:
         nats.dd.add($(ats.dd[x]))
         nats.tx.add(ats.tx[x])
     result = nats


proc showTimeSeries* (ats:Ts,header,ty:string,N:int,fgr:string = yellowgreen,bgr:string = black,xpos:int = 0)  =
   ## showTimeseries
   ## takes a Ts object as input as well as a header string
   ## for the data column , a string which can be one of
   ## head,tail,all and N for number of rows to display
   ## usage :
   ##
   ## .. code-block:: nim
   ##     showTimeseries(myTimeseries,myHeader,"head|tail|all",rows)
   ##
   ## Example
   ##
   ## .. code-block:: nim
   ##    import cx,nimFinLib
   ##    # show adj. close price , 5 rows head and tail 374 days apart
   ##    var myD = initStocks()
   ##    myD = getSymbol2("0386.HK",minusdays(getDateStr(),374),getDateStr())
   ##    var mydT = timeseries(myD,"a") # adjusted close
   ##    curup(1)
   ##    echo()
   ##    showTimeSeries(mydT,"AdjClose","head",5)
   ##    curup(6)
   ##    showTimeSeries(mydT,"AdjClose","tail",5,xpos = 30)
   ##    doFinish()
   ##    
   printLn(fmtx(["<11","",">11"],"Date",spaces(1),header),fgr,xpos = xpos)
   if ats.dd.len > 0:
        if ty == all:
            for x in 0.. <ats.tx.len:
                printLn(fmtx(["<11","",">11"],ats.dd[x],spaces(1),ff2(ats.tx[x],4)),xpos = xpos)
        elif ty == tail:
            for x in (ats.tx.len - N).. <ats.tx.len:
                printLn(fmtx(["<11","",">11"],ats.dd[x],spaces(1),ff2(ats.tx[x],4)),xpos = xpos)
         
        else:
            ## head is the default in case an empty ty string was passed in
            for x in 0.. <N:
                printLn(fmtx(["<11","",">11"],ats.dd[x],spaces(1),ff2(ats.tx[x],4)),xpos = xpos)


proc initAccount*():Account =
     ## initAccount
     ##
     ## init a new empty account object
     ##
     ## .. code-block:: nim
     ##    var myAccount = initAccount()
     ##
     var apf : Account
     apf.pf = @[]
     result = apf


proc initPortfolio*(): Portfolio =
    ## initPortfolio
    ##
    ## init a new empty portfolio object
    ##
    ## .. code-block:: nim
    ##    var myETFportfolio = initPortfolio()
    ##
    var anf : Portfolio
    anf.nx = ""
    anf.dx = @[]
    result = anf


proc initStocks*(): Stocks =
    ## initStocks
    ##
    ## init stock data object
    ##
    ## .. code-block:: nim
    ##    var mystockData = initStocks()
    ##
    var adf : Stocks
    adf.stock = ""
    adf.date  = @[]
    adf.open  = @[]
    adf.high  = @[]
    adf.low   = @[]
    adf.close = @[]
    adf.vol   = @[]
    adf.adjc  = @[]
    adf.ro    = @[]
    adf.rh    = @[]
    adf.rl    = @[]
    adf.rv    = @[]
    adf.rc    = @[]
    adf.rca   = @[]
    result = adf

proc initYHobject*() : YHobject = 
     
     var myst : YHobject
     myst.stcode   = ""
     myst.stname   = ""
     myst.stmarket = ""
     myst.stprice  = ""
     myst.stdate   = ""
     myst.sttime   = ""
     myst.stopen   = ""
     myst.sthigh   = ""
     myst.stvolume = ""
     myst.stchange = ""
     myst.strange  = ""
     result = myst

proc initCurrencies*():Currencies=
     ## initCurrencies
     ##
     ## init a Currencies object to hold basic forex data
     ##
     ## .. code-block:: nim
     ##    var myForex = initCurrencies()
     ##
     var acf : Currencies
     acf.cu = @[]
     acf.ra = @[]
     result = acf



proc initPool*():seq[Stocks] =
  ## initPool
  ##
  ## init pools , which are sequences of Stocks objects used in portfolio building
  ##
  ## .. code-block:: nim
  ##    var mystockPool = initPool()
  ##
  result  = newSeq[Stocks]()


proc aline*()  {.discardable.} =
      printLn(repeat("-",tw),xpos = 0)


proc checkChange*(s:string):int = 
     # checkChange 
     # 
     # internal utility proc used by currentIDX
     # parse the change data[9] from yahoo
     # 
     # 
     var z = split(s," - ")[0]
     if z.startswith("+") == true:
        result = 1
     elif z.startswith("-") == true:
        result = -1
     else:
        result = 0


proc getCurrentQuote*(stcks:string) : string =
   ## getCurrentQuote
   ##
   ## gets the current price/quote from yahoo for 1 stock code
   var aurl=yahoourl  % stcks
   var data = newSeq[string]()
   let zcli = newHttpClient()
   var line = zcli.getContent(aurl)
   data = line[1..line.high].split(",")
   if data.len > 1:
      result = data[3]
   else:
      result = "-1"



proc getStocks*(aurl:string,xpos:int = 1):seq[string] =
  ## getStocks
  ##
  ## fetch stock data from yahoo and return in a seq[string] .
  ## 
  ## Data can be easily unpacked see showStocks.
  ## 
  ## Quote maybe 15 mins delayed
  ##
  ## callable
  ##
  #  some error handling is implemented if the yahoo servers are down
 
  var data3 = newSeq[string]()
    
  try:
       let zcli = newHttpClient(timeout = 5000)
       let zz = splitLines(zcli.getContent(aurl))
       for zs in 0.. <zz.len-1: data3.add(zz[zs])    
      
  except HttpRequestError:
      printLn("Yahoo current data could not be retrieved . Try again .\L",truetomato,xpos = xpos)
  finally:
      result = data3    




proc currentStocks(aurl:string,xpos:int = 1) =
  ## currentStocks
  ##
  ## display routine for current stock quote maybe 15 mins delayed
  ##
  ## not callable
  ##
  #  some error handling is implemented if the yahoo servers are down

  var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
  try:
    let zcli = newHttpClient(timeout = 5000)
    var ci = zcli.getContent(aurl)
    for line in ci.splitLines:
      var data = line[1..line.high].split(",")
      # even if yahoo servers are down our data.len is still 1 so
      if data.len > 1:
              printLn(fmtx(["<8","","","","",""],"Code : ",unquote(data[0])," Name : ",unquote(data[1]),"   Market : ",unquote(data[2])),yellowgreen,xpos = xpos)
              printLn(fmtx(["<10","<11","","","<9","","","<"],"Date : ",unquote(data[4]),unquote(data[5]),spaces(5),"Price  : ",data[3],"  Volume : ",data[8]),white,xpos = xpos)
              var cc = checkchange(unquote(data[9]))
              if cc == -1:  # down
                    printLn(fmtx(["","<8","","<8","","","","","","",""],"Open : ",data[6]," High : ",data[7]," Change :",red,downarrow,white,unquote(data[9]),"  Range : ",unquote(data[10])),white,xpos = xpos)
              
              elif cc == 0: # N/A
                    printLn(fmtx(["","<8","","<5","","","","","","","","",""],"Open : ",data[6]," High : ",data[7]," Change :",white,".",skyblue,unquote(data[9]),white,"  Range  : ",skyblue,unquote(data[10])),white,xpos = xpos)
       
              else :  # up
                    printLn(fmtx(["","<8","","<8","","","","","","",""],"Open : ",data[6]," High : ",data[7]," Change :",lime,uparrow,white,unquote(data[9]),"  Range : ",unquote(data[10])),white,xpos = xpos)
       
              printLn(repeat("-",tw))
      else:
             if data.len == 1 and sflag == false:
                printLn("Yahoo server maybe unavailable. Try again later",truetomato,xpos = xpos)
                sflag = true

  except HttpRequestError:
      printLn("Yahoo current data could not be retrieved . Try again .",truetomato,xpos = xpos)
      echo()
  finally:
      discard    


proc currentIndexes(aurl:string,xpos:int = 1) {.discardable.} =
  ## currentIndexes    currently unused - a different display format still needs to be adjusted for cx
  ##
  ## display routine for current index quote
  ##
  ## not callable
  ##
  #  some error handling is implemented if the yahoo servers are down

  var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
  try:
    let zcli = newHttpClient()
    var ci = zcli.getContent(aurl)
    for line in ci.splitLines:
      var data = line[1..line.high].split(",")
      if data.len > 1:
              var cc = checkChange(unquote(data[9]))
              
              case cc
                  of -1 :                                       
                          printLn(fmtx(["",">7"," ","<9","  ",">7","","<16","  ",">7","  ","<6","","<7","","<10","", "<8" ,"   ",">9", "","","",""],yellowgreen,"Code : ",peru,unquote(data[0]),yellowgreen , "Name : ",peru , unquote(data[1]),yellowgreen , "    Market : ",peru , unquote(data[2]),yellowgreen , "Date : ",peru , unquote(data[4]),peru , unquote(data[5]),yellowgreen , " Index : ",red , downarrow,lightskyblue , unquote(data[3])))
                          printLn(fmtx(["","","","<8","","","","","",">17","","","",""],yellowgreen,"Open : ",white,unquote(data[6]),yellowgreen,"  Change : ",red,downarrow,white , unquote(data[9]),yellowgreen,"    Range  : ",white,unquote(data[10])))            
                                            
                  of  0 : 
                          printLn(fmtx(["",">7"," ","<9","  ",">7","","<16","  ",">7","  ","<6","","<7","","<10","","<8","   ",">9","","","",""],yellowgreen,"Code : ",peru,unquote(data[0]),yellowgreen , "Name : ",peru , unquote(data[1]),yellowgreen , "    Market : ",peru , unquote(data[2]),yellowgreen , "Date : ",peru , unquote(data[4]),peru , unquote(data[5]),yellowgreen , " Index : ",white, ".",lightskyblue , unquote(data[3])))
                          printLn(fmtx(["","","","<8","","","","<2","",">17","","","",""],yellowgreen,"Open : ",white,unquote(data[6]),yellowgreen,"  Change : ",white," ",white , unquote(data[9]),yellowgreen,"    Range   :  ",white,unquote(data[10])))             
                          
                  of  1 : 
                          printLn(fmtx(["",">7"," ","<9","  ",">7","","<16","  ",">7","  ","<6","","<7","","<10","","<8","   ",">9","","","",""],yellowgreen,"Code : ",peru,unquote(data[0]),yellowgreen , "Name : ",peru , unquote(data[1]),yellowgreen , "    Market : ",peru , unquote(data[2]),yellowgreen , "Date : ",peru , unquote(data[4]),peru , unquote(data[5]),yellowgreen , " Index : ",lime , uparrow,lightskyblue , unquote(data[3])))
                          printLn(fmtx(["","","","<8","","","","","",">17","","","",""],yellowgreen,"Open : ",white,unquote(data[6]),yellowgreen,"  Change : ",lime,uparrow,white , unquote(data[9]),yellowgreen,"    Range  : ",white,unquote(data[10])))
                    
                  else  : printLn("Data Error",red)
                          
              echo repeat("-",tw)
      else:
              if data.len == 1 and sflag == false:
                 printLn("Yahoo server maybe unavailable. Try again later",red)
                 sflag = true
  except HttpRequestError:
      printLn("Yahoo current data could not be retrieved . Try again .",red)
      echo()


proc yahooStocks*(stock:string,xpos:int = 1):seq[YHobject] =
    ## yahooStocks
    ## 
    ## store all stocks data received by getStocks into a seq[YHobject] for 
    ## 
    ## easy moving about and unpacking
    ##  
    result = newSeq[YHobject]()
    let data5 = getStocks(yahoourl % stock ,xpos = xpos)
    var dn = newSeq[string]()
    var ss = stock.split("+")
    for x in 0.. <ss.len:
          dn = data5[x].split(",")
          var myst = initYHobject()
          if dn.len == 11:
              myst.stcode   = unquote(dn[0])
              myst.stname   = unquote(dn[1])
              myst.stmarket = unquote(dn[2])
              myst.stprice  = unquote(dn[3])
              myst.stdate   = unquote(dn[4])
              myst.sttime   = unquote(dn[5])
              myst.stopen   = unquote(dn[6])
              myst.sthigh   = unquote(dn[7])
              myst.stvolume = unquote(dn[8])
              myst.stchange = unquote(dn[9])
              myst.strange  = unquote(dn[10])
          else:
              # maybe will never be reached as yahoo may return N/A
              printLn("Yahoo returned insufficient data for $1",red % $ss[x],xpos = xpos)   
              
          result.add(myst)



proc showStocks*(stock:string,xpos:int = 1) =
    ## showStocks
    ## 
    ## convenience proc to lists all stocks received by getStocks
    ## 
    ##  
    ## 
    ##  
    for x in yahooStocks(stock,xpos = 10):
        printLnBiCol("Code      : " & x.stcode)
        printLnBiCol("Name      : " & x.stname)
        printLnBiCol("Market    : " & x.stmarket)
        printLnBiCol("Price     : " & x.stprice)
        printLnBiCol("Date/Time : " & fmtx(["","",""],x.stdate,spaces(1),x.sttime))
        printLnBiCol("Open      : " & x.stopen)
        printLnBiCol("High      : " & x.sthigh)
        printLnBiCol("Volume    : " & x.stVolume)
        printLnBiCol("Change    : " & x.stchange)
        printLnBiCol("Range     : " & x.strange)    
        echo()        


proc currentIDX(aurl:string,xpos:int) {.discardable.} =
    ## currentIDX
    ##
    ## display routine for current index quote using big slim letters for index value
    ##
    ## called by showCurrentIDX , allows postioning
    ##
    #  some error handling is implemented if the yahoo servers are down

    var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
    try:
      let zcli = newHttpClient()
      var ci = zcli.getContent(aurl)
      for line in ci.splitLines:
        var data = line[1..line.high].split(",")
        if data.len > 1:
                printBiCol(fmtx(["","<10"],"Code : ",unquote(data[0])),":",salmon,cyan,xpos = xpos)
                printLnBiCol(fmtx(["",""],"Index : ",unquote(data[1])),":",salmon,cyan)
                #curdn(1)                      
                printLnBiCol(fmtx(["","<30"],"Exch : ",unquote(data[2])),":",yellowgreen,goldenrod,xpos = xpos)                   
                #curdn(1)
                printLnBiCol(fmtx(["","<12","<9"],"Date : ", unquote(data[4]),unquote(data[5])),":",xpos = xpos)
                curup(1) # needed to position the rune below
                var cc = checkChange(unquote(data[9]))
                
                var slmdis = 57 - 2       # used for fine alignment of slim number xpos
                var chgdis = slmdis + 1   # used for fine alignment of change data xpos
                case cc
                  of -1 : 
                          print(downarrow,red,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],truetomato,xpos = xpos + slmdis,align = "right")
                          print("Change",red,xpos = xpos + chgdis)
                          curdn(1)
                          if unquote(data[9]) == "N/A":
                             print("N/A",xpos = xpos + chgdis)
                             curdn(1)
                             print("N/A",xpos = xpos + chgdis)
                             curdn(1)
                          else:   
                             print(split(unquote(data[9])," - ")[0],xpos = xpos + chgdis)
                             curdn(1)
                             print(split(unquote(data[9])," - ")[1],xpos = xpos + chgdis)
                             curdn(1)
                  of  0 :
                          curup(1) 
                          printSlim(data[3],steelblue,xpos = xpos + slmdis,align = "right")  
                          print("Change",white,xpos = xpos + chgdis)
                          curdn(1)
                          if unquote(data[9]) == "N/A":
                             print("N/A",xpos = xpos + chgdis)
                             curdn(1)
                             print("N/A",xpos = xpos + chgdis)
                             curdn(1)
                          else:   
                             print(split(unquote(data[9])," - ")[0],xpos = xpos + chgdis)
                             curdn(1)
                             print(split(unquote(data[9])," - ")[1],xpos = xpos + chgdis)
                             curdn(1)
                  of  1 : 
                          print(uparrow,lime,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],lime,xpos = xpos + slmdis ,align = "right")         
                          print("Change",yellowgreen,xpos = xpos + chgdis)
                          curdn(1)
                          if unquote(data[9]) == "N/A":
                             print("N/A",xpos = xpos + chgdis)
                             curdn(1)
                             print("N/A",xpos = xpos + chgdis)
                             curdn(1)
                          else:   
                             print(split(unquote(data[9])," - ")[0],xpos = xpos + chgdis)
                             curdn(1)
                             print(split(unquote(data[9])," - ")[1],xpos = xpos + chgdis)
                             curdn(1)
                  else  : 
                          print("Error",red,xpos = xpos + 31)              
                
                curup(1)
                printLnBiCol(fmtx(["",""],"Range: ",unquote(data[10])),":",xpos = xpos)
                printBiCol(fmtx(["","<8"],"Open : ",data[6]),":",xpos = xpos)     
                if unquote(data[8]) == "0":
                    printBiCol(fmtx([""],"  Vol   : N/A"),":",xpos = xpos + 17)
                else:
                    printBiCol(fmtx([""],"  Vol   : " & unquote(data[8])),":",xpos = xpos + 17)               
                printLn("Yahoo Finance Data",brightblack,xpos = xpos + slmdis - 12)
                printLn(repeat("_",63),xpos = xpos)
                
        else:
                if data.len == 1 and sflag == false:
                  printLn("Yahoo Server Fail.",truetomato,xpos = xpos)
                  sflag = true
                  
    except HttpRequestError:
          printLn("Index Data temporary unavailable" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except ValueError:
          discard
    except OSError:
          discard
    except OverflowError:
          discard
    except  TimeoutError:
         printLn("TimeoutError: " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except  ProtocolError:
          printLn("Protocol Error" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except :
         discard
    finally:
        discard  

        

proc buildStockString*(apf:Portfolio):string =
  ## buildStocksString
  ##
  ## Produce a string of one or more stock codes coming from a Portfolio object
  var xs = ""
  for x in 0.. <apf.dx.len:
    # need to pass multiple code like so code+code+ , an initial + is also ok.
    xs = xs & "+" & apf.dx[x].stock
  result = xs

proc buildStockString*(adf:seq[Stocks]):string =
  ## buildStocksString
  ##
  ## Produce a string of one or more stock codes coming from a pool Stocks object
  var xs = ""
  for x in 0.. <adf.len:
    # need to pass multiple code like so code+code+ , an initial + is also ok.
    xs = xs & "+" & adf[x].stock
  result = xs


# Note showCurrentIDX and showCurrentStocks are basically the same
# but it makes for easier reading in the application to give it different names

proc showCurrentIndexes*(adf:seq[Stocks],xpos:int = 1){.discardable.} =
   ## showCurrentIndexes
   ##
   ## callable display routine for currentIndexes with a pool object passed in
   ## 
   ## wide view
   ##
   var idxs = buildStockString(adf)
   #hdx(echo "Index Data for a pool" )
   var qurl = yahoourl  % idxs
   currentIndexes(qurl,xpos = xpos)


proc showCurrentIndexes*(idxs:string,xpos:int = 1){.discardable.} =
    ## showCurrentIndexes
    ##
    ## callable display routine for currentIDX with a string of format IDX1+IDX2+IDX3 .. 
    ## 
    ## passed in . Note this will use big slim letters to display inex value
    ## 
    ## wide view
    ##
    ## .. code-block:: nim
    ##     showCurrentIndexes("^HSI+^GDAXI+^FTSE+^NYA",xpos = 5)
    ## xpos allows x positioning
    #
    var qurl = yahoourl  % idxs
    currentIndexes(qurl,xpos = xpos)


proc showCurrentIDX*(adf:seq[Stocks],xpos:int = 1,header:bool = false){.discardable.} =
   ## showCurrentIDX
   ##
   ## callable display routine for currentIndexes with a pool object passed in
   ## 
   ## compact view
   ##
   
   var idxs = buildStockString(adf)
   if header == true: hdx(printLn("Index Data ",yellowgreen,termblack),width = 64,nxpos = xpos)
   var qurl = yahoourl  % idxs
   currentIDX(qurl,xpos = xpos)



proc showCurrentIDX*(idxs:string,xpos:int = 1,header:bool = false){.discardable.} =
    ## showCurrentIDX
    ##
    ## callable display routine for currentIDX with a string of format IDX1+IDX2+IDX3 .. 
    ## 
    ## passed in . Note this will use big slim letters to display inex value
    ## 
    ## compact view
    ## 
    ##
    ## .. code-block:: nim
    ##     showCurrentIDX("^HSI+^GDAXI+^FTSE+^NYA",xpos = 5)
    ## xpos allows x positioning
    #
    
    if header == true: hdx(printLn("Index Quote ",yellowgreen,termblack),width = 64,nxpos = xpos)
    var qurl = yahoourl  % idxs
    currentIDX(qurl,xpos = xpos)


proc currentSTX(aurl:string,xpos:int) {.discardable.} =
    ## currentIDX
    ##
    ## display routine for current index quote using big slim letters for index value
    ##
    ## called by showCurrentSTX , allows postioning
    ## 
    ## 
    #  some error handling is implemented if the yahoo servers are down

    var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
    try:
      let zcli = newHttpClient()
      var ci = zcli.getContent(aurl)
      for line in ci.splitLines:
        var data = line[1..line.high].split(",") 
        
        if data.len > 1:
                printBiCol(fmtx(["","<9"],"Code : ",unquote(data[0])),":",lightskyblue,cyan,xpos = xpos)
                printLnBiCol(fmtx(["","<36"],"   Name : ",unquote(data[1])),":",lightskyblue,pastelyellowgreen)
                printLnBiCol(fmtx(["",""],"Exch : ",unquote(data[2])),":",yellowgreen,goldenrod,xpos = xpos)
                #curdn(1)
                printLnBiCol(fmtx(["","<12","<9",""],"Date : ",unquote(data[4]),unquote(data[5]),spaces(4)),":",xpos = xpos)
                curup(1) 
                var cc = checkChange(unquote(data[9])) 
                
                var slmdis = 57 - 2       # used for fine alignment of slim number xpos
                var chgdis = slmdis + 1   # used for fine alignment of change data xpos
                case cc
                  of -1 : 
                          print(downarrow,red,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],truetomato,xpos = xpos + slmdis,align = "right")
                          print("Change",red,xpos = xpos + chgdis)
                          curdn(1)
                          try:
                             print(split(unquote(data[9])," - ")[0],xpos = xpos + chgdis)
                          except:
                             print("N/A",xpos = xpos + chgdis)
                          curdn(1)
                          try:
                             print(split(unquote(data[9])," - ")[1],xpos = xpos + chgdis)
                          except:
                             print("N/A",xpos = xpos + chgdis)
                          curdn(1)
                  of  0 :
                          curup(1) 
                          printSlim(data[3],steelblue,xpos = xpos + slmdis,align = "right")  
                          print("Change",white,xpos = xpos + chgdis)
                          curdn(1)
                          try:
                             print(split(unquote(data[9])," - ")[0],xpos = xpos + chgdis)
                          except:
                             print("N/A",xpos = xpos + chgdis)
                          curdn(1)
                          try:
                             #print(split(unquote(data[9])," - ")[1],xpos = xpos + chgdis)
                             print("N/A",xpos = xpos + chgdis)  
                          except:
                             print("N/A",xpos = xpos + chgdis)
                          curdn(1)
                  of  1 : 
                          print(uparrow,lime,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],lime,xpos = xpos + slmdis ,align = "right")         
                          print("Change",yellowgreen,xpos = xpos + chgdis)
                          curdn(1)
                          try:
                             print(split(unquote(data[9])," - ")[0],xpos = xpos + chgdis)
                          except:
                             print("N/A",xpos = xpos + chgdis)
                          curdn(1)
                          try:
                             print(split(unquote(data[9])," - ")[1],xpos = xpos + chgdis)
                          except:
                             print("N/A",xpos = xpos + chgdis)
                          curdn(1)
                  else  : 
                          print("Error",red,xpos = xpos + 31)              
                
                curup(1)
                printLnBiCol(fmtx(["",""],"Range: ",unquote(data[10])),":",xpos = xpos)
                printBiCol(fmtx(["","<8"],"Open : ",unquote(data[6])),":",xpos = xpos)          
                printBiCol(fmtx([""],"   Vol  : " & unquote(data[8])),":",xpos = xpos + 17)               
                printLn("Yahoo Finance Data",brightblack,xpos = xpos + slmdis - 12)
                printLn(repeat("_",63),xpos = xpos)
            
        else:
                if data.len == 1 and sflag == false:
                   printLn("Yahoo Server Fail.",truetomato,xpos = xpos)
                   sflag = true
    except HttpRequestError:
          printLn("Stock Data temporary unavailable" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except ValueError:
          discard
    except OSError:
          discard
    except OverflowError:
          discard
    except  TimeoutError:
         printLn("TimeoutError: " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except  ProtocolError:
         printLn("Protocol Error" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except :
         discard
    finally:
        discard  


proc showCurrentStocks*(apf:Portfolio,xpos:int = 1,header:bool = false){.discardable.} =
   ## showCurrentStocks
   ##
   ## callable display routine for currentStocks with Portfolio object passed in
   ## 
   ## wide view
   ## 
   ## .. code-block:: nim
   ##    showCurrentStocks(myAccount.pf[0])
   ##
   ## This means get all stock codes of the first portfolio in myAccount
   ##
   ## Note : Yahoo servers maybe down sometimes which will make this procs fail.
   ##
   ## Just wait a bit and try again. Stay calm ! Do not panic !
   ##
   ## for full example see nimFinT5.nim
   ##
   var stcks = buildStockString(apf)
   if header == true : hdx(printLn("Stocks Current Quote for $1" % apf.nx,yellowgreen,termblack,xpos = xpos + 2),width = 64,nxpos = xpos)         
   var qurl = yahoourl  % stcks
   currentStocks(qurl,xpos = xpos)



proc showCurrentStocks*(stcks:string,xpos:int = 1,header:bool = false){.discardable.} =
   ## showCurrentStocks
   ##
   ## callable display routine for currentStocks with stockstring passed in
   ##
   ## wide view
   ##
   ## .. code-block:: nim
   ##    showCurrentStocks("IBM+BP.L+0001.HK")
   ##    decho(2)
   ##
   ## Note : Yahoo servers maybe down sometimes which will make this procs fail.
   ##
   ## Just wait a bit and try again. Stay calm ! Do not panic !
   ##
   
   if header == true : hdx(printLn("Stocks Current Quote ",yellowgreen,termblack,xpos = xpos + 2),width = 64,nxpos = xpos)         
   var qurl = yahoourl  % stcks
   currentStocks(qurl,xpos = xpos)


proc showCurrentSTX*(apf:Portfolio,xpos:int = 1,header:bool = false){.discardable.} =
   ## showCurrentSTX
   ##
   ## callable display routine for currentSTX with Portfolio object passed in
   ## 
   ## compact view
   ##
   ## .. code-block:: nim
   ##    showCurrentSTX(myAccount.pf[0])
   ##
   ## This means get all stock codes of the first portfolio in myAccount
   ##
   ## Note : Yahoo servers maybe down sometimes which will make this procs fail.
   ##
   ## Just wait a bit and try again. Stay calm ! Do not panic !
   ##
   ## for full example see nimFinT5.nim
   ##
   
   var stcks = buildStockString(apf)
   if header == true: hdx(printLn("Stocks Current Quote for $1" % apf.nx,yellowgreen,termblack,xpos = xpos + 2),width = 64,nxpos = xpos)
   var qurl = yahoourl  % stcks
   currentSTX(qurl,xpos = xpos)



proc showCurrentSTX*(stcks:string,xpos:int = 1,header:bool = false){.discardable.} =
   ## showCurrentSTX
   ##
   ## callable display routine for currentSTX with stockstring passed in
   ##
   ## compact display style
   ##
   ## .. code-block:: nim
   ##    showCurrentSTX("IBM+BP.L+0001.HK")
   ##    decho(2)
   ##
   ## Note : Yahoo servers maybe down sometimes which will make this procs fail.
   ##
   ## Just wait a bit and try again. Stay calm ! Do not panic !
   ##
   
   if header == true :  hdx(printLn("Stocks Quote ",yellowgreen,termblack,xpos = xpos + 2),width = 64,nxpos = xpos)
   var qurl = yahoourl  % stcks
   currentSTX(qurl,xpos = xpos)
 



proc ymonth*(aDate:string) : string =
  ## ymonth
  ##
  ## yahoo month starts with 00 for jan
  ##
  ## Format MM
  ##
  ## only used internally for yahoo url setup
  #
  var asdm = $(parseInt(aDate.split("-")[1])-1)
  if len(asdm) < 2: asdm = "0" & asdm
  result = asdm


proc get_crumble_and_cookie(symbol:string):seq[string] =
    result = @[]
    var cookie_str = ""
    var crumble_link = "https://finance.yahoo.com/quote/$1/history?p=$1"
    var link = crumble_link % symbol
    var zcli = newHttpClient()
    var response = zcli.request(link,httpMethod = HttpGet)
    for x,y in response.headers:
         if $x == "set-cookie" : cookie_str = y.split(";")[0]
    var m1 = find($response.body,re"""CrumbStore":{"crumb":"(.*?)"}""")  
    var m2 = replace($m1,"""Some(CrumbStore":{"crumb":"""  , "")
    var crumble_str = replace(m2,"})","").replace("\"","")
    result.add(crumble_str)
    result.add(cookie_str)
    

proc download_quote(symbol:string, date_from:string = "2000-01-01", date_to:string = "2100-01-01",events:string = ""):string = 
    result = ""
    var quote_link = "https://query1.finance.yahoo.com/v7/finance/download/$1?period1=$2&period2=$3&interval=1d&events=$4&crumb=$5"
    var time_stamp_from = $(epochSecs(date_from))     
    var time_stamp_to = $(epochSecs(date_to))  
    var events = "history"   # default  available: history|div|split
    var attempts = 1
    var okflag = false
    var cc = newSeq[string]()
    while attempts < 4 and okflag == false:
        echo("Attempt No.       : ",attempts,"  for ",symbol)
        cc = get_crumble_and_cookie(symbol)
        quotelink = quote_link % [symbol, time_stamp_from, time_stamp_to, events,$cc[0]]
        var zcli = newHttpClient()
        var dacooky = strip(cc[1])
        zcli.headers = newHttpHeaders({"Cookie": dacooky}) 
        try:
                var r = zcli.request(url=quotelink)
                if ($r.body).len > 0:
                   if ($r.body).contains("Invalid cookie") == true:
                      okflag = false
                      supererrorflag = true
                      attempts += 1
                      sleepy(2 * attempts)  # do not hit poor yahoo too fast
                      result = "Symbol " & symbol & " download failed.\n\nReason : \n\n"
                      result = result & $r.body   # adding any yahoo returned error message
                      
                   else:
                      okflag = true 
                      supererrorflag = false
                      result = $r.body
                   
                
        except :
                # we may come here if the httpclient can not connect or there is no such symbol
                supererrorflag = true           
                attempts += 1
                okflag = false
                sleepy(2 * attempts)
                result = "Symbol " & symbol & " download failed.\n"
                break
             
#  trying to rewrite this
proc getSymbol2*(symb,startDate,endDate : string,processFlag:bool = false) : Stocks =
    ## getSymbol2
    ##
    ## the work horse proc for getting yahoo data in csv format
    ##
    ## and then to parse into a Stocks object
    ##
    # feedbackline can be commented out if not desired
    #
    # check the dates if there are funny dates an empty Stocks object will be returned
    # together with an error message
    # 
    # Note on rewrite something blocks the data despite it coming in
    # 

    if validdate(startDate) and validdate(endDate):
          if processFlag == true:
             print(fmtx(["<15"],"Processing   : "))
             print(fmtx(["<8"],symb & spaces(1)),green)
             print(fmtx(["<11","","<11"],startDate,spaces(1),endDate))
             # end feedback line
          else:
              printLnBiCol("Processing... : " & symb,":",lightskyblue)
              curup(1)
          # set up dates for yahoo
          var sdy = year(startDate)
          var sdm = ymonth(startDate)
          var sdd = day(startDate)

          var edy = year(endDate)
          var edm = ymonth(endDate)
          var edd = day(endDate)

          # set up df variables
          var datx = ""
          var datdf = newSeq[string]()
          var opex = 0.0
          var opedf = newSeq[float]()
          var higx = 0.0
          var higdf = newSeq[float]()
          var lowx = 0.0
          var lowdf = newSeq[float]()
          var closx = 0.0
          var closdf = newSeq[float]()
          var volx = 0.0
          var voldf = newSeq[float]()
          var adjclosx = 0.0
          var adjclosdf = newSeq[float]()

          # add RunningStat capability all columns
          var openRC   : Runningstat
          var highRC   : Runningstat
          var lowRC    : Runningstat
          var closeRC  : Runningstat
          var volumeRC : Runningstat
          var closeRCA : Runningstat
             
          var headerset = [symb,"Date","Open","High","Low","Close","Volume","Adj Close"]
          var c = 0
          var hflag  : bool # used for testing maybe removed later
          var astock = initStocks()   # this will hold our result history data for one stock

          # naming outputfile nimfintmp.csv as many stock symbols have dots like 0001.HK
          # could also be done to be in memory like /shm/  this file will be auto removed.

          var acvsfile = "nimfintmp.csv"
          var errstflag = false 
          
          #prepare for writing incoming data
          var fsw = newFileStream(acvsfile, fmWrite)
          try:
               var mydata = download_quote(symbol = symb,startdate,enddate)
               # maybe we can check here for invalid data and abort imm if something is wrong
               if mydata.contains("Invalid cookie") == true:    
                   errstflag = true
                   printLnBiCol("Error downloading data for : " & symb ,":",peru,red)
                   
               # we only continue if no error sofar
               if errstflag == false:
                   var mydataline = mydata.splitLines()
                   var xdata2 = ""
                   for xdata in mydataline:
                       xdata2 = strip(xdata,true,true)
                      
                       if xdata2.len > 0:
                          # we do not write lines with "null" values as happens with yahoo data
                          # unfortunately this makes holes in our timeseries
                          if ($xdata2).contains("null") == false: 
                             fsw.writeLine(xdata2)
                             
                            
               printLnBicol("Created  File     : " & acvsfile)
               echo()
          except:
               printLnBicol("Error writing to  : " & acvsfile,":",red)
               discard
            
          fsw.close() 
          sleepy(0.3) # give it some time to settle down
          
          # now reopen the file with the cvsparser for reading 
         
          var x: CsvParser
          if errstflag == false and supererrorflag == false: 
                var s = newFileStream(acvsfile, fmRead)
                if s == nil:
                    # in case of problems with the yahoo csv file we show a message
                    printLn("Error : Data file for $1 could not be opened " % symb,red)
                    errstflag = true
                
                # now try to open anyway and see whats going on parse the csv file
                if errstflag == false:
                   open(x, s , acvsfile, separator=',')
                   while readRow(x):
                     
                      if errstflag == false and supererrorflag == false: 
                          # a way to get the actual csv header , but here we use our custom headerset with more info
                          # if validIdentifier(x.row[0]):
                          #    header = x.row
                          c = 0 # counter to assign item to correct var
                          
                          for val in items(x.row):
                            if val in headerset:
                                hflag = true

                            else:
                                c += 1
                                hflag = false

                                case c
                                of 1:
                                    datx = val
                                    datdf.add(datx)

                                of 2:
                                    opex = parseFloat(val)
                                    openRC.push(opex)      ## RunningStat for open price
                                    opedf.add(opex)

                                of 3:
                                    higx = parseFloat(val)
                                    highRC.push(higx)
                                    higdf.add(higx)

                                of 4:
                                    lowx = parseFloat(val)
                                    lowRC.push(lowx)
                                    lowdf.add(lowx)

                                of 5:
                                    closx = parseFloat(val)
                                    closeRC.push(closx)     ## RunningStat for close price
                                    closdf.add(closx)
                                    
                                of 6:
                                    adjclosx = parseFloat(val)
                                    closeRCA.push(adjclosx)  ## RunningStat for adj close price
                                    adjclosdf.add(adjclosx)

                                of 7:
                                    volx = parseFloat(val)
                                    volumeRC.push(volx)
                                    voldf.add(volx)

                            
                                else :
                                    printLn("Csv Data in unexpected format for Stocks :" & symb,red)

          # feedbacklines can be shown with processFlag set to true
          if processFlag == true and errstflag == false and supererrorflag == false:
             printLn(" --> Rows processed : " & $processedRows(x),salmon)
          

          # close CsvParser
          if processFlag == true and errstflag == false and supererrorflag == false:
             try:
                 close(x)
             except:
                 printLn("csvParser x was not closed",red)

          # put the collected data into Stocks type
          # if errstflag == true the stock name will be changed to Error for further handling
          # this occures if yahoo does not have data for a given stock
          if errstflag == false and supererrorflag == false:
             astock.stock = symb
          else:
             astock.stock = "Error " & symb
          astock.date  = datdf
          astock.open  = opedf
          astock.high  = higdf
          astock.low   = lowdf
          astock.close = closdf
          astock.adjc  = adjclosdf
          astock.vol   = voldf
          astock.ro    = @[]
          astock.rh    = @[]
          astock.rl    = @[]
          astock.rc    = @[]
          astock.rv    = @[]
          astock.rca   = @[]

          astock.ro.add(openRC)
          astock.rh.add(highRC)
          astock.rl.add(lowRC)
          astock.rc.add(closeRC)
          astock.rv.add(volumeRC)
          astock.rca.add(closeRCA)

          # clean up
          removeFile(acvsfile)
          # send astock back
          result = astock

    else:
          printLn("Date error     : " &  startDate &  "/" & endDate & "  Format yyyy-MM-dd expected",red)
          printLn("Error location : proc getSymbol2",red)
          result = initStocks() # return an empty df


proc getSymbol3*(symb:string,startDate,endDate : string,processFlag:bool = false):Stockdata =
     ## getSymbol3   
     ##
     ## data returned is inside an Stockdata object with following fields and types
     ##
     ## the reason for string types in marketcap and ebitda is yahoo returning
     ##
     ## numbers shortened with B for billions etc.
     ##
     ## not all data may be available for stocks or even maybe incorrect.
     ##
     ## so use with care.
     ##
     ##
     ##     price*            : float
     ##
     ##     change*           : float
     ##
     ##     volume*           : float
     ##
     ##     avgdailyvol*      : float
     ##
     ##     market*           : string
     ##
     ##     marketcap*        : string
     ##
     ##     bookvalue*        : float
     ##
     ##     ebitda*           : string
     ##
     ##     dividendpershare* : float
     ##
     ##     dividendperyield* : float
     ##
     ##     earningspershare* : float
     ##
     ##     week52high*       : float
     ##
     ##     week52low*        : float
     ##
     ##     movingavg50day*   : float
     ##
     ##     movingavg200day*  : float
     ##
     ##     priceearingratio* : float
     ##
     ##     priceearninggrowthratio* : float
     ##
     ##     pricesalesratio*  : float
     ##
     ##     pricebookratio*   : float
     ##
     ##     shortratio*       : float
     ##
     ##
     ##     Example : 
     ##     
     ## .. code-block:: nim     
     ##     echo getSymbol3("0005.HK","2000-01-01",getDateStr())
     ##
     var qz : Stockdata
     var stx = "l1c1va2xj1b4j4dyekjm3m4rr5p5p6s7"
     var qurl3 = "http://finance.yahoo.com/d/quotes.csv?s=$1&f=$2" % [symb, stx]
     let zcli = newHttpClient()
     var rx = zcli.getcontent(qurl3)
     var rxs = rx.split(",")
     try:
        qz.price             = parseFloat(strip(rxs[0]))
     except:
        qz.price             =  0.0
     try:
        qz.change            = parseFloat(strip(rxs[1]))
     except:
        qz.change            = 0.0
     try:
        qz.volume            = parseFloat(strip(rxs[2]))
     except:
        qz.volume            = 0.0
     try:
        qz.avgdailyvol       = parseFloat(strip(rxs[3]))
     except:
        qz.avgdailyvol       = 0.0
     try:
        qz.market            = strip(rxs[4])
     except:
        qz.market            = ""
     try:
        qz.marketcap         = strip(rxs[5])
     except:
        qz.marketcap         = ""
     try:
        qz.bookvalue         = parseFloat(strip(rxs[6]))
     except:
        qz.bookvalue         = 0.0
     try:
        qz.ebitda            = strip(rxs[7])
     except:
        qz.ebitda            = ""
     try:
        qz.dividendpershare  = parseFloat(strip(rxs[8]))
     except:
        qz.dividendpershare  = 0.0
     try:
        qz.dividendperyield  = parseFloat(strip(rxs[9]))
     except:
        qz.dividendperyield  = 0.0
     try:
        qz.earningspershare  = parseFloat(strip(rxs[10]))
     except:
        qz.earningspershare  = 0.0
     try:
        qz.week52high        = parseFloat(strip(rxs[11]))
     except:
        qz.week52high        = 0.0
     try:
        qz.week52low         = parseFloat(strip(rxs[12]))
     except:
        qz.week52low         = 0.0
     try:
        qz.movingavg50day    = parseFloat(strip(rxs[13]))
     except:
        qz.movingavg50day    = 0.0
     try:
        qz.movingavg200day   = parseFloat(strip(rxs[14]))
     except:
        qz.movingavg200day   = 0.0
     try:
        qz.priceearingratio  = parseFloat(strip(rxs[15]))
     except:
        qz.priceearingratio  = 0.0
     try:
        qz.priceearninggrowthratio = parseFloat(strip(rxs[16]))
     except:
        qz.priceearninggrowthratio = 0.0
     try:
        qz.pricesalesratio   = parseFloat(strip(rxs[17]))
     except:
        qz.pricesalesratio   = 0.0
     try:
        qz.pricebookratio    = parseFloat(strip(rxs[18]))
     except:
        qz.pricebookratio    = 0.0
     try:
        qz.shortratio        = parseFloat(strip(rxs[19]))
     except:
        qz.shortratio        = 0.0
     result = qz



proc showHistData*(adf: Stocks,n:int) =
    ## showhistData
    ##
    ## Show n recent rows historical stock data
    decho(1)
    printLn(fmtx(["<8","<11",">10",">10",">10",">10",">14",">10"],"Code","Date","Open","High","Low","Close","Volume","AdjClose"),green)
    if n >= adf.date.len:
      for x in 0.. <adf.date.len:
        echo(fmtx(["<8","<11",">10.3",">10.3",">10.3",">10.3",">14",">10.3"],adf.stock,adf.date[x],adf.open[x],adf.high[x],adf.low[x],adf.close[x],adf.vol[x],adf.adjc[x]))
    else:
      for x in 0.. <n:
        echo(fmtx(["<8","<11",">10.3",">10.3",">10.3",">10.3",">14",">10.3"],adf.stock,adf.date[x],adf.open[x],adf.high[x],adf.low[x],adf.close[x],adf.vol[x],adf.adjc[x]))
    decho(2)


proc showHistData*(adf: Stocks,s: string,e:string) =
    ## showhistData
    ##
    ## show historical stock data between 2 dates
    ##
    ## dates must be of format yyyy-MM-dd
    # s == e   ==> 0
    # s >= e   ==> 1
    # s <= e   ==> 2
    decho(1)
    printLn(fmtx(["<8","<11",">10",">10",">10",">10",">14",">10"],"Code","Date","Open","High","Low","Close","Volume","AdjClose"),green)
    for x in 0.. <adf.date.len:
      var c1 = compareDates(adf.date[x],s)
      var c2 = compareDates(adf.date[x],e)
      if c1 == 1 or c1 == 0:
          if c2 == 2  or c2 == 0:
             echo(fmtx(["<8","<11",">10.3",">10.3",">10.3",">10.3",">14",">10.3"],adf.stock,adf.date[x],adf.open[x],adf.high[x],adf.low[x],adf.close[x],adf.vol[x],adf.adjc[x]))
    decho(2)


proc seqlast*[T](self : seq[T]): T =
    ## Various data navigation routines
    ##
    ## first,last,head,tail
    ##
    ## last means most recent row
    ##
    try:
      result = self[self.low]
    except IndexError:
      discard


proc seqfirst*[T](self : seq[T]): T =
    ## first means oldest row
    ## still need to improve this in case nothing received
    try:
        result = self[self.high]
    except:
      result = self[0]

proc seqtail*[T](self : seq[T] , n: int) : seq[T] =
    ## tail means most recent rows
    ##
    try:
        if len(self) >= n:
            result = self[0.. <n]
        else:
            result = self[0.. <len(self)]
    except RangeError:
       discard


proc seqhead*[T](self : seq[T] , n: int) : seq[T] =
    ## head means oldest rows
    ##
    var self2 = reversed(self)
    try:
        if len(self2) >= n:
            result = self2[0.. <n].seqtail(n)
        else:
            result = self2[0.. <len(self2)].seqtail(n)
    except RangeError:
       discard


proc lagger*[T](self:T , days : int) : T =
     ## lagger
     ##
     ## often we need a timeseries off by x days
     ##
     ## this functions provides this
     ##
     try:
       var lgx = self[days.. <self.len]
       result = lgx
     except RangeError:
       discard


proc dailyReturns*(self:seq[float]):seq =
    ## dailyReturns
    ##
    ## daily returns calculation gives same results as dailyReturns in R / quantmod
    ##
    var k = 1
    var lgx = newSeq[float]()
    for z in 1+k.. <self.len:
        lgx.add(1-(self[z] / self[z-k]))
    result = lgx


proc showDailyReturnsCl*(self:Stocks , N:int) =
      ## showdailyReturnsCl
      ##
      ## display returns based on close price
      ##
      ## formated output to show date and returns columns
      ##
      var dfr = self.close.dailyReturns    # note the first in seq corresponds to date closest to now

      # we also need to lag the dates
      var dfd = self.date.lagger(1)
      if dfd.len > 0:
          # now show it with symbol , date and close columns
          echo ""
          printLn(fmtx(["<8","","<11","",">14"],"Code",spaces(1),"Date",spaces(1),"Returns"),yellowgreen)
          # show limited rows output if c<>0
          if N == 0:
              for  x in 0.. <dfr.len:
                      printLn(fmtx(["<8","<11","",">15.10f"],self.stock,dfd[x],spaces(1),ff2(dfr[x],6)))

          else:
              for  x in 0.. <N:
                      printLn(fmtx(["<8","<11","",">15.10f"],self.stock,dfd[x],spaces(1),ff2(dfr[x],6)))



proc showDailyReturnsAdCl*(self:Stocks , N:int) =
      ## showdailyReturnsAdCl
      ##
      ## returns based on adjusted close price
      ##
      ## formated output to only show date and returns
      ##
      var dfr = self.adjc.dailyReturns    # note the first in seq corresponds to date closest to now
      # we also need to lag the dates
      var dfd = self.date.lagger(1)
      if dfd.len > 0:
            # now show it with symbol , date and close columns
            echo ""
            printLn(fmtx([":<8","","<11","",">14"],"Code",spaces(1),"Date",spaces(1),"Returns"),yellowgreen)
            # show limited output if c<>0
            if N == 0:
                for  x in 0.. <dfr.len:
                        printLn(fmtx(["<8","<11","",">15.10f"],self.stock,dfd[x],spaces(1),ff2(dfr[x],6)))

            else:
                for  x in 0.. <N:
                        printLn(fmtx(["<8","<11","",">15.10f"],self.stock,dfd[x],spaces(1),ff2(dfr[x],6)))


proc sumDailyReturnsCl*(self:Stocks) : float =
      ## sumdailyReturnsCl
      ##
      ## returns sum based on close price
      ##
      # returns a sum of dailyreturns but is off from quantmod more than expected why ?
      # the len of seq roughly the same of by 1-2 vals as expected but
      # the sum is of by too much , maybe it is in the missing values
      result = 0.0
      var sumdfr = 0.0
      var dR = self.close.dailyReturns
      
      try:
         sumdfr = sum(dR)
         # feedback line can be commented out
         printLn("Returns on Close Price calculated : " & $dR.len,yellow)
      except:   
           printLnBiCol("Returns on Close Price : failed due to no data error . value 0.0 returned",":",red)
      result = sumdfr


proc sumDailyReturnsAdCl*(self:Stocks) : float =
      ## sumdailyReturnsAdCl
      ##
      ## returns sum based on adjc
      ##
      # returns a sum of dailyreturns but is off from quantmod more than expected why ?
      # the len of seq roughly the same of by 1-2 vals as expected but
      # the sum is of by too much , maybe it is in the missing values
      result = 0.0
      var sumdfr = 0.0
      var dR = self.adjc.dailyReturns
      try:
          var sumdfr = sum(dR)
          # feedback line can be commented out
          printLn("Returns on Close Price calculated : " & $dR.len,peru)
      except:
          printLnBiCol("Returns on Adjc.Close Price : failed due to no data error . value 0.0 returned",":",red)
      result = sumdfr


proc statistics*(x:Runningstat) =
        ## statistics
        ##
        ## display statistsics output of a runningstat object
        ##
        echo "RunningStat Sum     : ", $formatFloat(x.sum,ffDecimal,5)
        echo "RunningStat Var     : ", $formatFloat(x.variance,ffDecimal,5)
        echo "RunningStat mean    : ", $formatFloat(x.mean,ffDecimal,5)
        echo "RunningStat Std     : ", $formatFloat(x.standardDeviation,ffDecimal,5)
        echo "RunningStat Max     : ", $formatFloat(x.max,ffDecimal,5)
        echo "RunningStat Min     : ", $formatFloat(x.min,ffDecimal,5)



proc showStatistics*(z : Stocks) =
      ## showStatistics
      ##
      ## shows all statistics from a Stocks objects ohlcva columns
      ##
      var itemset = @["sum","variance","mean","stddev","max","min"]
      var ohSet = @[z.ro[0],z.rh[0],z.rl[0],z.rc[0],z.rv[0],z.rca[0]]
      var z1 = newSeq[float]()
      var z2 = newSeq[float]()
      var z3 = newSeq[float]()
      var z4 = newSeq[float]()
      var z5 = newSeq[float]()
      var z6 = newSeq[float]()

      for x in 0.. 5:
          z1.add(ohSet[x].sum)
      for x in 0.. 5:
          z2.add(ohSet[x].variance)
      for x in 0.. 5:
          z3.add(ohSet[x].mean)
      for x in 0.. 5:
          z4.add(ohSet[x].standardDeviation)
      for x in 0.. 5:
          z5.add(ohSet[x].max)
      for x in 0.. 5:
          z6.add(ohSet[x].min)

      decho(1)
      printLn(fmtx(["<11",">11",">11",">11",">11",">14",">11"],"Item","Open","High","Low","Close","Volume","Adj Close"),yellowgreen)
      printLn(fmtx(["<11",">11",">11",">11",">11",">14",">11"],itemset[0],ff(z1[0],2),ff(z1[1],2),ff(z1[2],2),ff(z1[3],2),ff2(z1[4],0),ff(z1[5],2)))
      printLn(fmtx(["<11",">11",">11",">11",">11",">14",">11"],itemset[1],ff(z2[0],2),ff(z2[1],2),ff(z2[2],2),ff(z2[3],2),ff2(z2[4],0),ff(z2[5],2)))
      printLn(fmtx(["<11",">11",">11",">11",">11",">14",">11"],itemset[2],ff(z3[0],2),ff(z3[1],2),ff(z3[2],2),ff(z3[3],2),ff2(z3[4],0),ff(z3[5],2)))
      printLn(fmtx(["<11",">11",">11",">11",">11",">14",">11"],itemset[3],ff(z4[0],2),ff(z4[1],2),ff(z4[2],2),ff(z4[3],2),ff2(z4[4],0),ff(z4[5],2)))
      printLn(fmtx(["<11",">11",">11",">11",">11",">14",">11"],itemset[4],ff(z5[0],2),ff(z5[1],2),ff(z5[2],2),ff(z5[3],2),ff2(z5[4],0),ff(z5[5],2)))
      printLn(fmtx(["<11",">11",">11",">11",">11",">14",">11"],itemset[5],ff(z6[0],2),ff(z6[1],2),ff(z6[2],2),ff(z6[3],2),ff2(z6[4],0),ff(z6[5],2)))
      decho(2)                                                                     


proc showStatisticsT*(z : Stocks) =
      ## showStatisticsT
      ##
      ## shows all statistics from a Stocks objects ohlcva columns
      ##
      ## transposed display  , needs full terminal width , precision set to 2
      ##
      var ohSet = @[z.ro[0],z.rh[0],z.rl[0],z.rc[0],z.rv[0],z.rca[0]]
      var headerset = @["Open","High","Low","Close","Volume","Adj Close"]
      decho(1)
      printLn(fmtx(["<11",">14",">14",">14",">14",">14",">14"],"Item","sum","variance","mean","stddev","max","min"))
      for x in 0.. <ohSet.len:
          printLn(fmtx(["<11",">14",">14",">14",">14",">14",">14"],headerset[x],ff(ohSet[x].sum,2),ff(ohSet[x].variance,2),ff(ohSet[x].mean,2),
          ff(ohSet[x].standardDeviation,2),ff(ohSet[x].max,2),ff(ohSet[x].min,2)))
      decho(2)


# emaflag = false meaning all ok
# if true some problem to indicate to following calcs not to proceed

var emaflag : bool = false

proc calculateEMA(todaysPrice : float , numberOfDays: int , EMAYesterday : float) : float =
   ## supporting proc for ema calculation, not callable
   ##
   var k = 2 / (float(numberOfDays) + 1.0)
   var ce = (todaysPrice * k) + (EMAYesterday * (1.0 - k))
   result = ce

proc ema* (dx : Stocks , N: int = 14) : Ts =
    ## ema
    ##
    ## exponential moving average based on close price
    ##
    ## returns a Ts object loaded with date,ema pairs
    ##
    ## calling with Stocks object and number of days for moving average default = 14
    ##
    ## results match R quantmod/TTR
    ##

    ## we need at least 5 * N > 100 days of data or ema will be skewed or invalid
    ##
    ## EMA = Price(t) * k + EMA(y) * (1 – k)
    ##
    # t = today, y = yesterday, N = number of days in EMA, k = 2/(N+1)

    var m_emaSeries : Ts # we use our Ts object to hold a series of dates and ema
    m_emaSeries.dd = @[]
    m_emaSeries.tx = @[]
    if dx.close.len < ( 5 * N):
       emaflag = true
       printLn(dx.stock & ": Insufficient data for ema calculation, need min. $1 data points" % $(5 * N),red)

    else:

      # lets calc the first ema by hand as per
      # http://www.iexplain.org/ema-how-to-calculate/
      # note that our list is upside down so the first is actually the bottom in our list
      #
      var nk = 2/(N + 1)
      var ns = 0.0
      for x in countdown(dx.close.len-1,dx.close.len-N,1):  # we count down coz first in is at bottom
          ns = ns + dx.close[x]

      ns = ns / float(N)
      ns = ns * (1 - nk)
      # now we need the next closing
      var ms = dx.close[dx.close.len - (N + 1)]
      ms = ms * nk
      var yesterdayEMA = ms + ns   # at this stage we have a first ema which will be used for yday

      for x in countdown(dx.close.len-1,0,1):  # ok but we get the result in reverse
          # call the EMA calculation
          var aema = calculateEMA(dx.close[x], N, yesterdayEMA)
          # put the calculated ema into our Ts object
          m_emaSeries.dd.add(dx.date[x])
          m_emaSeries.tx.add(aema)
          # make sure yesterdayEMA gets filled with the EMA we used this time around
          yesterdayEMA = aema


    result = m_emaSeries


proc showEma* (emx:Ts , n:int = 5,ty:string = head,xpos:int = 1) =
   ## showEma
   ##
   ## convenience proc to display ema series with dates
   ##
   ## input is a ema series Ts object and rows to display and N number of rows to display default = 5
   ##
   ## ty parameter enables head,tail or all data to be shown
   ## 
   ## note that data shown is in descending order , this may or may not change in the future
   ##
   echo()
   printLn(fmtx(["<11","",">11"],"Date",spaces(1),"EMA"),yellowgreen,xpos = xpos)
   if emx.dd.len > 0:
       case ty 
        of head :  
          for x in countdown(emx.dd.len - 1,emx.dd.len - n,1) :  
              printLn(fmtx(["<11","",">11"],emx.dd[x],spaces(1),ff2(emx.tx[x],6)),xpos = xpos)

        of tail :
           for x in countdown(n - 1,0,1) :  
              printLn(fmtx(["<11","",">11"],emx.dd[x],spaces(1),ff2(emx.tx[x],6)),xpos = xpos)
        
        of all :
           for x in countdown(emx.dd.len - 1,0,1) :  
              printLn(fmtx(["<11","",">11"],emx.dd[x],spaces(1),ff2(emx.tx[x],6)),xpos = xpos)

          
        else : discard  

proc getCurrentForex*(curs:openarray[string],xpos:int = 1):Currencies =
  ## getCurrentForex
  ##
  ## get the latest yahoo exchange rate info for a currency pair
  ##
  ## e.g EURUSD , JPYUSD ,GBPHKD
  ##
  ## .. code-block:: nim
  ##    var curs = getCurrentForex(@["EURUSD","EURHKD"])
  ##    echo()
  ##    printLn("Current EURUSD Rate : ",fmtx(["<8"],curs.ra[0]))
  ##    printLn("Current EURHKD Rate : ",fmtx(["<8"].curs.ra[1]))
  ##    echo()
  ##

  # currently using cvs data url
  # this version does not need temp file as we parse cvs as text file directly
  
  try:
          var aurl = "http://finance.yahoo.com/d/quotes.csv?e=.csv&f=c4l1&s="    #  EURUSD=X,GBPUSD=X
          for ac in curs:
             aurl = aurl & ac & "=X,"

          var cc = 0
          # init a Currencies object to hold forex data
          var rf = initCurrencies()
          let zcli = newHttpClient()
          var zs = splitlines(unquote(zcli.getcontent(aurl)))  # get data
          var c = 0
          for zl in zs:
              
              var x = split(zl,",")
              c = 0 # counter to assign item to correct var
              for val in x:
                       c += 1
                       case c
                        of 1:
                             if val == "N/A":  # that is we do not get the currency like HKD from EURHKD
                                 var acur = curs[cc][3..6]
                                 rf.cu.add(acur)
                             else:    
                                 rf.cu.add(val)
                        of 2:
                             if val == "N/A":
                                rf.ra.add(0.00)
                             else:
                               rf.ra.add(parseFloat(val))
                        else:
                             printLn("Csv currency data in unexpected format ",truetomato,xpos = xpos)
              inc cc
          
          result = rf
          
  except HttpRequestError:
          printLn("Forex Data temporary unavailable" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
  except ValueError:
          discard
  except OSError:
          discard
  except OverflowError:
          discard
  except  TimeoutError:
         printLn("TimeoutError: " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
  except  ProtocolError:
         printLn("Protocol Error" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
  except :
         discard
  finally:
        discard  

 
 


proc showCurrentForex*(curs : openarray[string],xpos:int = 1) =
       ## showCurrentForex
       ##
       ## a convenience proc to display exchange rates with positioning
       ## 
       ## see note of yahoo outages in getcurrentForex
       ##
       ## .. code-block:: nim
       ##    showCurrentForex(["EURUSD","GBPHKD","CADEUR","AUDNZD"],xpos = 10)
       ##    decho(3)
       ##
       ## .. code-block:: nim
       ##    import cx,nimFinLib
       ##    var curs = ["EURUSD","GBPHKD","CADEUR","AUDNZD","USDCNY","GBPCNY","JPYHKD"]
       ##    var cursl = curs.len
       ##    showCurrentForex(curs,xpos = 5)
       ##    curup(cursl + 2)
       ##    drawbox(cursl + 2,38,1,2,xpos = 3)
       ##    decho(cursl + 5)
       ##    doFinish()
       ##           
       var cx = getcurrentForex(curs) # we get a Currencies object back
       printLn(fmtx(["<14","<4","",">6"],"Currencies","Cur",spaces(1),"Rate"),lime,xpos = xpos)
       for x in 0.. <cx.cu.len:
            printLn(fmtx(["<14","<4","",">8.4f"],curs[x],cx.cu[x],spaces(1),cx.ra[x]),xpos = xpos)


proc showStocksTable*(apfdata: Portfolio,xpos:int = 1) =
   ## showStocksTable
   ##
   ## a convenience prog to display the data part of a Portfolio object
   ##
   ## for usage example see nimFinT3
   ##

   var astkdata = apfdata.dx

   decho(2)
   # header for the table
   printLn(fmtx(["<8",">9",">9",">9",">9",">13",">10",">9",">9",">9",">9"],"Code","Open","High","Low","Close","Volume","AdjClose","StDevHi","StDevLo","StDevCl","StDevClA"),yellowgreen)
   for x in 0.. <astkdata.len:
       var sx = astkdata[x] # just for less writing ...
       # display the data rows
       try:
          printLn(fmtx(["<8",">9.3f",">9.3f",">9.3f",">9.3f",">13",">10.3f",">9.3f",">9.3f",">9.3f",">9.3f"],sx.stock,sx.open.seqlast,sx.high.seqlast,sx.low.seqlast,sx.close.seqlast,int(sx.vol.seqlast),sx.adjc.seqlast,
          sx.rh[0].standardDeviation,sx.rl[0].standardDeviation,sx.rc[0].standardDeviation,sx.rca[0].standardDeviation))
       except:
          printLn(sx.stock & " data errors ",red)
   echo()
   printLn(" NOTE : stdDevOpen and stdDevVol are not shown but available",peru)
   decho(2)


proc showStockdataTable*(a:Stockdata) =
      ## showStockdatatable
      ##
      ## shows all items of a Stockdata object
      ##
      printLn(fmtx(["<17","",">12"],"Price"," : ",a.price))
      printLn(fmtx(["<17","",">12"],"Change"," : ",a.change))
      printLn(fmtx(["<17","",">12"],"Volume"," : ",a.volume))
      printLn(fmtx(["<17","",">12"],"Avg.DailyVolume"," : ",a.avgdailyvol))
      printLn(fmtx(["<17","",">12"],"Market"," : ",a.market))
      printLn(fmtx(["<17","",">12"],"MarketCap"," : ",a.marketcap))
      printLn(fmtx(["<17","",">12"],"BookValue"," : ",a.bookvalue))
      printLn(fmtx(["<17","",">12"],"Ebitda"," : ",a.ebitda))
      printLn(fmtx(["<17","",">12"],"DividendPerShare"," : ",a.dividendpershare))
      printLn(fmtx(["<17","",">12"],"DividendPerYield"," : ",a.dividendperyield))
      printLn(fmtx(["<17","",">12"],"EarningsPerShare"," : ",a.earningspershare))
      printLn(fmtx(["<17","",">12"],"52 Week High"," : ",a.week52high))
      printLn(fmtx(["<17","",">12"],"52 Week Low"," : ",a.week52low))
      printLn(fmtx(["<17","",">12"],"50 Day Mov. Avg"," : ",ff(a.movingavg50day,2)))
      printLn(fmtx(["<17","",">12"],"200 Day Mov. Avg"," : ",ff(a.movingavg200day,2)))
      printLn(fmtx(["<17","",">12"],"P/E"," : ",ff(a.priceearingratio,2)))
      printLn(fmtx(["<17","",">12"],"P/E Growth Ratio"," : ",ff(a.priceearninggrowthratio,2)))
      printLn(fmtx(["<17","",">12"],"Price Sales Ratio"," : ",ff(a.pricesalesratio,2)))
      printLn(fmtx(["<17","",">12"],"Price Book Ratio"," : ",ff(a.pricebookratio,2)))
      printLn(fmtx(["<17","",">12"],"Price Short Ratio"," : ",ff(a.shortratio,2)))
      decho(2)

template metal(dc:int):typed =
    ## metal
    ## 
    ## utility template to display Kitco metal data
    ## 
    ## used by showKitcoMetal
    ## 
    
    if ktd[x].startswith(dl) == true:
      printLn(ktd[x],yellowgreen,xpos = xpos - 2 )
      
    elif find(ktd[x],"Asia / Europe") > 0:
       print(strip(ktd[x],true,true),cx.white,xpos = xpos)
        
    elif find(ktd[x],"New York") > 0:
       print(strip(ktd[x],true,true),cx.white,xpos = xpos)
    
    elif find(ktd[x],opn) > 0 :
        printLn(spaces(10) & "MARKET IS OPEN",lime)
              
    elif find(ktd[x],cls) > 0:
        printLn(spaces(10) & "MARKET IS CLOSED",truetomato)
              
    elif find(ktd[x],"Update") > 0:
        printLn(ktd[x] & " New York Time",yellowgreen,xpos = xpos - 2)                    

    else:
           
          if dc < 36:
               try:
                 var ks = ktd[x].split(" ")
                 if ktd[x].contains("Metals") == true:
                    printLn(ktd[x],cx.white,xpos = xpos - 1)
                 else: 
                    
                    kss = @[]
                    if ks.len > 0:
                      for x in 0.. <ks.len:
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
                  printLn("All Metal Markets Closed or Data outdated/unavailable",truetomato,xpos = xpos)
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
                  for x in 0.. <ktd.len - 18: 
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

# procs for future use

proc logisticf* (z:float):float =
     ## logisticf
     ##
     ## maps the input z to an output between 0 and 1
     ##
     # good for smaller numbers -10 .. 10
     var lf:float = 1 / (1 + pow(E,-z))
     result = lf


proc logisticf_derivative* (z:float): float =
     ## logisticf_derivative
     ##
     ## returns derivative of logisticf for gradient solutions
     ##
     result = logisticf(z) * (1 - logisticf(z))





#------------------------------------------------------------------------------------------
# End of nimFinLib
#------------------------------------------------------------------------------------------
