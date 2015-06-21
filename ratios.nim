import nimFinLib,strfmt,math,times


#
# --------------------------------------------------------------------------------------------
# Development snippets not ready for use yet
# --------------------------------------------------------------------------------------------
#
# maybe we should not do this and rather pipe the stuff to R or pandas
# for better results .. hmmm 
#
#
# ToDo or not ok yet
# proc sharpe ()
# 
# proc sharpeannualized ()
# 
# proc sortino ()
# 
# proc drawdown()

# Formulars ex R PortfolioAnalytics MAR risk factor
# proc downsidedeviation(R, MAR) = sqrt(1/n * sum(t=1..n)((min(R(t)-MAR, 0))^2))
# 
# proc downsidevariance(R, MAR) = 1/n * sum(t=1..n)((min(R(t)-MAR, 0))^2)
# 
# proc downsidepotential(self:Df): float = 

proc rsi* (dx:Df , N: int):Ts = 
  ## rsi
  ## 
  ## oscillator
  ## 
  ## under Development
  ## 
  ## This is not ok yet , values seem a little off
  ## 
  
  # values are off from quantmod rsi ema maybe due to
  # different smoothing
  
  # call : rsi(dfobject, numberofdays for ema)
  
  # that means we need to calc ema 2 times so we make two series
  # of our closeprices for up and down side days
  var closeup : Df
  var closedn : Df
  
  closeup.date  = @[]
  closeup.close = @[]
  closedn.date  = @[]
  closedn.close = @[]
  
  for x in 1.. <dx.close.len:
      if dx.close[x] >= dx.close[x-1]:
         closeup.date.add(dx.date[x])
         closeup.close.add(dx.close[x])
         closedn.date.add(dx.date[x])
         closedn.close.add(0.0)
         
         
      else :
         closeup.date.add(dx.date[x-1])
         closeup.close.add(0)
         closedn.date.add(dx.date[x-1])
         closedn.close.add(dx.close[x-1])
         
  var emaup = ema(closeup,N)
  var emadn = ema(closedn,N)
  var maxl = 0
  # maxl holds len of the shorter series if not equal length to avoid index errors
  maxl = min(emaup.dd.len,emadn.dd.len)
   
  var arsi : Ts
  arsi.dd = @[]
  arsi.tx = @[]
  for x in 0.. <maxl:
     # same formular given as used for rsi quantmod   
     # http://www.inside-r.org/packages/cran/TTR/docs/RSI
     # the difference could come from a smoothing factor applied
     # to the ema series see
     # http://www.inside-r.org/packages/cran/TTR/docs/ema
     let smoothf =  2.0 /float(14/7 + 1)
     # but it is not clear how it is applied
     var rsi = 100 - (100 / ( 1 + (emaup.tx[x] / emadn.tx[x]) * smoothf)) 
     arsi.dd.add(emaup.dd[x])
     arsi.tx.add(rsi)
  # we return a Ts object holding date and rsi columns
  result = arsi    
      


proc showRsi* (rsx:Ts , N:int) {.discardable.} = 
    ## showRsi 
    ## 
    ## a convenience proc to display rsi latest is on top
    ## 
    echo ()
    msgg() do : echo "{:<11} {:>11}".fmt("Date","RSI")
    for x in countdown(rsx.dd.len-1,rsx.dd.len-N,1) :
         echo "{:<11.f4} {:>11.f4} ".fmt(rsx.dd[x],rsx.tx[x])

                    

proc sharpe*(adfstock:Df, adfriskfree:Df):float = 
  ## sharpe ratios based on std.dev
  ## it does not match with R / quantmod output 
  ## 
  ## under Development
  ## 
  ## This is not ok yet 
  
  # values seem incorrect  this ratios seem to be calculated nilly willy 
  # differently everywhere
  # maybe becoz they have a 95% p value factored in or different undarlying assumtions
  # also note we use riskfree as 0  so adfriskfree is
  # currently not really required 
  # 
  # ingredients (returnsstock - returnsriskfree) / sqrt (stdev stock - riskfree)
  var retstock = dailyReturns(adfstock.close)
  var retrf    = dailyReturns(adfriskfree.close)

  var tailrows = min(retstock.len,retrf.len)
  var sumrs = sumdailyReturnsCl(adfstock)  #.close.tail(tailrows))
  var sumrr = sumdailyReturnsCl(adfriskfree) #.close.tail(tailrows))

  var stdev    = adfstock.rc[0].standardDeviation
  var stdevrf  = adfriskfree.rc[0].standardDeviation
  # pseudo below as we deduct seq from seq
  # note formular in quantmod is 
  # \frac{\overline{(R_{a}-R_{f})}}{√{σ_{(R_{a}-R_{f})}}}
  # frac(retstock - retrf) / sqrt(stdev(retstock - retrf))
  # the question is how it is calculated internaly
  # so best for us here to assume the riskfree thing = 0
  # hmm but we are still a bit off from quantmod
  # 
  var sharpx   = (sumrs - 0) / sqrt(stdev - 0)
  # testing
  #   msgy() do :
  #              echo "Sumrs  : ",sumrs
  #              echo "Sumrr  : ",sumrr
  #              echo "stdev  : ",stdev
  #              echo "stdevrf: ",stdevrf
  # end testing
  
  result = sharpx


proc stochastic(adfstock:Df):float = 
  
  # as  per http://www.fmlabs.com/reference/default.htm?url=StochasticOscillator.htm
  # under consideration
  result = 0.0  
 
proc bollingerosc(adfstock):Ts = 
    var emax = ema(adfstock,9) 
    showema(emax,10)
    var emarc : RunningStat
    var bo : Ts
    bo.dd = @[]
    bo.tx = @[]
    for x in 0.. <emax.dd.len:
        emarc.push(emax.tx[x])
        var bosc = (adfstock.close[x]-emax.tx[x]) /  emarc.standardDeviation
        bo.dd.add(emax.dd[x])
        bo.tx.add(bosc) 
    result = bo 


# again above is wrong we need to find stdev for the 9 day range not all or whatever
#     Find the 9-day moving average average (n1 + n2 ... + n9)/9
#     Find the standard deviation of the 9-days
#     Subtract 9-day Moving average from the current ruling price
#     Take the answer devide by the standard deviation
#     Answer is the BOS (Bollinger Oscillator)















# proc overbought/oversold


       



######### testing things from above


var data : Df
data = getsymbol2("0386.HK","2014-01-01",getDateStr())

var ix:Df
ix = getsymbol2("^HSI","2014-01-01",getDateStr())

var ndays = 14
# testing rsi
# does not yet line up with quantmod and should not be used
# current underlying price column is : close
# rsi is under development
# Note rsi comes in as Ts with newest value at bottom
# our displayroutine will show top down
# 
# echo ()
# msgg() do : echo "{:<11} {:>11} ".fmt("Date","RSI (ema 14)") 
# var arsi = ratios.rsi(data,ndays) 
# ratios.showRsi(arsi,5)



var bx = bollingerosc(data)

for x in 0.. <bx.dd.len:
  echo bx.dd[x],"  ",bx.tx[x]