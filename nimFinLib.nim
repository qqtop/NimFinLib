
##
## Program     : nimFinLib  
## 
## Status      : Development 
## 
## License     : MIT opensource  
## 
## Version     : 0.2.x
## 
## Compiler    : nim 0.11.3
## 
## 
## Description : A basic library for financial calculations with Nim
## 
##               Yahoo historical stock data
##               
##               Yahoo current quotes and forex rates
##               
##               Dataframe like structure for easy working with dataseries
##               
##               Returns calculations
##               
##               Ema calculation
##               
##               Date manipulations
##               
##               
##               Documention was created with : nim doc nimFinLib 
##               
##               
##                            
##               
## Tested on   : Linux
##               
## ProjectStart: 2015-06-05
## 
## ToDo        : Ratios ,plotting, metals
## 
##  
## 
## Programming : qqTop 
## 
## Contributors: reactorMonk
## 


import os,strutils,parseutils,sequtils,httpclient,strfmt,terminal,times,tables
import parsecsv,streams,algorithm,math,unicode

let VERSION* = "0.2.1"

type
   
  Pf*  = object 
      ## Pf type
      ## holds all portfolios similar to a master account
      ## portfolios are Nf objects
      pf* : seq[Nf]  ## pf holds all Nf type portfolios for an account
  
  
    
  Nf* {.inheritable.} = object  
      ## Nf type
      ## holds one portfolio with all relevant historic stocks data
      nx* : string   ## nx  holds portfolio name  e.g. MyGetRichPortfolio
      dx* : seq[Df]  ## dx  holds all stocks with historical data 
  
 
   
  Df* {.inheritable.} = object of Nf
    ## Df type
    ## holds individual stocks history data and RunningStat for close and adj.close
    ## even more items may be added like full company name etc in the future
    ## items are stock code, ohlcva, rc and rca . 
    stock* : string           ## yahoo style stock code 
    date*  : seq[string]
    open*  : seq[float]
    high*  : seq[float]
    low*   : seq[float]
    close* : seq[float]
    vol*   : seq[float]        ## volume
    adjc*  : seq[float]        ## adjusted close price
    rc*    : seq[Runningstat]  ## RunningStat for close price
    rca*   : seq[Runningstat]  ## RunningStat for adjusted close price
   
 
 
  Ts* {.inheritable.} = object
       ## Ts type
       ## is a simple timeseries object which can hold one 
       ## column of any OHLCVA data
       
       dd* : seq[string]  # date
       tx* : seq[float]   # data


  Cf* {.inheritable.} = object
       ## Cf type
       ## is a simple object to hold current currency data
       
       cu* : seq[string]  # currency code pair e.g. EURUSD
       ra* : seq[float]   # relevant rate  e.g 1.354


template msgg*(code: stmt): stmt {.immediate.} =
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

template msggb*(code: stmt): stmt {.immediate.} =
      ## msggb
      ## 
      ## .. code-block:: nim
      ##    msggb() do : echo "How nice, it's in bright green"
      ##    
     
      setforegroundcolor(fgGreen,true)
      code
      setforegroundcolor(fgWhite)      
      
      
template msgy*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgYellow)
      code
      setforegroundcolor(fgWhite)
      
template msgyb*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgYellow,true)
      code
      setforegroundcolor(fgWhite)      
      

template msgr*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgRed)
      code
      setforegroundcolor(fgWhite)
      
template msgrb*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgRed,true)
      code
      setforegroundcolor(fgWhite)      

template msgc*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgCyan)
      code
      setforegroundcolor(fgWhite)

template msgcb*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgCyan,true)
      code
      setforegroundcolor(fgWhite)


template msgw*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgWhite)
      code
      setforegroundcolor(fgWhite)

template msgwb*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgWhite,true)
      code
      setforegroundcolor(fgWhite)

template hdx*(code:stmt):stmt {.immediate.}  =
   ## hdx
   ## 
   ## hdx is used for headers to make them stand out
   ## 
   ## it puts the text between 2 horizontal lines
   ##

   echo ""
   echo repeat("+",tw)
   setforegroundcolor(fgCyan)
   code
   setforegroundcolor(fgWhite)
   echo repeat("+",tw)
   echo ""

  
