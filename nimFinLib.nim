
##
## Program     : nimFinLib
##
## Status      : Development
##
## License     : MIT opensource
##
## Version     : 0.2.6.3
##
## Compiler    : nim 0.13.1
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
##               Yahoo market indexes
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
##               Documention was created with : nim doc nimFinLib
##
##
## Notes       : nimFinlib is being developed utilizing cx.nim module
##               to improve coloring of data and positioning of output.
##               Terminals tested : bash,xterm,st.
##
##
## Project     : https://github.com/qqtop/NimFinLib
##
## Tested on   : Linux
##
## ProjectStart: 2015-06-05 / 2015-11-21
##
## ToDo        : Ratios , Covariance , Correlation
##               improve timeout exception handling if yahoo data fails to be retrieved
##               or is temporary unavailable for certain markets
##
## Programming : qqTop
##
## Contributors: reactorMonk
##
## Requires    : strfmt,random modules , statistics.nim and cx.nim
##
##               get cx.nim like so
##               
##               git clone https://github.com/qqtop/NimCx.git
##               
##               then copy cx.nim into your dev directory or path
##
##
##
## Notes       : it is assumed that terminal color is black background
##
##               and white text. Other color schemes may not show all output.
##               
##               also read notes about terminal compability in cx.nim
##               
##               Best results with terminals supporting truecolor.
##
## Tests       : For comprehensive tests and example usage see nfT52.nim and minifin.nim
## 
##
## Installation: git clone https://github.com/qqtop/NimFinLib.git
##
## or
##
## nimble install nimFinLib
##
##

import os,cx,strutils,parseutils,sequtils,httpclient,net,strfmt
import terminal,times,tables,random, parsecsv,streams,algorithm,math,unicode
import stats  #,statistics

let NIMFINLIBVERSION* = "0.2.6.3"

let yahoourl* = "http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm"


type

  Account*  = object
        ## Account type
        ## holds all portfolios similar to a master account
        ## portfolios are Portfolio objects
        pf* : seq[Portfolio]  ## pf holds all Portfolio type portfolios for an account



  Portfolio* {.inheritable.} = object
        ## Portfolio type
        ## holds one portfolio with all relevant historic stocks data
        nx* : string   ## nx  holds portfolio name  e.g. MyGetRichPortfolio
        dx* : seq[Stocks]  ## dx  holds all stocks with historical data



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
       ## column of any OHLCVA data

       dd* : seq[string]  # date
       tx* : seq[float]   # data


  Currencies* {.inheritable.} = object
       ## Currencies type
       ## a simple object to hold current currency data

       cu* : seq[string]  # currency code pair e.g. EURUSD
       ra* : seq[float]   # relevant rate  e.g 1.354



type 
 
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
     return ts


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
   ##     # show adj. close price , 5 rows head and tail 372 days apart
   ##     var myD =initStocks()
   ##     myD = getSymbol2("AAPL",minusdays(getDateStr(),372),getDateStr())
   ##     var mydT = timeseries(myD,"a") # adjusted close
   ##     echo()
   ##     showTimeSeries(mydT,"AdjClose","head",5)
   ##     showTimeSeries(mydT,"AdjClose","tail",5)
   ##


   printLn("{:<11} {:>11} ".fmt("Date",header),fgr)
   if ats.dd.len > 0:
        if ty == "all":
            for x in 0.. <ats.tx.len:
                echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])
        elif ty == "tail":
            for x in ats.tx.len-N.. <ats.tx.len:
                echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])
        elif ty == "head":
            for x in 0.. <N:
                echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])
        else:
            ## head is the default in case an empty ty string was passed in
            for x in 0.. <N:
                echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])


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

proc initTs*():Ts=
     ## initTs
     ##
     ## init a timeseries object
     var ats : Ts
     ats.dd = @[]
     ats.tx = @[]
     result = ats

