import os,cx,httpclient,strutils,nimFinLib,times,strfmt,osproc


# MINIFIN

# A MINI financial information system example
# currently set to update every minute if started w/o param
# 
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
var mmax = 0        # give it some unlikely value to adjust
var mmin = 1000000  #  

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
    
        
# main
# setup auto refresh schedule default 1 min , min 10 secs , max 10 minutes
# commandLine input in seconds 
# 

var timespace = 60000
if len(commandLineParams()) > 0:
    for param in commandLineParams():
       if parseInt(param) > 10 and parseInt(param) < 600:
          timespace = parseInt(param) * 1000 # allow min 10 sec max 10 minutes refresh
       elif parseInt(param) <= 10 :
          timespace = 10000  # min allowed 10 secs
       else:   
          timespace = 600 * 1000 # in any case refresh every 10 minutes  
else:
     timespace = 60000 # default update every 1 min 
          
    
var lpx = 0                   # reload counter
var ts = timespace div 1000   # reload timeout
var mxpos = 5                 # space from left edge for our setup here

# run forever 
while true:
      inc lpx
      doit(mxpos)
      bottomInfo(lpx,mxpos,ts)
      curset()
      sleep(timespace)
  
  
##########################################################################################