proc timeseries*[T](self:T,ty:string): Ts =
     ## timeseries
     ## returns a Ts type date and one data column based on ty selection 
     ## input usually is a Df object and a string , if a string is in ohlcva
     ## the relevant series will be extracted from the Df object
     ## 
     ## usage exmple : 
     ## 
     ## .. code-block:: nim
     ##  
     ##    timeseries(myDfObject,"o")
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


 

proc showTimeseries* (ats:Ts,header,ty:string,N:int)  =
   ## showTimeseries 
   ## takes a Ts object as input as well as a header string
   ## for the data column , a string which can be one of
   ## head,tail,all and N for number of rows to display 
   ## usage : showTimeseries(myTimeseries,myHeader,"head|tail|all",rows)
    
   
   msgg() do : echo "{:<11} {:>11} ".fmt("Date",header) 
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


proc initPf*():PF = 
     ## initPf
     ## 
     ## init a new empty account object
     ## 
     ## .. code-block:: nim
     ##    var myAccount = initPf()
     ##  
     var apf : Pf
     apf.pf = @[]
     result = apf


proc initNf*():Nf =
    ## initNf
    ## 
    ## init a new empty portfolio object
    ## 
    ## .. code-block:: nim
    ##    var myETFportfolio = initNf()
    ##    
    var anf : Nf
    anf.nx = ""
    anf.dx = @[]
    result = anf 


proc initDf*():Df =
    ## initDf
    ## 
    ## init stock data object 
    ## 
    ## .. code-block:: nim
    ##    var mystockData = initDf()
    ##    
    var adf : Df
    adf.stock = ""
    adf.date  = @[]
    adf.open  = @[]
    adf.high  = @[]
    adf.low   = @[]
    adf.close = @[]
    adf.vol   = @[]
    adf.adjc  = @[]
    adf.rc    = @[]
    adf.rca   = @[]
    result = adf

    
proc initCf*():Cf=
     ## initCf
     ## 
     ## init a Cf object to hold basic forex data
     ## 
     ## .. code-block:: nim
     ##    var myForex = initCf()
     ##    
     var acf : Cf
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
     
proc initPool*():seq[Df] =
  ## initPool
  ## 
  ## init pools , which are sequences of Df objects used in portfolio building
  ## 
  ## .. code-block:: nim
  ##    var mystockPool = initPool()
  ##    
  
  var apool = newSeq[Df]()     
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

# will change this once windows gets a real terminal or shell
when defined(Windows):
   tw = repeat("-",80)

proc decho*(z:int) {.discardable.} =
    ## decho
    ##  
    ## blank lines creator
    ## 
    ## .. code-block:: nim
    ##    decho(10)
    ## to create 10 blank lines   
    for x in 0.. <z:
      echo()

       
proc stockDf*(dx : Df) : string =
  ## stockDf
  ## 
  ## get the stock name from a Df object and return as string
  ## (will be deprecated shortly)
  ## 
  var stk: string = dx.stock
  result = stk        

proc currentStocks(aurl:string) {.discardable.} =
  ## currentStocks 
  ## 
  ## display routine for current stock quote maybe 15 mins delayed
  ## 
  ## not callable
  ## 
  #  some meek error handling is implemented if the yahoo servers are down
  
  var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
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
                

proc currentIndexes(aurl:string) {.discardable.} =
  ## currentIndexes
  ## 
  ## display routine for current index quote
  ## 
  ## not callable
  ##
  #  some meek error handling is implemented if the yahoo servers are down
  
  var sflag : bool = false  # a flag to avoid multiple error messages if we are in a loop
  for line in getContent(aurl).splitLines:
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

proc buildStockString*(apf:Nf):string =
  ## buildStockString
  ## 
  ## Produce a string of one or more stock codes coming from a Nf object
  var xs = ""
  for x in 0.. <apf.dx.len:
    # need to pass multiple code like so code+code+ , an initial + is also ok.
    xs = xs & "+" & stockDf(apf.dx[x]) 
  result = xs  
  