proc initPool*():seq[Stocks] =
  ## initPool
  ##
  ## init pools , which are sequences of Stocks objects used in portfolio building
  ##
  ## .. code-block:: nim
  ##    var mystockPool = initPool()
  ##

  var apool = newSeq[Stocks]()
  apool = @[]
  result  = apool

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
   #var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
   var data = newSeq[string]()
   var line = getContent(aurl)
   data = line[1..line.high].split(",")
   #echo "DATA -> : ",data
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
       let zz = splitLines(getContent(aurl,timeout = 5000))
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
    var ci = getContent(aurl,timeout = 5000)
    for line in ci.splitLines:
      var data = line[1..line.high].split(",")
      # even if yahoo servers are down our data.len is still 1 so
      if data.len > 1:
              printLn("Code : {:<10} Name : {}  Market : {}".fmt(unquote(data[0]),unquote(data[1]),unquote(data[2])),yellowgreen,xpos = xpos)
              printLn("Date : {:<12}{:<9}    Price  : {:<8} Volume : {:>12}".fmt(unquote(data[4]),unquote(data[5]),data[3],data[8]),white,xpos = xpos)
              var cc = checkchange(unquote(data[9]))
              if cc == -1:
                    printLn("Open : {:<8} High : {:<8} Change :{}{}{}{} Range : {}".fmt(data[6],data[7],red,showRune("FFEC"),white,unquote(data[9]),unquote(data[10])),white,xpos = xpos)
              elif cc == 0:
                    printLn("Open : {:<8} High : {:<8} Change : {}{} Range : {}".fmt(data[6],data[7]," ",unquote(data[9]),unquote(data[10])),white,xpos = xpos)
       
              else :  # up
                    printLn("Open : {:<8} High : {:<8} Change :{}{}{}{} Range : {}".fmt(data[6],data[7],lime,showRune("FFEA"),white,unquote(data[9]),unquote(data[10])),white,xpos = xpos)
       
       
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
    var ci = getContent(aurl)
    for line in ci.splitLines:
      var data = line[1..line.high].split(",")
      if data.len > 1:
              var cc = checkChange(unquote(data[9]))
             
              case cc
                  of -1 : 
                          printLn("{}{:>7} {}{:<9}  {}{:>7} {}{:<16} {}{:>7} {}{:<6} {}{:<7} {}{:<10}{} {:<8} {}{:>9} {}{}{}{}".fmt(yellowgreen,"Code : ",peru,unquote(data[0]),yellowgreen , "Name : ",peru , unquote(data[1]),yellowgreen , "Market : ",peru , unquote(data[2]),yellowgreen , "Date : ",peru , unquote(data[4]),peru , unquote(data[5]),yellowgreen , "Index : ",red , showRune("FFEC"),lightskyblue , unquote(data[3])))
                          printLn("{}Open : {}{:<8}  {}Change : {}{:<2}{}{:>10}  {}Range : {}{} ".fmt(yellowgreen,white,unquote(data[6]),yellowgreen,red , showRune("FFEC") ,white , unquote(data[9]),yellowgreen,white,unquote(data[10])))            
                  of  0 : 
                          printLn("{}{:>7} {}{:<9}  {}{:>7} {}{:<16} {}{:>7} {}{:<6} {}{:<7} {}{:<10}{} {:<8} {}{:>9} {}{}{}{}".fmt(yellowgreen,"Code : ",peru,unquote(data[0]),yellowgreen , "Name : ",peru , unquote(data[1]),yellowgreen , "Market : ",peru , unquote(data[2]),yellowgreen , "Date : ",peru , unquote(data[4]),peru , unquote(data[5]),yellowgreen , "Index : ",white, " ",lightskyblue , unquote(data[3])))
                          printLn("{}Open : {}{:<8}  {}Change : {}{:<2}{}{:>10}  {}Range : {}{} ".fmt(yellowgreen,white,unquote(data[6]),yellowgreen,white," "              ,white , unquote(data[9]),yellowgreen,white,unquote(data[10])))             
                  of  1 : 
                          printLn("{}{:>7} {}{:<9}  {}{:>7} {}{:<16} {}{:>7} {}{:<6} {}{:<7} {}{:<10}{} {:<8} {}{:>9} {}{}{}{}".fmt(yellowgreen,"Code : ",peru,unquote(data[0]),yellowgreen , "Name : ",peru , unquote(data[1]),yellowgreen , "Market : ",peru , unquote(data[2]),yellowgreen , "Date : ",peru , unquote(data[4]),peru , unquote(data[5]),yellowgreen , "Index : ",lime , showRune("FFEA"),lightskyblue , unquote(data[3])))
                          printLn("{}Open : {}{:<8}  {}Change : {}{:<2}{}{:>10}  {}Range : {}{} ".fmt(yellowgreen,white,unquote(data[6]),yellowgreen,lime ,showRune("FFEA") ,white , unquote(data[9]),yellowgreen,white,unquote(data[10])))
                    
                  else  : printLn("Data Error",red)
                          
              echo repeat("-",tw)
      else:
              if data.len == 1 and sflag == false:
                 msgr() do : echo "Yahoo server maybe unavailable. Try again later"
                 sflag = true
  except HttpRequestError:
      msgr() do : echo "Yahoo current data could not be retrieved . Try again ."
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
              println("Yahoo returned insufficient data for $1",red % $ss[x],xpos = xpos)   
              
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
        printlnBiCol("Code      : " & x.stcode)
        printlnBiCol("Name      : " & x.stname)
        printlnBiCol("Market    : " & x.stmarket)
        printlnBiCol("Price     : " & x.stprice)
        printlnBiCol("Date/Time : " & "{} {}".fmt(x.stdate,x.sttime))
        printlnBiCol("Open      : " & x.stopen)
        printlnBiCol("High      : " & x.sthigh)
        printlnBiCol("Volume    : " & x.stVolume)
        printlnBiCol("Change    : " & x.stchange)
        printlnBiCol("Range     : " & x.strange)    
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
      var ci = getContent(aurl)
      for line in ci.splitLines:
        var data = line[1..line.high].split(",")
        if data.len > 1:
                printBiCol("Code : {:<10}  ".fmt(unquote(data[0])),":",salmon,cyan,xpos = xpos)
                printLnBiCol("Index : {}".fmt(unquote(data[1])),":",salmon,cyan)
                curdn(1)                      
                printLnBiCol("Exch : {:<30}".fmt(unquote(data[2])),":",yellowgreen,goldenrod,xpos = xpos)                   
                curdn(1)
                printLnBiCol("Date : {:<12}{:<9}    ".fmt(unquote(data[4]),unquote(data[5])),":",xpos = xpos)
                curup(1) 
                var cc = checkChange(unquote(data[9]))
                
                var slmdis = 57 - 2       # used for fine alignment of slim number xpos
                var chgdis = slmdis + 2   # used for fine alignment of change data xpos
                case cc
                  of -1 : 
                          print(showRune("FFEC"),red,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],truetomato,xpos = xpos + slmdis,align = "right")
                          print("Change",red,xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[0],xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[1],xpos = chgdis)                 
                          curdn(3)
                  of  0 :
                          curup(1) 
                          printSlim(data[3],steelblue,xpos = xpos + slmdis,align = "right")  
                          print("Change",white,xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[0],xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[1],xpos = chgdis)
                          curdn(3)
                  of  1 : 
                          print(showRune("FFEA"),lime,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],lime,xpos = xpos + slmdis ,align = "right")         
                          print("Change",yellowgreen,xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[0],xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[1],xpos = chgdis)
                          curdn(3)
                  else  : 
                          print("Error",red,xpos = xpos + 31)              
                
                curup(1)
                printLnBiCol("Range: {}".fmt(unquote(data[10])),":",xpos = xpos)
                
                printBiCol("Open : {:<8} ".fmt(data[6]),":",xpos = xpos)     
                
                if unquote(data[8]) == "0":
                    printBiCol("  {}".fmt("Vol   : N/A"),":",xpos = xpos + 17)
                else:
                    printBiCol("  {}".fmt("Vol   : " & unquote(data[8])),":",xpos = xpos + 17)               
                printLn("Yahoo Finance Data",brightblack,xpos = slmdis - 10)
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
         println("TimeoutError: " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except  ProtocolError:
          println("Protocol Error" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
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
   var qurl=yahoourl  % idxs
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
    ##     showCurrentIDX("^HSI+^GDAXI+^FTSE+^NYA",xpos = 5)
    ## xpos allows x positioning
    #
    var qurl=yahoourl  % idxs
    currentIndexes(qurl,xpos = xpos)


proc showCurrentIDX*(adf:seq[Stocks],xpos:int = 1){.discardable.} =
   ## showCurrentIDX
   ##
   ## callable display routine for currentIndexes with a pool object passed in
   ## 
   ## compact view
   ##
   var idxs = buildStockString(adf)
   #hdx(echo "Index Data for a pool" )
   var qurl=yahoourl  % idxs
   currentIDX(qurl,xpos = xpos)



proc showCurrentIDX*(idxs:string,xpos:int = 1){.discardable.} =
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
    var qurl=yahoourl  % idxs
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
      var ci = getContent(aurl)
      for line in ci.splitLines:
        var data = line[1..line.high].split(",")
        if data.len > 1:
                printBiCol  ("Code : {:<9} ".fmt(unquote(data[0])),":",lightskyblue,cyan,xpos = xpos)
                printLnBiCol("   Name : {:<36} ".fmt(unquote(data[1])),":",lightskyblue,pastelyellowgreen)
                printLnBiCol("Exch : {} ".fmt(unquote(data[2])),":",yellowgreen,goldenrod,xpos = xpos)
                curdn(1)
                printLnBiCol("Date : {:<12}{:<9}    ".fmt(unquote(data[4]),unquote(data[5])),":",xpos = xpos)
                curup(1) 
                var cc = checkChange(unquote(data[9]))
                
                var slmdis = 57 - 2       # used for fine alignment of slim number xpos
                var chgdis = slmdis + 2   # used for fine alignment of change data xpos
                case cc
                  of -1 : 
                          print(showRune("FFEC"),red,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],truetomato,xpos = xpos + slmdis,align = "right")
                          print("Change",red,xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[0],xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[1],xpos = chgdis)                 
                          curdn(3)
                  of  0 :
                          curup(1) 
                          printSlim(data[3],steelblue,xpos = xpos + slmdis,align = "right")  
                          print("Change",white,xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[0],xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[1],xpos = chgdis)
                          curdn(3)
                  of  1 : 
                          print(showRune("FFEA"),lime,xpos = xpos + 31)
                          curup(1)
                          printSlim(data[3],lime,xpos = xpos + slmdis ,align = "right")         
                          print("Change",yellowgreen,xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[0],xpos = chgdis)
                          curdn(1)
                          print(split(unquote(data[9])," - ")[1],xpos = chgdis)
                          curdn(3)
                  else  : 
                          print("Error",red,xpos = xpos + 31)              
                
                curup(1)
                printLnBiCol("Range: {}".fmt(unquote(data[10])),":",xpos = xpos)
                
                printBiCol("Open : {:<8} ".fmt(data[6]),":",xpos = xpos)     
                          
                printBiCol("{}".fmt("   Vol  : " & unquote(data[8])),":",xpos = xpos + 17)               
                printLn("Yahoo Finance Data",brightblack,xpos = slmdis - 10)
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
         println("TimeoutError: " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except  ProtocolError:
         println("Protocol Error" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except :
         discard
    finally:
        discard  


proc showCurrentStocks*(apf:Portfolio,xpos:int = 1){.discardable.} =
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
   hdx(echo "Stocks Current Quote for $1" % apf.nx)
   var qurl=yahoourl  % stcks
   currentStocks(qurl,xpos = xpos)



proc showCurrentStocks*(stcks:string,xpos:int = 1){.discardable.} =
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

   hdx(echo "Stocks Current Quote")
   var qurl=yahoourl  % stcks
   currentStocks(qurl,xpos = xpos)


proc showCurrentSTX*(apf:Portfolio,xpos:int = 1){.discardable.} =
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
   hdx(echo "Stocks Current Quote for $1" % apf.nx)
   var qurl=yahoourl  % stcks
   currentSTX(qurl,xpos = xpos)



proc showCurrentSTX*(stcks:string,xpos:int = 1){.discardable.} =
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

   hdx(println("Stocks Quote ",yellowgreen,termblack),width = 64)
   var qurl=yahoourl  % stcks
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



proc getSymbol2*(symb,startDate,endDate : string) : Stocks =
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

    if validdate(startDate) and validdate(endDate):

          stdout.write("{:<15}".fmt("Processing   : "))
          msgg() do: stdout.write("{:<8} ".fmt(symb))
          stdout.write("{:<11} {:<11}".fmt(startDate,endDate))
          # end feedback line

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

          # note to dates for this yahoo url according to latest research
          # a=04  means may  a=00 means jan start month
          # b = start day
          # c = start year
          # d = end month  05 means jun
          # e = end day
          # f = end year
          # we use the csv string , yahoo json format only returns limited data 1.5 years or less
          # this url worked until 2015-09-21
          #var qurl = "http://real-chart.finance.yahoo.com/table.csv?s=$1&a=$2&b=$3&c=$4&d=$5&e=$6&f=$7&g=d&ignore=.csv" % [symb,sdm,sdd,sdy,edm,edd,edy]
          # current historical data url
          var qurl = "http://ichart.finance.yahoo.com/table.csv?s=$1&a=$2&b=$3&c=$4&d=$5&e=$6&f=$7&g=d&ignore=.csv" % [symb,sdm,sdd,sdy,edm,edd,edy]

          var headerset = [symb,"Date","Open","High","Low","Close","Volume","Adj Close"]
          var c = 0
          var hflag  : bool # used for testing maybe removed later
          var astock = initStocks()   # this will hold our result history data for one stock

          # naming outputfile nimfintmp.csv as many stock symbols have dots like 0001.HK
          # could also be done to be in memory like /shm/  this file will be auto removed.

          var acvsfile = "nimfintmp.csv"
          try:
            downloadFile(qurl,acvsfile)
          except HttpRequestError:
            echo()
            msgr() do : echo "Error : Yahoo currently does not provide historical data for " & symb

          var s = newFileStream(acvsfile, fmRead)
          if s == nil:
             # in case of problems with the yahoo csv file we show a message
             msgr() do : echo "Error : Data file for $1 could not be opened " % symb

          # now parse the csv file
          var x: CsvParser
          open(x, s , acvsfile, separator=',')
          while readRow(x):
            # a way to get the actual csv header , but here we use our custom headerset with more info
            # if validIdentifier(x.row[0]):
            #  header = x.row
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
                          volx = parseFloat(val)
                          volumeRC.push(volx)
                          voldf.add(volx)

                    of 7:
                          adjclosx = parseFloat(val)
                          closeRCA.push(adjclosx)  ## RunningStat for adj close price
                          adjclosdf.add(adjclosx)

                    else :
                          msgr() do : echo "Csv Data in unexpected format for Stocks :",symb

          # feedbacklines can be commented out
          msgc() do:
                    stdout.writeln(" --> Rows processed : ",processedRows(x))


          # close CsvParser
          close(x)

          # put the collected data into Stocks type
          astock.stock = symb
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
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc getSymbol2"
          result = initStocks() # return an empty df


proc getSymbol3*(symb:string):Stockdata =
     ## getSymbol3
     ##
     ## additional data as provided by yahoo for a stock
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

     var qz : Stockdata
     var stx = "l1c1va2xj1b4j4dyekjm3m4rr5p5p6s7"
     var qurl = "http://finance.yahoo.com/d/quotes.csv?s=$1&f=$2" % [symb, stx]
     var rx = getcontent(qurl)
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
    msgg() do: echo "{:<8}{:<11}{:>10}{:>10}{:>10}{:>10}{:>14}{:>10}".fmt("Code","Date","Open","High","Low","Close","Volume","AdjClose")
    if n >= adf.date.len:
      for x in 0.. <adf.date.len:
        echo "{:<8}{:<11}{:>10}{:>10}{:>10}{:>10}{:>14}{:>10}".fmt(adf.stock,adf.date[x],adf.open[x],adf.high[x],adf.low[x],adf.close[x],adf.vol[x],adf.adjc[x])
    else:
      for x in 0.. <n:
        echo "{:<8}{:<11}{:>10}{:>10}{:>10}{:>10}{:>14}{:>10}".fmt(adf.stock,adf.date[x],adf.open[x],adf.high[x],adf.low[x],adf.close[x],adf.vol[x],adf.adjc[x])
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
    msgg() do: echo "{:<8}{:<11}{:>10}{:>10}{:>10}{:>10}{:>14}{:>10}".fmt("Code","Date","Open","High","Low","Close","Volume","AdjClose")
    for x in 0.. <adf.date.len:

      var c1 = compareDates(adf.date[x],s)
      var c2 = compareDates(adf.date[x],e)
      if c1 == 1 or c1 == 0:
          if c2 == 2  or c2 == 0:
             echo "{:<8}{:<11}{:>10}{:>10}{:>10}{:>10}{:>14}{:>10}".fmt(adf.stock,adf.date[x],adf.open[x],adf.high[x],adf.low[x],adf.close[x],adf.vol[x],adf.adjc[x])
    decho(2)


proc last*[T](self : seq[T]): T =
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


proc first*[T](self : seq[T]): T =
    ## first means oldest row
    ##
    try:
      result = self[self.high]
    except IndexError:
      discard

proc tail*[T](self : seq[T] , n: int) : seq[T] =
    ## tail means most recent rows
    ##
    try:
        if len(self) >= n:
            result = self[0.. <n]
        else:
            result = self[0.. <len(self)]
    except RangeError:
       discard


proc head*[T](self : seq[T] , n: int) : seq[T] =
    ## head means oldest rows
    ##
    var self2 = reversed(self)
    try:
        if len(self2) >= n:
            result = self2[0.. <n].tail(n)
        else:
            result = self2[0.. <len(self2)].tail(n)
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
          msgg() do: echo "{:<8} {:<11} {:>14}".fmt("Code","Date","Returns")
          # show limited rows output if c<>0
          if N == 0:
              for  x in 0.. <dfr.len:
                      echo "{:<8}{:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])


          else:
              for  x in 0.. <N:
                      echo "{:<8}{:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])


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
            msgg() do: echo "{:<8} {:<11} {:>14}".fmt("Code","Date","Returns")
            # show limited output if c<>0
            if N == 0:
              for  x in 0.. <dfr.len:
                  echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])
            else:
              for  x in 0.. <N:
                  echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])


