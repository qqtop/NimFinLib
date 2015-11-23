import os,cx,httpclient,strutils,nimFinLib2,times,strfmt,osproc

# MINIFIN

# A MINI financial information system example
# currently set to update every minute if started w/o param
# here we show part of upcoming nimFinLib procs which utilize cx coloring and
# positional printing.
# 
# Usage : minifin 20    # update every 20 seconds
# 
# terminal size : full screen 80 x 40
# font          : monospace
# fontsize      : 9 regular

var mxpos = 5  # spacer from the left edge

let dl  = "   ----------------------------------------------------------------------"
let cls = "CLOSED"
let opn = "OPEN" 
let spc = "   "
let url = "http://www.kitco.com/texten/texten.html"



proc checkChange(s:string):int = 
     # parse the change data[6] from yahoo
     var z = split(s," - ")[0]
     if z.startswith("+") == true:
        result = 1
     elif z.startswith("-") == true:
        result = -1
     else:
        result = 0


proc currentIndexes(aurl:string,xpos:int) {.discardable.} =
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
                printBiCol("Code : {:<10}  ".fmt(unquote(data[0])),":",yellowgreen,cyan,xpos = xpos)
                printLnBiCol("Market : {}".fmt(unquote(data[2])),":",yellowgreen,cyan)
                echo()                        
                print(unquote(data[1]),yellowgreen,xpos = xpos)                   
                curdn(1)
                printLnBiCol("Date : {:<12}{:<9}    ".fmt(unquote(data[4]),unquote(data[5])),":",xpos = xpos)
                curup(2) 
                var cc = checkChange(unquote(data[9]))
                case cc
                  of -1 : printSlimNumber(data[3],fgr=truetomato,xpos = xpos + 29)
                  of  0 : printSlimNumber(data[3],fgr=steelblue,xpos = xpos + 29)
                  of  1 : printSlimNumber(data[3],fgr=lime,xpos = xpos + 29)
                  else    : print("Error",red,xpos = xpos + 29)
                
                printLnBiCol("Open : {:<8} High : {:<8} Change : {}".fmt(data[6],data[7],unquote(data[9])),":",xpos = xpos)
                printLnBiCol("Range: {}".fmt(unquote(data[10])),":",xpos = xpos)
                printLn(repeat("-",60),xpos = xpos)
                #curdn(1)
        else:
                if data.len == 1 and sflag == false:
                  printLn("Yahoo Server Fail.",truetomato,xpos = xpos)
                  sflag = true
    except HttpRequestError:
        printLn("Yahoo Data Fail.",truetomato,xpos = xpos)
        

proc showCurrentIDX(adf:string,xpos:int){.discardable.} =
    ## showCurrentIndexes
    ##
    ## callable display routine for currentIndexes with a pool object passed in
    ##
    #var idxs = buildStockString(adf)
    #cx.hdx(echo "Index Data for a pool" )
    var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % adf
    currentIndexes(qurl,xpos = xpos)



proc printNimSxR(nimsx:seq[string],col:string = yellowgreen, xpos: int = 1) = 
    ## printNimSxR
    ## 
    ## prints large Letters
    ## in your calling code arrange that most right one is printed first
    ## 
          
    var sxpos = xpos
    var maxl = 0
    
    for x in nimsx:
      if maxl < x.len:
          maxl = x.len
    
    var maxpos = cx.tw - maxl div 2 
    
    if xpos > maxpos:
          sxpos = maxpos

    for x in nimsx :
          printLn(" ".repeat(xpos) & x,randcol())
   
    
proc showCFx2(curs : seq[string],xpos:int) =
    var cx = getcurrentForex(curs) # we get a Currencies object back
    printLn("{:<16} {:<4} {}".fmt("Currencies","Cur","Rate"),lime,xpos = xpos)
    for x in 0.. <cx.cu.len:
            printLn("{:<16} {:<4} {}".fmt(curs[x],cx.cu[x],cx.ra[x]),xpos = xpos)