proc buildStockString*(adf:seq[Df]):string =
  ## buildStockString
  ## 
  ## Produce a string of one or more stock codes coming from a pool Df object
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


proc showCurrentIndexes*(adf:seq[Df]){.discardable.} =
   ## showCurrentIndexes
   ## 
   ## callable display routine for currentIndexes with a pool object passed in
   ## 
   var idxs = buildStockString(adf)
   hdx(echo "Index Data for a pool" )
   var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % idxs
   currentIndexes(qurl)  



proc showCurrentStocks*(apf:Nf){.discardable.} =
   ## showCurrentStocks
   ## 
   ## callable display routine for currentStocks with Nf portfolio object passed in
   ## 
   ## .. code-block:: nim
   ##    showCurrentStocks(myAccount.Portfolio[0])
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


proc ymonth(aDate:string) : string =
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


proc validDate*(adate:string):bool =
     ## validDate
     ## 
     ## ensure that a date is in form yyyy-MM-dd (eg. 2015-03-20) and
     ## 
     ## contains correct entries for year,month,day incl. leapyears
     ## 
     ## date range allowed 1900-01-01  to  3000-12-31
     ## 
     var m30 = @["04","06","09","11"]
     var m31 = @["01","03","05","07","08","10","12"]
       
     var xdate = parseInt(aDate.replace("-",""))
     # check if the date is between 1900 - 3000
     if xdate > 19000101 and xdate < 30001231:
        var spdate = aDate.split("-")
        if parseint(spdate[0]) >= 1900 and parseint(spdate[0]) <= 3000:
             if spdate[1] in m30:
               # day max 30
                if parseInt(spdate[2]) > 0 and parseInt(spdate[2]) < 31:
                   result = true
                else:
                   result = false
                   
             elif spdate[1] in m31:
               # day max 31
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
         
         
 
       
proc compareDates*(startDate,endDate:string) : int = 
     ## compareDates
     ## 
     ## compare two dates of format yyyy-MM-dd
     ## 
     ## results returned:
     ## 
     ## startDate == endDate   ==> 0
     ## 
     ## startDate >= endDate   ==> 1
     ## 
     ## startDate <= endDate   ==> 2  
     ## 
     ## undefined , invalid startDate ==> -1   
     ## 
     ## undefined . invalid endDate and/or startDate  ==> -2
     ## 
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
          result = -2


proc plusDays*(aDate:string,days:int):string =
   ## plusDays
   ## 
   ## adds days to date string of format yyyy-MM-dd  or result of getDateStr()
   ## 
   ## and returns a string of format yyyy-MM-dd
   ## 
   ## the passed in date string must be a valid date or an error message will be returned
   ##
   var rxs = ""
   if validdate(adate) == true:
        
        var spdate = aDate.split("-")
        var tifo = parse(aDate,"yyyy-MM-dd") # this returns a TimeInfo type
        var mflag: bool = false
        tifo.year = parseInt(spdate[0])

        case parseInt(spdate[1])
        of 1 :  tifo.month = mJan
        of 2 :  tifo.month = mFeb
        of 3 :  tifo.month = mMar
        of 4 :  tifo.month = mApr
        of 5 :  tifo.month = mMay
        of 6 :  tifo.month = mJun
        of 7 :  tifo.month = mJul
        of 8 :  tifo.month = mAug
        of 9 :  tifo.month = mSep
        of 10:  tifo.month = mOct
        of 11:  tifo.month = mNov
        of 12 : tifo.month = mDec
        else :
          mflag = true
        
        tifo.monthday = parseInt(spdate[2])
                
        if mflag == false:
            var myinterval = initInterval() 
            myinterval.days = days
            var rx = tifo + myinterval
            rxs = rx.format("yyyy-MM-dd")
                     
        else :
              msgr() do: echo "Date error. Wrong month : " &  spdate[1]
              rxs = ""
   else:
        msgr() do : echo  "Date error. Invalid date : " &  aDate,"  Format yyyy-MM-dd expected"
        rxs = ""
     
   result = rxs