proc sumDailyReturnsCl*(self:Stocks) : float =
      ## sumdailyReturnsCl
      ##
      ## returns sum based on close price
      ##
      # returns a sum of dailyreturns but is off from quantmod more than expected why ?
      # the len of seq roughly the same of by 1-2 vals as expected but
      # the sum is of by too much , maybe it is in the missing values
      var dR = self.close.dailyReturns
      var sumdfr = sum(dR)
      # feedback line can be commented out
      msgy() do: echo "Returns on Close Price calculated : ", dR.len
      result = sumdfr


proc sumDailyReturnsAdCl*(self:Stocks) : float =
      ## sumdailyReturnsAdCl
      ##
      ## returns sum based on adjc
      ##
      # returns a sum of dailyreturns but is off from quantmod more than expected why ?
      # the len of seq roughly the same of by 1-2 vals as expected but
      # the sum is of by too much , maybe it is in the missing values
      var dR = self.adjc.dailyReturns
      var sumdfr = sum(dR)
      # feedback line can be commented out
      msgy() do: echo "Returns on Close Price calculated : ", dR.len
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
      msgg() do: echo "{:<11}{:>11}{:>11}{:>11}{:>11}{:>14}{:>11}".fmt("Item","Open","High","Low","Close","Volume","Adj Close")
      echo "{:<11}{:>11}{:>11}{:>11}{:>11}{:>14}{:>11}".fmt(itemset[0],z1[0],z1[1],z1[2],z1[3],z1[4],z1[5])
      echo "{:<11}{:>11}{:>11}{:>11}{:>11}{:>14}{:>11}".fmt(itemset[1],z2[0],z2[1],z2[2],z2[3],z2[4],z2[5])
      echo "{:<11}{:>11}{:>11}{:>11}{:>11}{:>14}{:>11}".fmt(itemset[2],z3[0],z3[1],z3[2],z3[3],z3[4],z3[5])
      echo "{:<11}{:>11}{:>11}{:>11}{:>11}{:>14}{:>11}".fmt(itemset[3],z4[0],z4[1],z4[2],z4[3],z4[4],z4[5])
      echo "{:<11}{:>11}{:>11}{:>11}{:>11}{:>14}{:>11}".fmt(itemset[4],z5[0],z5[1],z5[2],z5[3],z5[4],z5[5])
      echo "{:<11}{:>11}{:>11}{:>11}{:>11}{:>14}{:>11}".fmt(itemset[5],z6[0],z6[1],z6[2],z6[3],z6[4],z6[5])
      decho(2)


