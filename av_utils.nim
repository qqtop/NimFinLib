
# av_utils.nim 
# 
# A support module for nimFinLib
# 
# this holds vars and procs for accessing the alpha vantage api
# 
# 
# strings ending with demo do not need an apikey and can be used directly
# 
# Work in progress   
# 
# Note json parsing for all these needs to be implemented as indicators have different json structures
# 
# some of them are still in beta or do not actually return data for non US market components. 
#       
# 
# 
# Last : 2018-03-04
# 
# 

import strutils


# intraday
var av_intraday_1m* =  "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=MSFT&interval=1min&apikey=demo"
var av_intraday_15m* = "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=MSFT&interval=15min&outputsize=full&apikey=demo"
var av_intraday_1m_csv* = "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=MSFT&interval=1min&apikey=demo&datatype=csv"

# daily
var av_daily* = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=MSFT&apikey=demo"
var av_daily_full* = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=MSFT&outputsize=full&apikey=demo"
var av_daily_csv* = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=MSFT&apikey=demo&datatype=csv"

# daily adjusted
var av_daily_adjusted* = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=MSFT&apikey=demo"
var av_daily_adjusted_full* = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=MSFT&outputsize=full&apikey=demo"
var av_daily_adjusted_csv* = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=MSFT&apikey=demo&datatype=csv"

proc getcallavda*(stckcode:string,apikey:string):string = 
     result = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=$1&outputsize=compact&apikey=$2&datatype=csv" % [stckcode,apikey]

proc getcallavdafull*(stckcode:string,apikey:string):string = 
     result = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=$1&outputsize=full&apikey=$2&datatype=csv" % [stckcode,apikey]
      

# weekly
var av_weekly* = "https://www.alphavantage.co/query?function=TIME_SERIES_WEEKLY&symbol=MSFT&apikey=demo"
var av_weekly_csv* = "https://www.alphavantage.co/query?function=TIME_SERIES_WEEKLY&symbol=MSFT&apikey=demo&datatype=csv"

# weekly_adjusted
var av_weekly_adjusted* = "https://www.alphavantage.co/query?function=TIME_SERIES_WEEKLY_ADJUSTED&symbol=MSFT&apikey=demo"
var av_weekly_adjusted_csv* = "https://www.alphavantage.co/query?function=TIME_SERIES_WEEKLY_ADJUSTED&symbol=MSFT&apikey=demo&datatype=csv"

# monthly
var av_monthly* = "https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol=MSFT&apikey=demo"
var av_monthly_csv* = "https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol=MSFT&apikey=demo&datatype=csv"

# monthly adjusted
var av_monthly_adjusted* = "https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY_ADJUSTED&symbol=MSFT&apikey=demo"
var av_monthly_adjusted_csv* = "https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY_ADJUSTED&symbol=MSFT&apikey=demo&datatype=csv"

# forex
var forex_btc_cny* = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=BTC&to_currency=CNY&apikey=demo"
var forex_usd_jpy* = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=JPY&apikey=demo"

proc getexchangerate*(fromCur:string,toCur:string,apikey:string):string =
     result  = "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=$1&to_currency=$2&apikey=$3" % [fromCur,toCur,apikey]

# digital currency intraday
var av_digital_intraday* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_INTRADAY&symbol=BTC&market=CNY&apikey=demo"
var av_digital_intraday_csv* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_INTRADAY&symbol=BTC&market=CNY&apikey=demo&datatype=csv"

# digital currency daily 
var av_digital_daily* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_DAILY&symbol=BTC&market=CNY&apikey=demo"
var av_digital_daily_csv* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_DAILY&symbol=BTC&market=CNY&apikey=demo&datatype=csv"

# digital currency weekly
var av_digital_weekly* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_WEEKLY&symbol=BTC&market=CNY&apikey=demo"
var av_digital_weekly_csv* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_WEEKLY&symbol=BTC&market=CNY&apikey=demo&datatype=csv"

# digital currency monthly
var av_digital_monthly* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_MONTHLY&symbol=BTC&market=CNY&apikey=demo"
var av_digital_monthly_csv* = "https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_MONTHLY&symbol=BTC&market=CNY&apikey=demo&datatype=csv"

#indicators

var av_sma* = "https://www.alphavantage.co/query?function=SMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
var av_sma_csv* = "https://www.alphavantage.co/query?function=SMA&symbol=MSFT&interval=weekly&time_period=10&series_type=open&apikey=demo"


var av_ema* = "https://www.alphavantage.co/query?function=EMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"
var av_ema_csv* = "https://www.alphavantage.co/query?function=EMA&symbol=MSFT&interval=weekly&time_period=10&series_type=open&apikey=demo"

var av_wma* = "https://www.alphavantage.co/query?function=WMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"

var av_trima* = "https://www.alphavantage.co/query?function=TRIMA&symbol=MSFT&interval=15min&time_period=10&series_type=close&apikey=demo"

var av_sector = "https://www.alphavantage.co/query?function=SECTOR&apikey=demo"

# many more to go https://www.alphavantage.co/documentation/