proc minusDays*(aDate:string,days:int):string =
   ## minusDays
   ## 
   ## subtracts days from a date string of format yyyy-MM-dd  or result of getDateStr()
   ## 
   ## and returns a string of format yyyy-MM-dd
   ## 
   ## the passed in date string must be a valid date or an error message will be returned
   ##
   
   var rxs = ""
   if validdate(adate) == true:
        
        var spdate = aDate.split("-")
        var tifo = parse(aDate,"yyyy-MM-dd")  # this returns a TimeInfo type
        var mflag: bool = false
        tifo.year = parseInt(spdate[0])

        case parseInt(spdate[1])
        of 1 :  tifo.month = mJan
        of 2 :  tifo.month = mFeb
        of 3 :  tifo.month = mMar
        of 4 :  tifo.month = mApr
        of 5 :  tifo.month = mMay
        of 6 :  tifo.month = mJun
        of 7 :  tifo.month = mJul
        of 8 :  tifo.month = mAug
        of 9 :  tifo.month = mSep
        of 10:  tifo.month = mOct
        of 11:  tifo.month = mNov
        of 12 : tifo.month = mDec
        else :
          mflag = true
        
        tifo.monthday = parseInt(spdate[2])
                
        if mflag == false:
            var myinterval = initInterval() 
            myinterval.days = days
            var rx = tifo - myinterval
            rxs = rx.format("yyyy-MM-dd")
            
        else :
              msgr() do: echo "Date error. Wrong month : " &  spdate[1]
              rxs = ""
   else:
        msgr() do : echo  "Date error. Invalid date : " &  aDate ,"  Format yyyy-MM-dd expected"
        rxs = ""
     
   result = rxs

        
 
proc intervalsecs*(startDate,endDate:string) : float =
      ## interval procs returns time elapsed between two dates in secs,hours etc. 
      ## 
      var f     = "yyyy-MM-dd"
      var ssecs = toSeconds(timeinfototime(startDate.parse(f)))
      var esecs = toSeconds(timeinfototime(endDate.parse(f)))
      var isecs = esecs - ssecs  
      result = isecs
 
proc intervalmins*(startDate,endDate:string) : float =
      var imins = intervalsecs(startDate,endDate) / 60
      result = imins
 
proc intervalhours*(startDate,endDate:string) : float =
      var ihours = intervalsecs(startDate,endDate) / 3600
      result = ihours
 
proc intervaldays*(startDate,endDate:string) : float =
      var idays = intervalsecs(startDate,endDate) / 3600 / 24
      result = idays
   
proc intervalweeks*(startDate,endDate:string) : float =
      var iweeks = intervalsecs(startDate,endDate) / 3600 / 24 / 7
      result = iweeks
     
proc intervalmonths*(startDate,endDate:string) : float =
      var imonths = intervalsecs(startDate,endDate) / 3600 / 24 / 365  * 12
      result = imonths 
      
proc intervalyears*(startDate,endDate:string) : float =
      var iyears = intervalsecs(startDate,endDate) / 3600 / 24 / 365
      result = iyears

proc sleepy*(s:float) =
      ## sleepy
      ## 
      ## a sleep function to delay execution
      ## 
      ## usefull if fetching hundreds of stock codes or quotes from yahoo
      ## 
      ## in a loop in order not to hit the servers too hard.
      ## 
      
      var ss = epochtime()
      var ee = ss + s
      var c = 0
      while ee > epochtime():
        inc c


 