proc showStatisticsT*(z : Stocks) =
      ## showStatisticsT
      ##
      ## shows all statistics from a Stocks objects ohlcva columns
      ##
      ## transposed display  , needs full terminal width
      ##
      var ohSet = @[z.ro[0],z.rh[0],z.rl[0],z.rc[0],z.rv[0],z.rca[0]]
      var headerset = @["Open","High","Low","Close","Volume","Adj Close"]

      decho(1)
      msgg() do: echo "{:<11}{:>14}{:>14}{:>14}{:>14}{:>14}{:>14}".fmt("Item","sum","variance","mean","stddev","max","min")
      for x in 0.. <ohSet.len:
          echo "{:<11}{:>14}{:>14}{:>14}{:>14}{:>14}{:>14}".fmt(headerset[x],ohSet[x].sum,ohSet[x].variance,ohSet[x].mean,
          ohSet[x].standardDeviation,ohSet[x].max,ohSet[x].min)
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
       msgr() do : echo dx.stock,": Insufficient data for valid ema calculation, need min. $1 data points" % $(5 * N)

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


proc showEma* (emx:Ts , N:int = 5) =
   ## showEma
   ##
   ## convenience proc to display ema series with dates
   ##
   ## input is a ema series Ts object and rows to display and N number of rows to display default = 5
   ##
   ## latest data is on top
   ##
   echo()
   msgg() do : echo "{:<11} {:>11} ".fmt("Date","EMA")
   if emx.dd.len > 0:
       for x in countdown(emx.dd.len-1,emx.dd.len-N,1) :
          echo "{:<11} {:>11} ".fmt(emx.dd[x],emx.tx[x])