template metal():stmt =
                  if ktd[x].startswith(dl) == true:
                    printLn(ktd[x],yellowgreen,xpos = mxpos - 3 )
                                                
                  elif find(ktd[x],opn) > 0 :
                      printLn(ktd[x],lime,xpos = mxpos - 3)   
                    
                  elif find(ktd[x],cls) > 0:
                      printLn(ktd[x],truetomato,xpos = mxpos - 3)  
                    
                  elif find(ktd[x],"Update") > 0:
                      printLn(ktd[x] & " New York Time",yellowgreen,xpos = mxpos - 3)
                                        
                  else:
                        printLn(ktd[x],cx.white,xpos = mxpos - 3)
         

proc doit() =
    cleanScreen()
    curset()
    cx.decho(2)
    printNimsxR(nimsx2,randcol(),xpos = cx.tw - 42)
    #printBigLetters("MINI",xpos = 102,fun = true)  # also ok
    printLn("Finance Center",yellowgreen,xpos = cx.tw -35)  
    var ymd = "Yahoo Market Data delayed 15 minutes"
    printLn(ymd,truetomato,xpos = cx.tw - 41)
    curset()
    cx.decho(2)
            
    curdn(10)
    showCFX2(@["EURHKD","GBPHKD","JPYHKD","AUDHKD","CNYHKD"],xpos = cx.tw -41)
    curdn(3)
    showCFX2(@["EURUSD","GBPUSD","USDJPY","AUDUSD","USDCNY"],xpos = cx.tw -41)
    curdn(1)
    cx.printLn($getTime(),yellowgreen,xpos = cx.tw - 40)
    
    curset()
    cx.decho(2)
    printLn("Stock Markets",peru,xpos = mxpos)
    echo()
    showCurrentIDX("^HSI+^FTSE+^GSPC",xpos = mxpos)       
    
    cx.decho(1)
    
    ## get kitco metal prices
    ## we try to show for open markets only
    ##  
    printLn("Gold,Silver,Platinum Spot price : New York and Asia / Europe ",peru,xpos = mxpos)
    
    var kt = getContent(url)
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
          printLn("All Metal Markets Closed",truetomato,xpos = mxpos)
          for x in 13.. <ktd.len:
              metal()   
              
              
    elif nymarket == true and asiaeuropemarket == true:
          # both open we show new york gold       
          for x in 0.. ktd.len - 18:
            metal()                                       

  
    elif nymarket == true and asiaeuropemarket == false:
        # ny  open we show new york gold       
          for x in 0.. <ktd.len - 18:
            metal()                                                                     


    elif nymarket == false and asiaeuropemarket == true:
          # asiaeuropemarket  open we show asiaeuropemarket gold       
          for x in 13.. <ktd.len:
            metal()                        

        
# main
var timespace = 60000
if len(commandLineParams()) > 0:
    for param in commandLineParams():
       if parseInt(param) > 10 and parseInt(param) < 600:
          timespace = parseInt(param) * 1000 # allow min 10 sec max 10 minutes refresh
       elif parseInt(param) < 10 :
          timespace = 10000  # min allowed 10 secs
       else:   
          timespace = 600 * 1000 # in any case refresh every 10 minutes  
else:
     timespace = 60000 # default update every 1 min 
          
    
var lpx = 0 # counter
var ts = timespace div 1000

while true:
  inc lpx
  doit()
  print("Updated : " & $lpx & " times ",cx.gray,xpos = mxpos)
  printLn("Next Update: " & $(getLocalTime(getTime()) + initInterval(0,ts,0,0,0)),pastelGreen,xpos = cx.tw - 45)
  #hlineLn()
  print("{:<14}".fmt("Application :"),pastelgreen,xpos = mxpos)
  print(extractFileName(getAppFilename()),brightblack)
  print(" | ",brightblack)
  print("Nim : ",lime)
  print(NimVersion & " | ",brightblack)
  print("cx : ",peru)
  print(CXLIBVERSION,brightblack)
  print(" | ",brightblack)
  cx.qqTop()
  print(" |",gray)  
  var ntc = "Metal : Kitco, Market Data : Yahoo Finance"
  printLn(ntc,gray,xpos = cx.tw - ntc.len - 3)
  curset()
  sleep(timespace)
  
  
cx.doFinish()   