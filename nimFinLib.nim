
##
## Program     : nimFinLib
##
## Status      : Development
##
## License     : MIT opensource
##
## Version     : 0.2.5
##
## Compiler    : nim 0.11.3
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
## Project     : https://github.com/qqtop/NimFinLib
##
## Tested on   : Linux
##
## ProjectStart: 2015-06-05
##
## ToDo        : Ratios , Covariance , Correlation
##               improve exception handling if yahoo data fails to be retrieved 
##               or is temporary unavailable for certain markets
##
## Programming : qqTop
##
## Contributors: reactorMonk
##
## Requires    : strfmt,random modules and statistics.nim
##
## Notes       : it is assumed that terminal color is black background
##
##               and white text. Other color schemes may not show all output.
##
##               For comprehensive tests and usage see nimFinT5.nim
##
## Installation: git clone https://github.com/qqtop/NimFinLib.git
##
## or
##
## nimble install nimFinLib
##
##


import os,strutils,parseutils,sequtils,httpclient,strfmt
import terminal,times,tables,random, parsecsv,streams,algorithm,math,unicode
import statistics

let NIMFINLIBVERSION* = "0.2.5"
let startnimfinlib = epochTime()

const
       red*    = "red"
       green*  = "green"
       cyan*   = "cyan"
       yellow* = "yellow"
       white*  = "white"
       black*  = "black"
       brightred*    = "brightred"
       brightgreen*  = "brightgreen"
       brightcyan*   = "brightcyan"
       brightyellow* = "brightyellow"
       brightwhite*  = "brightwhite"
      
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
       ## is a simple object to hold current currency data

       cu* : seq[string]  # currency code pair e.g. EURUSD
       ra* : seq[float]   # relevant rate  e.g 1.354


template msgg*(code: stmt): stmt =
      ## msgX templates
      ## convenience templates for colored text output
      ## the assumption is that the terminal is white text and black background
      ## naming of the templates is like msg+color so msgy => yellow
      ## msg+color+b turns on the bright flag
      ##
      ## .. code-block:: nim
      ##    msgg() do : echo "How nice, it's in green"
      ##
      setforegroundcolor(fgGreen)
      code
      setforegroundcolor(fgWhite)

template msggb*(code: stmt): stmt =
      ## msggb
      ##
      ## .. code-block:: nim
      ##    msggb() do : echo "How nice, it's in bright green"
      ##

      setforegroundcolor(fgGreen,true)
      code
      setforegroundcolor(fgWhite)


template msgy*(code: stmt): stmt =
      setforegroundcolor(fgYellow)
      code
      setforegroundcolor(fgWhite)


template msgyb*(code: stmt): stmt =
      setforegroundcolor(fgYellow,true)
      code
      setforegroundcolor(fgWhite)


template msgr*(code: stmt): stmt =
      setforegroundcolor(fgRed)
      code
      setforegroundcolor(fgWhite)


template msgrb*(code: stmt): stmt =
      setforegroundcolor(fgRed,true)
      code
      setforegroundcolor(fgWhite)

template msgc*(code: stmt): stmt =
      setforegroundcolor(fgCyan)
      code
      setforegroundcolor(fgWhite)


template msgcb*(code: stmt): stmt =
      setforegroundcolor(fgCyan,true)
      code
      setforegroundcolor(fgWhite)


template msgw*(code: stmt): stmt =
      setforegroundcolor(fgWhite)
      code
      setforegroundcolor(fgWhite)


template msgwb*(code: stmt): stmt =
      setforegroundcolor(fgWhite,true)
      code
      setforegroundcolor(fgWhite)


template msgb*(code: stmt): stmt =
      setforegroundcolor(fgBlack,true)
      code
      setforegroundcolor(fgWhite)