proc getSymbol2*(symb,startDate,endDate : string) : Df =
    ## getSymbol2
    ## 
    ## the work horse proc for getting yahoo data in csv format 
    ## 
    ## and then to parse into a Df object
    ## 
    # feedbackline can be commented out if not desired 
    # 
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
        
    # add RunningStat capability for close and adjusted close prices
    var closeRC  : Runningstat
    var closeRCA : Runningstat
          
    # note to dates for this yahoo url according to latest research
    # a=04  means may  a=00 means jan start month
    # b = start day 
    # c = start year
    # d = end month  05 means jun 
    # e = end day 
    # f = end year
    # we use the csv string , yahoo json format only returns limited data 1.5 years or less
    var qurl = "http://real-chart.finance.yahoo.com/table.csv?s=$1&a=$2&b=$3&c=$4&d=$5&e=$6&f=$7&g=d&ignore=.csv" % [symb,sdm,sdd,sdy,edm,edd,edy]
    var headerset = [symb,"Date","Open","High","Low","Close","Volume","Adj Close"]
    var c = 0
    var hflag  : bool # used for testing maybe removed later
    var astock = initDf()   # this will hold our result history data for one stock
                    
    # naming outputfile nimfintmp.csv as many stock symbols have dots like 0001.HK
    # could also be done to be in memory like /shm/  this file will be auto removed.
    
    var acvsfile = "nimfintmp.csv"
    downloadFile(qurl,acvsfile)
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
                    opedf.add(opex)
                  
              of 3:
                    higx = parseFloat(val)
                    higdf.add(higx)
                  
              of 4:
                    lowx = parseFloat(val)
                    lowdf.add(lowx)
                  
              of 5:
                    closx = parseFloat(val)
                    closeRC.push(closx)     ## RunningStat for close price
                    closdf.add(closx)
                  
              of 6:
                    volx = parseFloat(val)     
                    voldf.add(volx)
                  
              of 7:
                    adjclosx = parseFloat(val)    
                    closeRCA.push(adjclosx)  ## RunningStat for adj close price
                    adjclosdf.add(adjclosx)
              
              else :
                    msgr() do : echo "Csv Data in unexpected format for Stock :",symb

    # feedbacklines can be commented out  
    msgc() do:
              stdout.writeln(" --> Rows processed : ",processedRows(x))
              
              
    # close CsvParser
    close(x)
    
    # put the collected data into Df type
    astock.stock = symb
    astock.date  = datdf
    astock.open  = opedf
    astock.high  = higdf
    astock.low   = lowdf
    astock.close = closdf
    astock.adjc  = adjclosdf
    astock.vol   = voldf
    astock.rc    = @[]
    astock.rca   = @[]
    astock.rc.add(closeRC)
    astock.rca.add(closeRCA)
      
    # clean up
    removeFile(acvsfile)
    # send astock back
    result = astock
      
proc showhistData*(adf: Df,n:int) {.discardable.} =
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
    
      
proc showhistData*(adf: Df,s: string,e:string) {.discardable.} =
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
    result = self[self.low]
          
    
proc first*[T](self : seq[T]): T =
    ## first means oldest row 
    ## 
    result = self[self.high]
  
proc tail*[T](self : seq[T] , n: int) : seq[T] =
    ## tail means most recent rows 
    ## 
    if len(self) >= n:
        result = self[0.. <n]
    else:
        result = self[0.. <len(self)]
 
proc head*[T](self : seq[T] , n: int) : seq[T] =
    ## head means oldest rows 
    ## 
    var self2 = reversed(self)
    if len(self2) >= n:
        result = self2[0.. <n].tail(n)
    else:
        result = self2[0.. <len(self2)].tail(n)    
 
 
proc lagger*[T](self:T , days : int) : T =
     ## lagger
     ## 
     ## often we need a timeseries off by x days
     ## 
     ## this functions provides this
     ## 
     var lgx = self[days.. <self.len]
     result = lgx

 
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
                         

proc showdailyReturnsCl*(self:Df , N:int) {.discardable.} =
      ## showdailyReturnsCl
      ## 
      ## display returns based on close price
      ## 
      ## formated output to show date and returns columns
      ## 
      var dfr = self.close.dailyReturns    # note the first in seq corresponds to date closest to now
      # we also need to lag the dates  
      var dfd = self.date.lagger(1) 
      # now show it with symbol , date and close columns
      echo ""
      msgg() do: echo "{:<8} {:<11} {:>15}".fmt("Code","Date","Returns")
      # show limited rows output if c<>0
      if N == 0:
        for  x in 0.. <dfr.len:
             echo "{:<8}{:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])
      else:
        for  x in 0.. <N:
             echo "{:<8}{:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])
  

