import nimcx,nimFinLib,nimdataframe

# nfT55.nim
# 
# example prog to display EMA,WMA,SMA indicators with data from Alpha Vantage
# 
# Note : some csv files will be created too ,  delete them if not needed
# 
#        Run in full terminal window
#        
#        

getavSMA("MSFT",apikey="demo",xpos = 3)    
curup(23)
getavWMA("MSFT",apikey="demo" ,xpos = 46)       
curup(23)
getavEMA("MSFT",apikey="demo",xpos = 90) 

decho(2)
doFinish()
                                  