template hdx*(code:stmt):stmt  =
   ## hdx
   ##
   ## hdx is used for headers to make them stand out
   ##
   ## it puts the text between 2 horizontal "+" lines
   ##

   echo ""
   echo repeat("+",tw)
   setforegroundcolor(fgCyan)
   code
   setforegroundcolor(fgWhite)
   echo repeat("+",tw)
   echo ""


template withFile*(f: expr, filename: string, mode: FileMode,
                    body: stmt): stmt {.immediate.} =
    ## withFile
    ##
    ## file open close utility template
    ##
    ## .. code-block:: nim
    ##    let curFile="notes.txt"    # some file
    ##    withFile(txt, curFile, fmRead):
    ##        while true :
    ##            try:
    ##               stdout.writeln(txt.readLine())   # do something with the lines
    ##            except:
    ##               break
    ##    echo()
    ##

    let fn = filename
    var f: File

    if open(f, fn, mode):
        try:
          body
        finally:
          close(f)
    else:
        let msg = "Cannot open file"
        echo ()
        msgy() do : echo "Processing file " & fn & ", stopped . Reason: ", msg
        quit()



proc printHl*(sen:string,astr:string,col:string) =
      ## printHl
      ##
      ## print and highlight all appearances of a char or substring of a string
      ##
      ## with a certain color
      ##
      ## .. code-block:: nim
      ##    printHl("HELLO THIS IS A TEST","T",green)
      ##
      ## this would highlight all T in green
      ##
      ## available colors : green,yellow,cyan,red,white,black,brightgreen,brightwhite
      ## 
      ##                    brightred,brightcyan,brightyellow
 
      var rx = sen.split(astr)
      for x in rx.low.. rx.high:
          writestyled(rx[x],{})
          if x != rx.high:
              case col
              of green  : msgg() do  : write(stdout,astr)
              of red    : msgr() do  : write(stdout,astr)
              of cyan   : msgc() do  : write(stdout,astr)
              of yellow : msgy() do  : write(stdout,astr)
              of white  : msgw() do  : write(stdout,astr)
              of black  : msgb() do  : write(stdout,astr)
              of brightgreen : msggb() do : write(stdout,astr)
              of brightwhite : msgwb() do : write(stdout,astr)
              of brightyellow: msgyb() do : write(stdout,astr)
              of brightcyan  : msgcb() do : write(stdout,astr)
              of brightred   : msgrb() do : write(stdout,astr)
              else  : msgw() do  : write(stdout,astr)


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


proc showTimeSeries* (ats:Ts,header,ty:string,N:int)  =
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


   msgg() do : echo "{:<11} {:>11} ".fmt("Date",header)
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

converter toTwInt(x: cushort): int = result = int(x)
when defined(Linux):
    proc getTerminalWidth*() : int =
      ## getTerminalWidth
      ##
      ## utility to easily draw correctly sized lines on linux terminals
      ##
      ## and get linux terminal width
      ##
      ## for windows this currently is set to terminalwidth 80
      ##
      ## .. code-block:: nim
      ##
      ##    echo "Terminalwidth : ",tw
      ##    echo aline
      ##
      ## tw and aline are exported
      ## but of course you also can do
      ##
      ## .. code-block:: nim
      ##    var mytermwidth = getTerminalWidth()
      ##    echo repeat("*",mytermwidth)
      ## in case you want to use another line building char
      ##
      type WinSize = object
        row, col, xpixel, ypixel: cushort
      const TIOCGWINSZ = 0x5413
      proc ioctl(fd: cint, request: culong, argp: pointer)
        {.importc, header: "<sys/ioctl.h>".}
      var size: WinSize
      ioctl(0, TIOCGWINSZ, addr size)
      result = toTwInt(size.col)

    var tw* = getTerminalWidth()
    var aline* = repeat("-",tw)

# currently hardcoded for windows
when defined(Windows):
     var tw* = 80
     var aline* = repeat("-",tw)

proc decho*(z:int)  =
    ## decho
    ##
    ## blank lines creator
    ##
    ## .. code-block:: nim
    ##    decho(10)
    ## to create 10 blank lines
    for x in 0.. <z:
      echo()

