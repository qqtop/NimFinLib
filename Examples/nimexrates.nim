import nimcx

# example for fetching exchangrates from Alpha Vantage api


# nimexrate
# 
# test to pull real time exchange rates using Alpha Vantage Api call
#
# status : ok
# 
# 2017-11-18
# 
# this returns json like so
# {
# 
#     "Realtime Currency Exchange Rate": {
#         "1. From_Currency Code": "BTC",
#         "2. From_Currency Name": "Bitcoin",
#         "3. To_Currency Code": "CNY",
#         "4. To_Currency Name": "Chinese Yuan",
#         "5. Exchange Rate": "48524.87322480",
#         "6. Last Refreshed": "2017-11-06 10:51:48",
#         "7. Time Zone": "UTC"
#     }
# 
# }
# 


let apikey = ""


if apikey == "":
   
   echo()
   printLnBiCol("Error : Please provide your free Alpha Vantage api key.",red,bblack,":",0,true,{}) 
   doByeBye()

#  add your own curpair 
let currencypairs = @[["CNY","HKD"],
                      ["USD","HKD"],
                      ["GBP","HKD"],
                      ["CAD","HKD"],
                      ["USD","JPY"],
                      ["GBP","USD"],
                      ["GBP","EUR"]]


proc currequeststring(cur1,cur2:string):string =
  result = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=$1&to_currency=$2&apikey=$3" % [cur1,cur2,apikey]



proc getData1*(url:string):auto =
  ## getData1
  ## 
 
  try:
       var zcli = newHttpClient()
       result  = zcli.getcontent(url)   # orig test data
  except :
       printLnBiCol("Error : " & url & " content could not be fetched . Retry with -d:ssl",red,bblack,":",0,true,{}) 
       printLn(getCurrentExceptionMsg(),red,xpos = 9)
       doFinish()

var refdate = ""
proc getexrate[T](bdata:T,xpos:int=3) =
    var adata = bdata
    var fromcurcode = ""
    var fromcurname = ""
    var tocurcode = ""
    var tocurname = ""
    var exchangerate = ""
    var lastdate = ""
    var timezone = ""
        
    for key,value in mpairs(adata):      
       for key2,value2 in mpairs(value):
          case ($key2)
        
            of ("1. From_Currency Code") : fromcurcode  = $value2 
            of ("2. From_Currency Name") : fromcurname  = $value2 
            of ("3. To_Currency Code")   : tocurcode    = $value2
            of ("4. To_Currency Name")   : tocurname    = $value2
            of ("5. Exchange Rate")      : exchangerate = $value2
            of ("6. Last Refreshed")     : lastdate     = $value2
            of ("7. Time Zone")          : timezone     = $value2 
            else:  discard
            
    printLnBiCol(fmtx(["","","","",">10"],unquote(fromcurcode), "/" , unquote(tocurcode) , " : " , unquote(exchangerate)),xpos=xpos) 
    refdate = lastdate

cleanscreen() 
decho(3)
var myxpos = 3
printLnBiCol("Realtime Exchange Rate      ",colleft=truetomato,colRight = lightslategray,sep = " ",xpos = myxpos,styled={stylereverse})    
for ufox in  0..<currencypairs.len:   
   var cxdata = parseJson(getdata1(currequeststring(currencypairs[ufox][0],currencypairs[ufox][1])))
   getexrate(cxdata,xpos=myxpos)

printlnBiCol("Data    : Alpha Vantage     ",colLeft = gray,xpos = myxpos ,styled = {stylereverse})
printLnBiCol("UTC " & $(getTimeZone() div 3600) & "  : " & now(),colLeft = pastelblue,colRight = slategray,xpos = myxpos)  


doFinish()
