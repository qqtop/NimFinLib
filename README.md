# NimFinLib
Financial Library for Nim language


Program.: nimFinLib  

Status..: Development - alpha

License.: MIT opensource  

Version.: 0.1

Compiler: nim development branch (nim 0.11.3 or better)

Description: A basic library for financial calculations with Nim

              Yahoo historical stock data
              
              Yahoo current quotes
              
              Dataframe like structure for easy working with dataseries
              
              Returns calculations
              
              Ema calculation
              
              Date manipulations
              
              
Documentation: see nimFinLib.html


nimFinTxx are test programs to show use of the library .



Example:
         
         
          import nimFinLib,times

          # instead of hello world 

          # show latest stock quotes
          showCurrentStocks("IBM+BP.L+0001.HK")
          echo()
          echo()

          # get latest historic data for a stock
          var ibm : Df
          ibm = getsymbol2("IBM","2014-01-01",getDateStr())
          # show recent 5 returns based on closing price
          showdailyReturnsCl(ibm,5)     
          echo()
          echo()

          # show stock name and latest adjusted close
          echo ibm.stock ,"     ",ibm.date.last,"    ",ibm.adjc.last






NOTE : 
  
     This is alpha software and may change without prior notice              
     Forking , suggestions are welcome .
              
              
              
              