# 
# proc getCurrentForex*(curs:seq[string],xpos:int = 1):Currencies =
#   ## getCurrentForex     deprecated version which uses parsecsv and a tempfile
#   ##
#   ## get the latest yahoo exchange rate info for a currency pair
#   ##
#   ## e.g EURUSD , JPYUSD ,GBPHKD
#   ##
#   ## .. code-block:: nim
#   ##    var curs = getCurrentForex(@["EURUSD","EURHKD"])
#   ##    echo()
#   ##    echo "Current EURUSD Rate : ","{:<8}".fmt(curs.ra[0])
#   ##    echo "Current EURHKD Rate : ","{:<8}".fmt(curs.ra[1])
#   ##    echo()
#   ##
# 
#   # currently using cvs data url
#   try:
#           var aurl = "http://finance.yahoo.com/d/quotes.csv?e=.csv&f=c4l1&s="    #  EURUSD=X,GBPUSD=X
#           for ac in curs:
#             aurl = aurl & ac & "=X,"
# 
#           # init a Currencies object to hold forex data
#           var rf = initCurrencies()
# 
#           var acvsfile = "nimcurmp.csv"  # temporary file
#           downloadFile(aurl,acvsfile)
# 
#           var s = newFileStream(acvsfile, fmRead)
#           if s == nil:
#               # in case of problems with the yahoo csv file we show a message
#               msgr() do : echo "Hello : Forex data file $1 could not be opened " % acvsfile
# 
#           # now parse the csv file
#           var x: CsvParser
#           var c = 0
#           open(x, s , acvsfile, separator=',')
#           while readRow(x):
#               c = 0 # counter to assign item to correct var
#               for val in items(x.row):
#                       c += 1
# 
#                       case c
#                       of 1:
#                             rf.cu.add(val)
#                       of 2:
#                             if val == "N/A":
#                               rf.ra.add(0.00)
#                             else:
#                               rf.ra.add(parseFloat(val))
#                       else:
#                             msgr() do : echo "Csv currency data in unexpected format "
# 
#           # clean up
#           removeFile(acvsfile)
#           result = rf
#           
#   except HttpRequestError:
#           printLn("Forex Data temporary unavailable" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
#   except ValueError:
#           discard
#   except OSError:
#           discard
#   except OverflowError:
#           discard
#   except  TimeoutError:
#          println("TimeoutError: " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
#   except  ProtocolError:
#          println("Protocol Error" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
#   except :
#          discard
#   finally:
#         discard  
#         
        