proc getCurrentQuote*(stcks:string) : string =
   ## getCurrentQuote
   ##
   ## gets the current price/quote from yahoo for 1 stock code
   var aurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % stcks
   #var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
   var data = newSeq[string]()
   var line = getContent(aurl)
   data = line[1..line.high].split(",")
   #echo "DATA -> : ",data
   if data.len > 1:
      result = data[3]
   else:
      result = "-1"


proc currentStocks(aurl:string) =
  ## currentStocks
  ##
  ## display routine for current stock quote maybe 15 mins delayed
  ##
  ## not callable
  ##
  #  some error handling is implemented if the yahoo servers are down

  var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
  try:
    for line in getContent(aurl).splitLines:
      var data = line[1..line.high].split(",")
      # even if yahoo servers are down our data.len is still 1 so
      if data.len > 1:
              setforegroundcolor(fgGreen)
              echo "Code : {:<10} Name : {}  Market : {}".fmt(data[0],data[1],data[2])
              setforegroundcolor(fgWhite)
              echo "Date : {:<12}{:<9}    Price  : {:<8} Volume : {:>12}".fmt(data[4],data[5],data[3],data[8])
              echo "Open : {:<8} High : {:<8} Change : {} Range : {}".fmt(data[6],data[7],data[9],data[10])
              echo repeat("-",tw)
      else:
             if data.len == 1 and sflag == false:
                msgr() do : echo "Yahoo server maybe unavailable. Try again later"
                sflag = true
  except HttpRequestError:
      msgr() do : echo "Yahoo current data could not be retrieved . Try again ."


proc currentIndexes(aurl:string) {.discardable.} =
  ## currentIndexes
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
              setforegroundcolor(fgYellow)
              echo "Code : {:<10} Name : {}  Market : {}".fmt(data[0],data[1],data[2])
              setforegroundcolor(fgWhite)
              echo "Date : {:<12}{:<9}    Index  : {:<8}".fmt(data[4],data[5],data[3])
              echo "Open : {:<8} High : {:<8} Change : {} Range : {}".fmt(data[6],data[7],data[9],data[10])
              echo repeat("-",tw)
      else:
              if data.len == 1 and sflag == false:
                 msgr() do : echo "Yahoo server maybe unavailable. Try again later"
                 sflag = true
  except HttpRequestError:
      msgr() do : echo "Yahoo current data could not be retrieved . Try again ."
      

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


# Note showCurrentIndexes and showCurrentStocks are basically the same
# but it makes for easier reading in the application to give it different names

proc showCurrentIndexes*(idxs:string){.discardable.} =
   ## showCurrentIndexes
   ##
   ## callable display routine for currentIndexes
   ##
   hdx(echo "Index Data")
   var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % idxs
   currentIndexes(qurl)


proc showCurrentIndexes*(adf:seq[Stocks]){.discardable.} =
   ## showCurrentIndexes
   ##
   ## callable display routine for currentIndexes with a pool object passed in
   ##
   var idxs = buildStockString(adf)
   hdx(echo "Index Data for a pool" )
   var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % idxs
   currentIndexes(qurl)



proc showCurrentStocks*(apf:Portfolio){.discardable.} =
   ## showCurrentStocks
   ##
   ## callable display routine for currentStocks with Portfolio object passed in
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
   var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % stcks
   currentStocks(qurl)



proc showCurrentStocks*(stcks:string){.discardable.} =
   ## showCurrentStocks
   ##
   ## callable display routine for currentStocks with stockstring passed in
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
   var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % stcks
   currentStocks(qurl)



proc day*(aDate:string) : string =
   ## day
   ##
   ## get day substring from a yyyy-MM-dd date string
   ##
   ## Format dd
   ##
   aDate.split("-")[2]