proc showdailyReturnsAdCl*(self:Df , N:int) {.discardable.} =
      ## showdailyReturnsAdCl 
      ## 
      ## returns based on adjusted close price
      ## 
      ## formated output to only show date and returns
      ## 
      var dfr = self.adjc.dailyReturns    # note the first in seq corresponds to date closest to now
      # we also need to lag the dates 
      var dfd = self.date.lagger(1) 
      # now show it with symbol , date and close columns
      echo ""
      msgg() do: echo "{:<8} {:<11} {:>15}".fmt("Code","Date","Returns")
      # show limited output if c<>0
      if N == 0:
        for  x in 0.. <dfr.len:
             echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])
      else:
        for  x in 0.. <N:
             echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])  
  
  
proc sumdailyReturnsCl*(self:Df) : float =
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

  
proc sumdailyReturnsAdCl*(self:Df) : float =
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


proc statistics*(x:Runningstat) {.discardable.} =
        ## statistics
        ## 
        ## display output of a runningstat object
        ## 
        echo "RunningStat Sum     : ", $formatFloat(x.sum,ffDecimal,5)
        echo "RunningStat Var     : ", $formatFloat(x.variance,ffDecimal,5)
        echo "RunningStat mean    : ", $formatFloat(x.mean,ffDecimal,5)
        echo "RunningStat Std     : ", $formatFloat(x.standardDeviation,ffDecimal,5)
        echo "RunningStat Min     : ", $formatFloat(x.min,ffDecimal,5)
        echo "RunningStat Max     : ", $formatFloat(x.max,ffDecimal,5)
        
 


# emaflag = false meaning all ok
# if true some problem to indicate to following calcs not to proceed

var emaflag : bool = false 

proc CalculateEMA(todaysPrice : float , numberOfDays: int , EMAYesterday : float) : float =
   ## supporting proc for ema calculation, not callable
   ## 
   var k = 2 / (float(numberOfDays) + 1.0)
   var ce = (todaysPrice * k) + (EMAYesterday * (1.0 - k))
   result = ce

proc ema* (dx : Df , N: int) : Ts =
    ## ema
    ## 
    ## exponential moving average
    ## 
    ## returns a Ts object loaded with date,ema pairs
    ## 
    ## calling with Df object and number of days for moving average
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
       msgr() do : echo "Insufficient data for valid ema calculation, need min. $1 data points" % $(5 * N)
      
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
          var aema = CalculateEMA(dx.close[x], N, yesterdayEMA)
          # put the calculated ema into our Ts object
          m_emaSeries.dd.add(dx.date[x])
          m_emaSeries.tx.add(aema)
          # make sure yesterdayEMA gets filled with the EMA we used this time around
          yesterdayEMA = aema
      
      
    result = m_emaSeries


proc showEma* (emx:Ts , N:int) {.discardable.} =
   ## showEma
   ## 
   ## convenience proc to display ema series with dates
   ## 
   ## input is a ema series Ts object and rows to display
   ## 
   ## latest data is on top
   ## 
   echo()
   msgg() do : echo "{:<11} {:>11} ".fmt("Date","EMA") 
   for x in countdown(emx.dd.len-1,emx.dd.len-N,1) : 
          echo "{:<11} {:>11} ".fmt(emx.dd[x],emx.tx[x])



proc getCurrentForex*(curs:seq[string]):Cf =
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
  
  # init a Cf object to hold forex data
  var rf = initCf() 
     
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
 
   
proc showCurrentForex*(curs : seq[string]) {.discardable.} =
       ## showCurrentForex  
       ##     
       ## a convenience proc to display exchange rates
       ## 
       ## .. code-block:: nim
       ##    showCurrentForex(@["EURUSD","GBPHKD","CADEUR","AUDNZD"])
       ##    decho(3)
       ##  
       ##   
       
       var cx = getcurrentForex(curs) # we get a Cf object back
       msgg() do : echo "{:<8} {:<4} {}".fmt("Pair","Cur","Rate")
       for x in 0.. <cx.cu.len:
             echo "{:<8} {:<4} {}".fmt(curs[x],cx.cu[x],cx.ra[x])
          
          

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