proc getCurrentForex*(curs:seq[string],xpos:int = 1):Currencies =
  ## getCurrentForex
  ##
  ## get the latest yahoo exchange rate info for a currency pair
  ##
  ## e.g EURUSD , JPYUSD ,GBPHKD
  ##
  ## .. code-block:: nim
  ##    var curs = getCurrentForex(@["EURUSD","EURHKD"])
  ##    echo()
  ##    echo "Current EURUSD Rate : ","{:<8}".fmt(curs.ra[0])
  ##    echo "Current EURHKD Rate : ","{:<8}".fmt(curs.ra[1])
  ##    echo()
  ##

  # currently using cvs data url
  # this version does not need temp file as we parse cvs as text file directly
  
  try:
          var aurl = "http://finance.yahoo.com/d/quotes.csv?e=.csv&f=c4l1&s="    #  EURUSD=X,GBPUSD=X
          for ac in curs:
            aurl = aurl & ac & "=X,"

          # init a Currencies object to hold forex data
          var rf = initCurrencies()
          var zs = splitlines(unquote(getcontent(aurl)))  # get data
          var c = 0
          for zl in zs:
              var x = split(zl,",")
              c = 0 # counter to assign item to correct var
              for val in x:
                       c += 1
                       case c
                        of 1:
                             rf.cu.add(val)
                        of 2:
                             if val == "N/A":
                                rf.ra.add(0.00)
                             else:
                               rf.ra.add(parseFloat(val))
                        else:
                             println("Csv currency data in unexpected format ",truetomato,xpos = xpos)
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
         println("TimeoutError: " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
  except  ProtocolError:
         println("Protocol Error" & getCurrentExceptionMsg(),truetomato,xpos = xpos)
  except :
         discard
  finally:
        discard  

       

# proc showCurrentForex*(curs : seq[string]) =
#        ## showCurrentForex
#        ##
#        ## a convenience proc to display exchange rates
#        ##
#        ## .. code-block:: nim
#        ##    
#        ##    var curs = @["EURUSD","GBPHKD","CADEUR","AUDNZD","GBPCNY","JPYHKD"]
#        ##    var cursl = curs.len
#        ##    showCurrentForex(curs,xpos = 5)
#        ##    curup(cursl + 2)
#        ##    drawbox(cursl + 2,36,1,2,xpos = 3)
#        ##    decho(cursl + 5)
#        ##    doFinish()
#        ##    
# 
#        var cx = getcurrentForex(curs) # we get a Currencies object back
#        msgg() do : echo "{:<8} {:<4} {}".fmt("Pair","Cur","Rate")
#        for x in 0.. <cx.cu.len:
#              echo "{:<8} {:<4} {}".fmt(curs[x],cx.cu[x],cx.ra[x])

proc showCurrentForex*(curs : seq[string],xpos:int = 1) =
       ## showCurrentForex
       ##
       ## a convenience proc to display exchange rates with positiong
       ##
       ## .. code-block:: nim
       ##    showCurrentForex(@["EURUSD","GBPHKD","CADEUR","AUDNZD"],xpos = 10)
       ##    decho(3)
       ##
       ##

       var cx = getcurrentForex(curs) # we get a Currencies object back
       printLn("{:<16} {:<4} {}".fmt("Currencies","Cur","Rate"),lime,xpos = xpos)
       for x in 0.. <cx.cu.len:
            printLn("{:<16} {:<4} {}".fmt(curs[x],cx.cu[x],cx.ra[x]),xpos = xpos)


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
   msgg() do : echo  "{:<8}{:>9}{:>9}{:>9}{:>9}{:>13}{:>9}{:>9}{:>9}{:>9}{:>9}".fmt("Code","Open","High","Low","Close","Volume","AdjClose","StDevHi","StDevLo","StDevCl","StDevClA")
   for x in 0.. <astkdata.len:
       var sx = astkdata[x] # just for less writing ...
       # display the data rows
       echo "{:<8}{:>9.3f}{:>9.3f}{:>9.3f}{:>9.3f}{:>13}{:>9.3f}{:>9.3f}{:>9.3f}{:>9.3f}{:>9.3f}".fmt(sx.stock,sx.open.last,sx.high.last,sx.low.last,sx.close.last,sx.vol.last,sx.adjc.last,
       sx.rh[0].standardDeviation,sx.rl[0].standardDeviation,sx.rc[0].standardDeviation,sx.rca[0].standardDeviation)

   echo()
   msgy() do : echo " NOTE : stdDevOpen and stdDevVol are not shown but available"
   decho(2)


proc showStockdataTable*(a:Stockdata) =
     ## showStockdatatable
     ##
     ## shows all items of a Stockdata object
     ##
     echo "{:<17} : {:>12}".fmt("Price",a.price)
     echo "{:<17} : {:>12}".fmt("Change",a.change)
     echo "{:<17} : {:>12}".fmt("Volume",a.volume)
     echo "{:<17} : {:>12}".fmt("Avg.DailyVolume",a.avgdailyvol)
     echo "{:<17} : {:>12}".fmt("Market",a.market)
     echo "{:<17} : {:>12}".fmt("MarketCap",a.marketcap)
     echo "{:<17} : {:>12}".fmt("BookValue",a.bookvalue)
     echo "{:<17} : {:>12}".fmt("Ebitda",a.ebitda)
     echo "{:<17} : {:>12}".fmt("DividendPerShare",a.dividendpershare)
     echo "{:<17} : {:>12}".fmt("DividendPerYield",a.dividendperyield)
     echo "{:<17} : {:>12}".fmt("EarningsPerShare",a.earningspershare)
     echo "{:<17} : {:>12}".fmt("52 Week High",a.week52high)
     echo "{:<17} : {:>12}".fmt("52 Week Low",a.week52low)
     echo "{:<17} : {:>12}".fmt("50 Day Mov. Avg",a.movingavg50day)
     echo "{:<17} : {:>12}".fmt("200 Day Mov. Avg",a.movingavg200day)
     echo "{:<17} : {:>12}".fmt("P/E",a.priceearingratio)
     echo "{:<17} : {:>12}".fmt("P/E Growth Ratio",a.priceearninggrowthratio)
     echo "{:<17} : {:>12}".fmt("Price Sales Ratio",a.pricesalesratio)
     echo "{:<17} : {:>12}".fmt("Price Book Ratio",a.pricebookratio)
     echo "{:<17} : {:>12}".fmt("Price Short Ratio",a.shortratio)
     decho(2)



template metal():stmt =
    ## metal
    ## 
    ## utility template to display kitco metal data
    ## 
    ## used by showKitcoMetal
    ## 

    if ktd[x].startswith(dl) == true:
      printLn(ktd[x],yellowgreen,xpos = xpos - 3 )
      
    elif find(ktd[x],"Asia / Europe") > 0:
       print(strip(ktd[x],true,true),cx.white,xpos = xpos)
        
    elif find(ktd[x],"New York") > 0:
       print(strip(ktd[x],true,true),cx.white,xpos = xpos)
    
    elif find(ktd[x],opn) > 0 :
        printLn(ktd[x],lime)   
      
    elif find(ktd[x],cls) > 0:
        printLn(ktd[x],truetomato)  
      
    elif find(ktd[x],"Update") > 0:
        printLn(ktd[x] & " New York Time",yellowgreen,xpos = xpos - 3)
                          
    else:
          printLn(ktd[x],cx.white,xpos = xpos - 3)



proc showKitcoMetal*(xpos:int = 1) = 
    ## showKitcoMetal
    ## 
    ## get and display kitco metal prices
    ## 
    ##  
    let dl  = "   ----------------------------------------------------------------------"
    let cls = "CLOSED"
    let opn = "OPEN" 
    let url = "http://www.kitco.com/texten/texten.html"
    
    printLn("Gold,Silver,Platinum Spot price : New York and Asia / Europe ",peru,xpos = xpos)
    
    try:
            var kt = getContent(url,timeout = 5000)
  
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
                  printLn("All Metal Markets Closed or Data unavailable",truetomato,xpos = xpos)
                  for x in 13.. <ktd.len: metal()   
                      
            elif nymarket == true and asiaeuropemarket == true:
                  # both open we show new york gold       
                  for x in 0.. ktd.len - 18: metal()                                       
          
            elif nymarket == true and asiaeuropemarket == false:
                # ny  open we show new york gold       
                  for x in 0.. <ktd.len - 18: metal()                                                                     

            elif nymarket == false and asiaeuropemarket == true:
                  # asiaeuropemarket  open we show asiaeuropemarket gold       
                  for x in 13.. <ktd.len: metal()  
                  
                  
    except HttpRequestError:
          printLn("Kitco Data temporary unavailable : " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except ValueError:
          discard
    except OSError:
          discard
    except OverflowError:
          discard
    except  TimeoutError:
         println("TimeoutError : " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
    except  ProtocolError:
         println("Protocol Error : " & getCurrentExceptionMsg(),truetomato,xpos = xpos)
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