proc ymonth*(aDate:string) : string =
  ## ymonth
  ##
  ## yahoo month starts with 00 for jan
  ##
  ## Format MM
  ##
  ## not exported and only used internally for yahoo url setup
  #
  var asdm = $(parseInt(aDate.split("-")[1])-1)
  if len(asdm) < 2: asdm = "0" & asdm
  result = asdm


proc month*(aDate:string) : string =
  ## month
  ##
  ## get month substring from a yyyy-MM-dd date string
  ##
  ## Format MM
  ##
  var asdm = $(parseInt(aDate.split("-")[1]))
  if len(asdm) < 2: asdm = "0" & asdm
  result = asdm


proc year*(aDate:string) : string = aDate.split("-")[0]
     ## year
     ##
     ## get year substring from a yyyy-MM-dd date string
     ##
     ## Format yyyy


proc validdate*(adate:string):bool =
     ## validdate
     ##
     ## the purpose of this function is to strictly enforce correct dates
     ##
     ## input in format yyyy-MM-dd with correct year,month,day ranges
     ##

     var m30 = @["04","06","09","11"]
     var m31 = @["01","03","05","07","08","10","12"]

     var xdate = parseInt(aDate.replace("-",""))
     # check 1 is our date between 1900 - 3000
     if xdate > 19000101 and xdate < 30001212:
        var spdate = aDate.split("-")
        if parseint(spdate[0]) >= 1900 and parseint(spdate[0]) <= 3000:
             if spdate[1] in m30:
               # so day max 30
                if parseInt(spdate[2]) > 0 and parseInt(spdate[2]) < 31:
                   result = true
                else:
                   result = false

             elif spdate[1] in m31:
               # so day max 30
                if parseInt(spdate[2]) > 0 and parseInt(spdate[2]) < 32:
                   result = true
                else:
                   result = false

             else:
                   # so its february
                   if spdate[1] == "02" :
                      # check leapyear
                      if isleapyear(parseint(spdate[0])) == true:
                          if parseInt(spdate[2]) > 0 and parseint(spdate[2]) < 30:
                            result = true
                          else:
                            result = false
                      else:
                          if parseInt(spdate[2]) > 0 and parseint(spdate[2]) < 29:
                            result = true
                          else:
                            result = false

proc intervalsecs*(startDate,endDate:string) : float =
      ## interval procs returns time elapsed between two dates in secs,hours etc.
      if validdate(startDate) and validdate(endDate):
          var f     = "yyyy-MM-dd"
          var ssecs = toSeconds(timeinfototime(startDate.parse(f)))
          var esecs = toSeconds(timeinfototime(endDate.parse(f)))
          var isecs = esecs - ssecs
          result = isecs
      else:
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc intervalsecs"
          result = -0.0

proc intervalmins*(startDate,endDate:string) : float =
      if validdate(startDate) and validdate(endDate):
           var imins = intervalsecs(startDate,endDate) / 60
           result = imins
      else:
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc intervalmins"
          result = -0.0


proc intervalhours*(startDate,endDate:string) : float =
     if validdate(startDate) and validdate(endDate):
         var ihours = intervalsecs(startDate,endDate) / 3600
         result = ihours
     else:
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc intervalhours"
          result = -0.0

proc intervaldays*(startDate,endDate:string) : float =
      if validdate(startDate) and validdate(endDate):
          var idays = intervalsecs(startDate,endDate) / 3600 / 24
          result = idays
      else:
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc intervaldays"
          result = -0.0

proc intervalweeks*(startDate,endDate:string) : float =

      if validdate(startDate) and validdate(endDate):
          var iweeks = intervalsecs(startDate,endDate) / 3600 / 24 / 7
          result = iweeks
      else:
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc intervalweeks"
          result = -0.0


proc intervalmonths*(startDate,endDate:string) : float =
     if validdate(startDate) and validdate(endDate):
          var imonths = intervalsecs(startDate,endDate) / 3600 / 24 / 365  * 12
          result = imonths

     else:
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc intervalmonths"
          result = -0.0

