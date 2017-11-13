import nimcx,os

# nimexrateE1
# 
# Example  to pull real time exchange rates using Alpha Vantage Api call
#
# status : ok
# 
# 2017-11-13
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

var apikey = ""
if paramcount() == 1:
   apikey = paramStr(1)


if apikey == "":
   echo()
   printLnBiCol("Error : Please provide your Alpha Vantage api key in code or via command line.",red,bblack,":",0,true,{}) 
   doByeBye()

let ufo1 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=CNY&to_currency=HKD&apikey=$1" % [apikey]

let ufo2 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=GBP&to_currency=HKD&apikey=$1" % [apikey]

let ufo3 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=EUR&to_currency=HKD&apikey=$1" % [apikey]

let ufo4 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=AUD&to_currency=HKD&apikey=$1" % [apikey]

let ufo5 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=CAD&to_currency=HKD&apikey=$1" % [apikey]

let ufo6 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=JPY&apikey=$1" % [apikey]

let ufo7 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=GBP&to_currency=EUR&apikey=$1" % [apikey]

let ufo8 = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=GBP&to_currency=USD&apikey=$1" % [apikey]


#  add your own curpair request above and add it to currencypairs below

let currencypairs = @[ufo1,ufo2,ufo3,ufo4,ufo5,ufo6,ufo7,ufo8]

proc getData1*(url:string):auto =
  ## getData
  ## 
 
  try:
       var zcli = newHttpClient()
       result  = zcli.getcontent(url)   # orig test data
  except :
       printLnBiCol("Error : " & url & " content could not be fetched . Retry with -d:ssl",red,bblack,":",0,true,{}) 
       printLn(getCurrentExceptionMsg(),red,xpos = 9)
       doFinish()

var refdate = ""
proc getexrate[T](bdata:T) =
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
            
    printLnBiCol(fmtx(["","","","",">10"],unquote(fromcurcode), "/" , unquote(tocurcode) , " : " , unquote(exchangerate)),xpos=3) 
    refdate = lastdate

cleanscreen() 
decho(3)
printLnBiCol("Realtime Exchange Rate      ",colleft=truetomato,colRight = lightslategray,sep = " ",xpos = 3,styled={stylereverse})    
for ufox in  currencypairs:   
   var cxdata = parseJson(getdata1(ufox))
   getexrate(cxdata)

printlnBiCol("Data    : Alpha Vantage     ",colLeft = gray,xpos = 3 ,styled = {stylereverse})
printLnBiCol("UTC " & $(getTimeZone() div 3600) & "  : " & now(),colLeft = pastelblue,colRight = slategray,xpos = 3)  


doFinish()
