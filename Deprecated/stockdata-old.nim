import os,nimcx,httpclient,unicode
import nre except toSeq
import streams

# Download historical stockdata from yahoo after the major endpoint change in May 2017
# Tested ok 2017-06-05
# 
# Code adapted for Nim language from ideas in :
# https://stackoverflow.com/questions/44044263/yahoo-finance-historical-data-downloader-url-is-not-working
# 
# compile with :  nim c -d:release -d:ssl stockdata
# 
# 
# Requires : Nim compiler dev branch
#            nimble install nimcx
# 
# 
# usage:
# 
# ./stockdata                                    # some defaults for testing
# ./stockdata  BAS.DE  2015-01-01  2016-06-03    # symbol startdate enddate
# ./stockdata  0005.HK                           # symbol defaultstartdate  currentdate
# ./stockdata  0001.HK 2007-01-01                $ symbol startdate  enddate = currentdate
# 
# Note : if it fails try again .... tested with several hundred stock codes
# 

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
    while attempts < 6 and okflag == false:
        echo("Attempt No.       : ",attempts)
        cc = get_crumble_and_cookie(symbol)
        quotelink = quote_link % [symbol, time_stamp_from, time_stamp_to, events,$cc[0]]
        var zcli = newHttpClient()
        var dacooky = strip(cc[1])
        zcli.headers = newHttpHeaders({"Cookie": dacooky}) 
        try:
                var r = zcli.request(url=quotelink)
                if ($r.body).len > 0:
                   if ($r.body).contains("cookie") == true:
                      okflag = false
                      attempts += 1
                      sleepy(2 * attempts)  # do not hit poor yahoo too fast
                      result = "Symbol " & symbol & " download failed.\n\nReason : \n\n"
                      result = result & $r.body   # adding any yahoo returned error message
                      
                   else:
                      okflag = true                   
                      result = $r.body
                   
                
        except :
                # we may come here if the httpclient can not connect or there is no such symbol
                             
                attempts += 1
                okflag = false
                sleepy(2 * attempts)
                result = "Symbol " & symbol & " download failed.\n"
                break
                
let defaultstartdate = "2000-01-01"
let defaultenddate  = getDateStr()
let defaultsymbol = "0005.HK"
var fromdate = ""
var todate   = "" 
var mysymbol = ""
var pc = paramCount()
if pc > 0:
    mysymbol = paramStr(1)
else:
    printLnBicol("Using default Symbol : " & defaultsymbol)
    mysymbol = defaultsymbol    
    
if pc > 1:    
     fromdate = paramStr(2)
     if validdate(fromdate) == false:
        printLnBiCol("Invalid startdate  : " & fromdate,colLeft=red)
        printLnBicol("Using default date : " & defaultstartdate)
        fromdate = defaultstartdate
else:
    fromdate = defaultstartdate
     
if pc > 2:       
     todate = paramStr(3)
     if validdate(todate) == false:
        printLnBiCol("Invalid startdate  : " & fromdate,colLeft=red)
        printLnBicol("Using default date : " & defaultenddate)
        todate = defaultenddate
        
else:
     todate = defaultenddate     

var est = epochSecs(todate)
var esf = epochSecs(fromdate)    
var acvsfile = "$1.csv" % mysymbol    
var fsw = newFileStream(acvsfile, fmWrite)
echo()
printlnBiCol("Processing symbol : " & mysymbol)
printLnBiCol("Date range        : " & fromdate & " - " & todate)
echo()
try:
            var mydata = download_quote(symbol = mysymbol,fromdate,todate)
            var mydataline = mydata.splitLines()
            var xdata2 = ""
            for xdata in mydataline:
               xdata2 = strip(xdata,true,true)
               if xdata2.len > 0:
                  fsw.writeLine(xdata2) 
            printLnBicol("Created  File     : " & acvsfile)
            echo()
except:
            printLnBicol("Error writing to  : " & acvsfile,":",red)
            discard
            
fsw.close()
 
proc doDisplay() =
    
    var fs = newFileStream(acvsfile, fmRead)
    var data = ""
    if not isNil(fs):
       while fs.readLine(data): printLn(data)
    fs.close()
    decho(2)

echo()
doDisplay()

# comment out as needed
printLnBicol("Symbol        : " & mysymbol)
printLnBiCol("Date range    : " & fromdate & " - " & todate)
printLnBicol("Saved to      : " & acvsfile)
             
doFinish()    