proc intervalyears*(startDate,endDate:string) : float =
     if validdate(startDate) and validdate(endDate):
          var iyears = intervalsecs(startDate,endDate) / 3600 / 24 / 365
          result = iyears
     else:
          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc intervalyears"
          result = -0.0



proc compareDates*(startDate,endDate:string) : int =
     # dates must be in form yyyy-MM-dd
     # we want this to answer
     # s == e   ==> 0
     # s >= e   ==> 1
     # s <= e   ==> 2
     # -1 undefined , invalid s date
     # -2 undefined . invalid e and or s date
     if validdate(startDate) and validdate(enddate):

        var std = startDate.replace("-","")
        var edd = endDate.replace("-","")
        if std == edd:
          result = 0
        elif std >= edd:
          result = 1
        elif std <= edd:
          result = 2
        else:
          result = -1
     else:

          msgr() do : echo  "Date error. : " &  startDate,"/",endDate,"  Format yyyy-MM-dd expected"
          msgr() do : echo  "proc comparedates"
          result = -2


proc sleepy*[T:float|int](s:T) =
    # s is in seconds
    var ss = epochtime()
    var ee = ss + s.float
    var c = 0
    while ee > epochtime():
        inc c
    # feedback line can be commented out
    #msgr() do : echo "Loops during waiting for ",s,"secs : ",c



proc fx(nx:TimeInfo):string =
        result = nx.format("yyyy-MM-dd")

proc plusDays*(aDate:string,days:int):string =
   ## plusDays
   ##
   ## adds days to date string of format yyyy-MM-dd  or result of getDateStr()
   ##
   ## and returns a string of format yyyy-MM-dd
   ##
   ## the passed in date string must be a valid date or an error message will be returned
   ##
   if validdate(aDate) == true:
      var rxs = ""
      var tifo = parse(aDate,"yyyy-MM-dd") # this returns a TimeInfo type
      var myinterval = initInterval()
      myinterval.days = days
      rxs = fx(tifo + myinterval)
      result = rxs
   else:
      msgr() do : echo "Date error : ",aDate
      result = "Error"

proc minusDays*(aDate:string,days:int):string =
   ## minusDays
   ##
   ## subtracts days from a date string of format yyyy-MM-dd  or result of getDateStr()
   ##
   ## and returns a string of format yyyy-MM-dd
   ##
   ## the passed in date string must be a valid date or an error message will be returned
   ##

   if validdate(aDate) == true:
      var rxs = ""
      var tifo = parse(aDate,"yyyy-MM-dd") # this returns a TimeInfo type
      var myinterval = initInterval()
      myinterval.days = days
      rxs = fx(tifo - myinterval)
      result = rxs
   else:
      msgr() do : echo "Date error : ",aDate
      result = "Error"



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
             msgr() do : echo "Hello : Data file for $1 could not be opened " % symb

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



proc getCurrentForex*(curs:seq[string]):Currencies =
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
  var aurl = "http://finance.yahoo.com/d/quotes.csv?e=.csv&f=c4l1&s="    #  EURUSD=X,GBPUSD=X
  for ac in curs:
     aurl = aurl & ac & "=X,"

  # init a Currencies object to hold forex data
  var rf = initCurrencies()

  var acvsfile = "nimcurmp.csv"  # temporary file
  downloadFile(aurl,acvsfile)

  var s = newFileStream(acvsfile, fmRead)
  if s == nil:
       # in case of problems with the yahoo csv file we show a message
       msgr() do : echo "Hello : Forex data file $1 could not be opened " % acvsfile

  # now parse the csv file
  var x: CsvParser
  var c = 0
  open(x, s , acvsfile, separator=',')
  while readRow(x):
      c = 0 # counter to assign item to correct var
      for val in items(x.row):
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
                    msgr() do : echo "Csv currency data in unexpected format "

  # clean up
  removeFile(acvsfile)
  result = rf


