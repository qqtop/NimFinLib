import os,cx,httpclient,strutils,nimFinLib,times,strfmt,osproc,parseopt2


# MINIFIN

# A MINI financial information system example
# currently set to update every minute if started w/o param
# 
# Compiler : NIM 0.12.1
# 
# Usage : minifin 20    # update every 20 seconds
# 
# terminal size : full screen 80 x 40
# font          : monospace
# fontsize      : 9 regular
# 
# profiling
# import nimProf
# nim c -d:ssl --profiler:on --stackTrace:on minifin 
# 
# 
# nim c -d:release --threads:on --gc:boehm minifin
# 
# 
# 
# 
# NOTES:

#        auto refresh schedule default 1 min , min 10 secs , max 10 minutes
#        commandLine input in seconds 
#        
#        see -h for usage  to set refreshtime (implemented) and
#        stock display ( not yet implemented)
#        
# Future :
#         further idea is to have some other prog input being polled asyncly
#         so we run minifin and another prog called blah which sends new stock codes
#         to be displayed by the running minifin if so required or redisplay prev one
#         maybe max 10 codes in form of code open high low close 
# 
# 

var mmax      = 0        # give it some unlikely value to adjust
var mmin      = 1000000  #  
var timespace = 60000    # default update every 1 min 
var MINIFINVERSION   = "1.0"
var stock = ""


proc writeVersion() = 
  printLn("minifin version : " & MINIFINVERSION,lime)
  doFinish()

proc writehelp() = 
  println("Help",yellow)
  printLn("minifin version : " & MINIFINVERSION,lime)
  println("Example usage : ",salmon)
  println("-t 10        refresh time in secs",yellowgreen)
  println("-s 0386.HK   one stock code yahoo style",yellowgreen)
  doFinish()



proc bottomInfo(lpx:int,mxpos:int,ts:int) = 
      # some bottom information 
      var mm = getOccupiedMem()
      if mm >= mmax:
         mmax = mm
      if mm < mmin:
         mmin = mm
      if mm > 1_000_000:
           GC_FullCollect() # free some memory

      #curdn(1)
      printLn("Memory  : " &  $mm &  " | Min : " & $mmin & " | Max : " & $mmax,cx.gray,xpos = mxpos)
      print("Updated : " & $lpx & " times ",cx.gray,xpos = mxpos)
      print(" Update Interval " & $ts & " secs.",cx.gray)
      printLn("Next Update: " & $(getLocalTime(getTime()) + initInterval(0,ts,0,0,0)),pastelGreen,xpos = cx.tw - 45)
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


proc doit(mxpos:int) =
    # setup the terminal
    cleanScreen()
    curset()
    cx.decho(2)
    # print the large MINI with Finance Center and Yahoo delayed notice underneath
    printNimsxR(nimsx2,randcol(),xpos = cx.tw - 42)
    #printBigLetters("MINI",xpos = 102,fun = true)  # also ok
    printLn("Finance Center",yellowgreen,xpos = cx.tw -35)  
    var ymd = "Yahoo Market Data delayed 15 minutes"
    printLn(ymd,truetomato,xpos = cx.tw - 41)
    # move cursor to top left
    curset()
    # down 2
    cx.decho(2)
    # setup for forex display on the right side
    # down 10        
    curdn(10)
    # display top forex set
    showCurrentForex(@["EURHKD","GBPHKD","JPYHKD","AUDHKD","CNYHKD"],xpos = cx.tw -41)
    # down 3
    curdn(2)
    # display second forex set and update time
    showCurrentForex(@["EURUSD","GBPUSD","USDJPY","AUDUSD","USDCNY"],xpos = cx.tw -41)
    curdn(1)
    cx.printLn($getTime(),yellowgreen,xpos = cx.tw - 40)
    # go back to top left
    curset()
    # down 2
    cx.decho(2)
    # display 3 indexes
    printLn("Stock Markets",peru,xpos = mxpos)
    echo()
    showCurrentIDX("^HSI+^FTSE+^GSPC",xpos = mxpos)       
    echo()
    # display the kitco metal price
    showKitcoMetal(xpos = mxpos)
    
        
# main loop
  
proc checkTimespace(ts:int):int = 
    var tsx = 0
    if ts > 10 and ts < 600:
           tsx = ts * 1000 # allow min 10 sec max 10 minutes refresh
    elif ts <= 10 :
           tsx = 10000  # min allowed 10 secs
    else:   
           tsx = 600 * 1000 # in any case refresh every 10 minutes  
                
    result = tsx
  
  


var filename = ""  
for kind, key, val in getopt():
  case kind
  
  of cmdArgument:
    filename = key
    
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h"   : writeHelp()
    of "version", "v": writeVersion()
    of "time","t"    : timespace = checkTimespace(parseInt(val))
    of "stock","s"   : stock = $val
    
  of cmdEnd: assert(false) # cannot happen
  
    
    
var lpx = 0                   # reload counter
#var ts = timespace div 1000   # reload timeout
var mxpos = 5                 # space from left edge for our setup here

# run forever 
while true:
      inc lpx
      doit(mxpos)
      bottomInfo(lpx,mxpos,timespace div 1000)
      curset()
      sleep(timespace)
  
  
##########################################################################################