proc showCurrentForex*(curs : seq[string]) =
       ## showCurrentForex
       ##
       ## a convenience proc to display exchange rates
       ##
       ## .. code-block:: nim
       ##    showCurrentForex(@["EURUSD","GBPHKD","CADEUR","AUDNZD"])
       ##    decho(3)
       ##
       ##

       var cx = getcurrentForex(curs) # we get a Currencies object back
       msgg() do : echo "{:<8} {:<4} {}".fmt("Pair","Cur","Rate")
       for x in 0.. <cx.cu.len:
             echo "{:<8} {:<4} {}".fmt(curs[x],cx.cu[x],cx.ra[x])


proc showStocksTable*(apfdata: Portfolio) =
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


proc rainbow* (astr : string) =
    ## rainbow
    ##
    ## random multi colored string
    ##
    ## .. code-block:: nim
    ##    rainbow("Sparkling string display !")
    ##    decho(2)
    ##

    var c = 0
    var a = toSeq(1.. 12)
    for x in 0.. <astr.len:
       c = a[randomInt(a.len)]
       case c
        of 1  : msgg()  do : write(stdout,astr[x])
        of 2  : msgr()  do : write(stdout,astr[x])
        of 3  : msgc()  do : write(stdout,astr[x])
        of 4  : msgy()  do : write(stdout,astr[x])
        of 5  : msggb() do : write(stdout,astr[x])
        of 6  : msgr()  do : write(stdout,astr[x])
        of 7  : msgwb() do : write(stdout,astr[x])
        of 8  : msgc()  do : write(stdout,astr[x])
        of 9  : msgyb() do : write(stdout,astr[x])
        of 10 : msggb() do : write(stdout,astr[x])
        of 11 : msgcb() do : write(stdout,astr[x])
        else  : msgw()  do : write(stdout,astr[x])



proc handler*() {.noconv.} =
  ## handler
  ##
  ## experimental
  ##
  ## this runs if ctrl-c is pressed
  ##
  ## and provides some feedback upon exit
  ##
  ## .. code-block:: nim
  ##    import nimFinLib
  ##    # get the latest delayed quotes for your stock
  ##    # press ctrl-c to exit
  ##    # setControlCHook(handler)    # auto registered exit handler
  ##    while true :
  ##       showCurrentStocks("IBM+AAPL+BP.L")
  ##       sleepy(5)
  ##
  ##

  eraseScreen()
  echo()
  echo aline
  msgg() do: echo "Thank you for using     : ",getAppFilename()
  msgc() do: echo "{}{:<11}{:>9}".fmt("Last compilation on     : ",CompileDate ,CompileTime)
  echo aline
  echo "Using nimFinLib Version : ", NIMFINLIBVERSION
  echo "Nim Version             : ", NimVersion
  echo()
  rainbow("Have a Nice Day !")  ## change or add custom messages as required
  decho(2)
  system.addQuitProc(resetAttributes)
  quit(0)

# this handler is automatically registered , comment out if undesired
setControlCHook(handler)

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



proc qqTop*() =
  ## qqTop
  ##
  ## prints qqTop logo in custom color
  ## 
  printHl("qq","qq",cyan)
  printHl("T","T",brightgreen)
  printHl("o","o",brightred)
  printHl("p","p",cyan)
  


# finalizer
proc doFinish*() =
    ## doFinish
    ##
    ## a end of program routine which displays some information
    ##
    ## can be changed to anything desired
    ##
    msgb() do : write(stdout,"{:<15}{} | {}{} | {}{} - {} | ".fmt("Application : ",extractFileName(getAppFilename()),"Nim : ",NimVersion," nimFinLib : ",NIMFINLIBVERSION,year(getDateStr()))) 
    qqTop()
    echo()
    msgy() do : write(stdout,"{:<15}{}{}".fmt("Elapsed     : ",epochtime() - startnimfinlib," secs"))
    decho(2)
    system.addQuitProc(resetAttributes)
    quit 0


#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------
