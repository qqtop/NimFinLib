# NimFinLib

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![Join the chat at https://gitter.im/qqtop/NimFinLib](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/qqtop/NimFinLib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Financial Library for Nim language
==================================


![Image](http://qqtop.github.io/minifin1.png?raw=true)
Example screen from minifin.nim



| Library    | Status      | Version | License        | OS     | Compiler       |
|------------|-------------|---------|----------------|--------|----------------|
| nimFinLib  | Development | 0.2.6   | MIT opensource | Linux  | Nim 0.12.1 up  |




Data gathering and calculations support 
----------------------------------------

              Yahoo historical stock data
              
              Yahoo current quotes and forex rates
              
              Dataframe like structure for easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations
              
              Ema calculation
              
              Date manipulations
              
              
              
              
API Docs
--------

      http://qqtop.github.io/nimFinLib.html

      for a library pertaining to Hongkong Stocks see

      http://qqtop.github.io/libFinHk.html

Tests and Examples
------------------

      nimFinTxx   are test programs to show use of the library .
      
      examplex    short examples 
      
      nfT52       the main testing suite
      
      testMe      automated example1      
      

Requirements

      strfmt and random can be installed with nimble
      
      statistics is included
      
      cx  from  https://github.com/qqtop/NimCx
      


example1.nim 
------------

```nimrod         
import nimFinLib,times,strfmt,strutils,cx

# show latest stock quotes
showCurrentStocks("IBM+BP.L+0001.HK")
decho(2)

# get latest historic data for a stock
var ibm = initStocks()
ibm = getsymbol2("IBM","2000-01-01",getDateStr())

# show recent 5 historical data rows
showhistdata(ibm,5)

# show data between 2 dates incl.
showhistdata(ibm,"2015-01-12","2015-01-19")

# show recent 5 returns based on closing price
showdailyReturnsCl(ibm,5)     
decho(3)


# Show stock name and latest adjusted close
msgg() do: echo "{:<8} {:<11} {:>15}".fmt("Code","Date","Adj.Close") 
echo  "{:<8} {:<11} {:>15}".fmt(ibm.stock,ibm.date.last,ibm.adjc.last)
decho(1)


# Show some forex data

showCurrentForex(@["EURUSD","GBPHKD","CADEUR","AUDNZD"])
decho(3)

```


Want to try ? 

     Get the file testMe.nim and put it into a new directory
     then execute this :
              
         nim c -r -d:ssl testMe
       
     strfmt module will need to be installed beforehand. 
     

NOTE : 
  
     Improvements may be made at any time.              
     Forking ,testing, suggestions ,ideas are welcome.
     This is development code , hence use at your own risk.
     
     Tested Ubuntu 14.04 LTS , openSuse 13.2 ,openSuse Leap42.1 
              
              
Example output of nfT52 :





⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Testing nimFinLib                          ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


Processing   : SNP      2014-01-01  2016-01-08  --> Rows processed : 510
Processing   : SBUX     2014-01-01  2016-01-08  --> Rows processed : 510                                                   
Processing   : IBM      2014-01-01  2016-01-08  --> Rows processed : 510                                                   
Processing   : BP.L     2014-01-01  2016-01-08  --> Rows processed : 526                                                   

Processing   : ^GSPC    2014-01-01  2016-01-08  --> Rows processed : 510
Processing   : ^HSI     2014-01-01  2016-01-08  --> Rows processed : 502                                                   



⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for Account , Portfolio ,Stocks types  ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


TestPortfolio                                                                                                              
Name    : SNP                                                                                                              
Open    : 53.799999                                                                                                        
High    : 55.419998                                                                                                        
Low     : 53.490002                                                                                                        
Close   : 53.709999                                                                                                        
Volume  : 220600.0                                                                                                         
AdjClose: 53.709999                                                                                                        
StDevOp : 10.67459501174046                                                                                                
StDevHi : 10.62236409109998                                                                                                
StDevLo : 10.71805306352667                                                                                                
StDevCl : 10.6855448865523                                                                                                 
StDevVo : 98231.33052887539                                                                                                
StDevClA: 9.127885080806593                                                                                                

Using shortcut to display most recent open value                                                                           
53.799999                                                                                                                  


Show hist. stock data between 2 dates incl. if available                                                                   

Code    Date             Open      High       Low     Close        Volume  AdjClose
SNP     2015-11-13       65.3     65.37     64.09     64.62        169300     64.62
SNP     2015-11-12      67.38     68.78     66.21     67.39        157700     67.39                                        
SNP     2015-11-11      68.29     68.29     66.87     67.04         90400     67.04                                        
SNP     2015-11-10      68.75     68.86     68.16     68.53        121300     68.53                                        
SNP     2015-11-09         70     70.23     68.83     69.27        150400     69.27                                        
SNP     2015-11-06      70.58     70.97      69.9     70.77         86400     70.77                                        
SNP     2015-11-05      72.86     73.41     72.43     72.81         72300     72.81                                        
SNP     2015-11-04      74.03     74.18     72.79     73.04        177700     73.04                                        
SNP     2015-11-03      72.42      74.2      72.4     73.61        120900     73.61                                        
SNP     2015-11-02      71.57     72.64     71.19     72.36        144800     72.36                                        
SNP     2015-10-30      71.65     72.61     71.33     72.08        120700     72.08                                        
SNP     2015-10-29      72.34     72.56     71.49     72.25        168000     72.25                                        
SNP     2015-10-28      73.07     74.16     72.11     73.45        183400     73.45                                        
SNP     2015-10-27      73.13     73.32     72.61      73.1        158200      73.1                                        
SNP     2015-10-26      73.99     73.99     73.18     73.38        124600     73.38                                        
SNP     2015-10-23      75.41     75.53     74.64     75.39        150800     75.39                                        
SNP     2015-10-22      72.61     73.82     72.61     73.72        110700     73.72                                        
SNP     2015-10-21       73.6      73.7     72.33     72.48        116400     72.48                                        
SNP     2015-10-20       73.8     74.42     73.58     73.93        106000     73.93                                        
SNP     2015-10-19      74.46     74.46     73.39     73.92        159400     73.92                                        
SNP     2015-10-16      73.48     74.13     72.95     73.88        140500     73.88                                        
SNP     2015-10-15      73.22     73.77        72     73.77        164900     73.77                                        
SNP     2015-10-14      72.07     72.59     71.48     71.85        139800     71.85                                        
SNP     2015-10-13       71.3     71.99      70.6     70.83        155100     70.83                                        
SNP     2015-10-12      72.32      72.4     70.98      71.1        129500      71.1                                        





⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for dailyReturns                     ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


Most recent 5 dailyreturns based on close price

Code     Date               Returns
SNP     2016-01-06    -0.0411618147
SNP     2016-01-05     0.0008557076                                                                                        
SNP     2016-01-04    -0.0274066285                                                                                        
SNP     2015-12-31    -0.0010003501                                                                                        
SNP     2015-12-30    -0.0211525646                                                                                        

Most recent 5 dailyreturns based on adjc price

Code     Date               Returns
SNP      2016-01-06    -0.0411618147
SNP      2016-01-05     0.0008557076                                                                                       
SNP      2016-01-04    -0.0274066285                                                                                       
SNP      2015-12-31    -0.0010003501                                                                                       
SNP      2015-12-30    -0.0211525646                                                                                       

Show tail 2 rows = most recent dailyreturns based on adjc
2016-01-07  -0.04116181470352487
2016-01-06  0.0008557076844086797                                                                                          

Code     Date               Returns
SNP      2016-01-06    -0.0411618147
SNP      2016-01-05     0.0008557076                                                                                       

Returns on Close Price calculated : 506
DailyReturns sum based on Close Price     : ⵉ -0.4413590833981103
Returns on Close Price calculated : 506
DailyReturns sum based on AdjClose Price  : ⵉ -0.3571769131633352


⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for timeseries                       ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘



Test timeseries - show recent 5 rows for SNP                                                                               

Head                                                                                                                       
Date          Adj.Close 
2016-01-07        53.71                                                                                                    
2016-01-06        56.12                                                                                                    
2016-01-05        58.43                                                                                                    
2016-01-04        58.38                                                                                                    
2015-12-31        59.98                                                                                                    
Tail
Date          Adj.Close 
2014-01-08      70.0778                                                                                                    
2014-01-07      70.7856                                                                                                    
2014-01-06      71.0062                                                                                                    
2014-01-03      72.3208                                                                                                    
2014-01-02      73.4791                                                                                                    

Timeseries display test 
first     2014-01-02 73.4791
head(1)   2014-01-02 73.4791
last      2016-01-07 53.71
tail(1)   2016-01-07 53.71


⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for ema (exponential moving average)   ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


EMA for : SNP                                                                                                              

Date                EMA 
2016-01-07      59.6975 
2016-01-06      60.2678                                                                                                    
2016-01-05      60.6628                                                                                                    
2016-01-04      60.8754                                                                                                    
2015-12-31      61.1131                                                                                                    


⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for statistics on Stocks type          ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


---------------------------------------------------------------------------------------------------------------------------
Stats for : SNP based on Open
RunningStat Sum     : 41761.08999                                                                                          
RunningStat Var     : 113.94698                                                                                            
RunningStat mean    : 82.20687                                                                                             
RunningStat Std     : 10.67460                                                                                             
RunningStat Max     : 105.67000                                                                                            
RunningStat Min     : 53.80000                                                                                             
---------------------------------------------------------------------------------------------------------------------------
Stats for : SNP based on High
RunningStat Sum     : 42030.00001                                                                                          
RunningStat Var     : 112.83462                                                                                            
RunningStat mean    : 82.73622                                                                                             
RunningStat Std     : 10.62236                                                                                             
RunningStat Max     : 105.88000                                                                                            
RunningStat Min     : 55.42000                                                                                             
---------------------------------------------------------------------------------------------------------------------------
Stats for : SNP based on Low
RunningStat Sum     : 41459.59999                                                                                          
RunningStat Var     : 114.87666                                                                                            
RunningStat mean    : 81.61339                                                                                             
RunningStat Std     : 10.71805                                                                                             
RunningStat Max     : 104.64000                                                                                            
RunningStat Min     : 53.49000                                                                                             
---------------------------------------------------------------------------------------------------------------------------
Stats for : SNP based on Close
RunningStat Sum     : 41744.18995                                                                                          
RunningStat Var     : 114.18087                                                                                            
RunningStat mean    : 82.17360                                                                                             
RunningStat Std     : 10.68554                                                                                             
RunningStat Max     : 105.28000                                                                                            
RunningStat Min     : 53.71000                                                                                             
---------------------------------------------------------------------------------------------------------------------------
Stats for : SNP based on Volume
RunningStat Sum     : 85075200.00000                                                                                       
RunningStat Var     : 9649394297.47317                                                                                     
RunningStat mean    : 167470.86614                                                                                         
RunningStat Std     : 98231.33053                                                                                          
RunningStat Max     : 912900.00000                                                                                         
RunningStat Min     : 41700.00000                                                                                          
---------------------------------------------------------------------------------------------------------------------------
Stats for : SNP based on Adj.Close
RunningStat Sum     : 39917.67587                                                                                          
RunningStat Var     : 83.31829                                                                                             
RunningStat mean    : 78.57810                                                                                             
RunningStat Std     : 9.12789                                                                                              
RunningStat Max     : 99.46650                                                                                             
RunningStat Min     : 53.71000                                                                                             


Show full statistics - standard display                                                                                    

Item              Open       High        Low      Close        Volume  Adj Close
sum            41761.1      42030    41459.6    41744.2   8.50752e+07    39917.7
variance       113.947    112.835    114.877    114.181   9.64939e+09    83.3183                                           
mean           82.2069    82.7362    81.6134    82.1736        167471    78.5781                                           
stddev         10.6746    10.6224    10.7181    10.6855       98231.3    9.12789                                           
max             105.67     105.88     104.64     105.28        912900    99.4665                                           
min               53.8      55.42      53.49      53.71         41700      53.71                                           


Show full statistics - transposed display                                                                                  

Item                  sum      variance          mean        stddev           max           min
Open              41761.1       113.947       82.2069       10.6746        105.67          53.8
High                42030       112.835       82.7362       10.6224        105.88         55.42                            
Low               41459.6       114.877       81.6134       10.7181        104.64         53.49                            
Close             41744.2       114.181       82.1736       10.6855        105.28         53.71                            
Volume        8.50752e+07   9.64939e+09        167471       98231.3        912900         41700                            
Adj Close         39917.7       83.3183       78.5781       9.12789       99.4665         53.71                            




⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for quantile , kurtosis & skewness    ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


0.25  : 76.625                                                                                                             
0.50  : 83.07500099999999                                                                                                  
0.75  : 89.959999                                                                                                          
1.00  : 105.669998                                                                                                         


Kurtosis open  : -0.250675736202794                                                                                        
Kurtosis close : -0.2677218183959584                                                                                       


Skewness open  : -0.4144430708240852                                                                                       
Skewness close : -0.405618397427534                                                                                        


⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for date and logistic helper procs   ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


 Interval Information

Date Range : 2014-01-02  -  2016-01-07                                                                                     
Years      : 2.013698630136986                                                                                             
Months     : 24.16438356164384                                                                                             
Weeks      : 105.0                                                                                                         
Days       : 735.0                                                                                                         
Hours      : 17640.0                                                                                                       
Mins       : 1058400.0                                                                                                     
Secs       : 63504000.0                                                                                                    

Extract items from date string 2014-01-02                                                                                  
2014 01 02                                                                                                                 


 Test validDate proc

2015-05-10  true
2015-02-29  false
3000-15-10  false
1899-12-31  false
2018-12-31  true
2016-02-29  true
2017-02-29  false
2018-02-29  false
2019-02-29  false
2019-01-02  true
2016-01-08  true

 Test plusDays and minusDays proc 

Indate     : 2016-01-08                                                                                                    
Outdate +7 : 2016-01-15                                                                                                    
Outdate -7 : 2016-01-01                                                                                                    

 Testing logistics functions

          Value       logisticf   logistic_derivative
1.57186817512233 0.82804976833744 0.14238334949374                                                                         
1.55746375163890 0.82598911656667 0.14373109588008                                                                         
0.40051345565729 0.59881101709815 0.24023638290002                                                                         
1.67435472863364 0.84215555626895 0.13292957531428                                                                         
0.02891038296660 0.50722709237551 0.24994776913579                                                                         
0.50547608200303 0.62374536517618 0.23468708459741                                                                         
0.80136316066383 0.69026599887327 0.21379884967275                                                                         
1.66280508595663 0.84061419318772 0.13398197139907                                                                         
0.96569942030549 0.72426147166333 0.19970679232739                                                                         
1.63736609244643 0.83717622247815 0.13631219499536                                                                         
0.23588242999629 0.55869869074854 0.24655446370440                                                                         


⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for Current Stocks and Indexes  - Wide View ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘



+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Stocks Current Quote                                                                                                       
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Code : AAPL       Name : Apple Inc.  Market : NMS
Date : 1/7/2016    4:00pm       Price  : 96.45    Volume :     81446988
Open : 98.71    High : 100.13   Change :￬-4.25 - -4.22% Range : 96.43 - 100.13
---------------------------------------------------------------------------------------------------------------------------
Code : IBM        Name : International Business Machines  Market : NYQ
Date : 1/7/2016    4:02pm       Price  : 132.86   Volume :      7025943
Open : 133.46   High : 135.02   Change :￬-2.31 - -1.71% Range : 132.43 - 135.02
---------------------------------------------------------------------------------------------------------------------------
Code : BP.L       Name : BP  Market : LSE
Date : 1/8/2016    1:06pm       Price  : 333.5000 Volume :     10551455
Open : 339.7000 High : 339.7130 Change :￬-4.2000 - -1.2437% Range : 329.0000 - 339.7130
---------------------------------------------------------------------------------------------------------------------------
Code : BAS.DE     Name : BASF N  Market : GER
Date : 1/8/2016    2:06pm       Price  : 64.61    Volume :      1659781
Open : 64.45    High : 65.17    Change :￪+0.14 - +0.22% Range : 64.05 - 65.17
---------------------------------------------------------------------------------------------------------------------------

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Stocks Current Quote for TestPortfolio                                                                                     
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Code : SNP        Name : China Petroleum & Chemical Corp  Market : NYQ
Date : 1/7/2016    4:02pm       Price  : 53.71    Volume :       223142
Open : 53.52    High : 55.42    Change :￬-2.41 - -4.29% Range : 53.49 - 55.42
---------------------------------------------------------------------------------------------------------------------------
Code : SBUX       Name : Starbucks Corporation  Market : NMS
Date : 1/7/2016    4:00pm       Price  : 56.69    Volume :     11162152
Open : 56.88    High : 57.91    Change :￬-1.44 - -2.48% Range : 56.16 - 57.91
---------------------------------------------------------------------------------------------------------------------------
Code : IBM        Name : International Business Machines  Market : NYQ
Date : 1/7/2016    4:02pm       Price  : 132.86   Volume :      7025943
Open : 133.46   High : 135.02   Change :￬-2.31 - -1.71% Range : 132.43 - 135.02
---------------------------------------------------------------------------------------------------------------------------
Code : BP.L       Name : BP  Market : LSE
Date : 1/8/2016    1:06pm       Price  : 333.5000 Volume :     10551455
Open : 339.7000 High : 339.7130 Change :￬-4.2000 - -1.2437% Range : 329.0000 - 339.7130
---------------------------------------------------------------------------------------------------------------------------
Code :  ^GSPC      Name :  S&P 500          Market :  SNP    Date :  1/7/2016   4:29pm    Index :  ￬1943.09
Open : 1985.32   Change : ￬ -47.17 - -2.37%  Range : 1938.83 - 1985.32 
---------------------------------------------------------------------------------------------------------------------------
Code :  ^GSPC      Name :  S&P 500          Market :  SNP    Date :  1/7/2016   4:29pm    Index :  ￬1943.09
Open : 1985.32   Change : ￬ -47.17 - -2.37%  Range : 1938.83 - 1985.32 
---------------------------------------------------------------------------------------------------------------------------
Code :  ^HSI       Name :  HANG SENG INDEX  Market :  HKG    Date :  1/8/2016   4:01pm    Index :  ￪20453.71
Open : 20491.88  Change : ￪ +120.37 - +0.59%  Range : 20324.62 - 20596.42 
---------------------------------------------------------------------------------------------------------------------------


⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for Current Stocks and Indexes  - Compact View ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘



+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Stocks Current Quote                                                                                                       
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Code : AAPL        Market : NMS
                               ┌─┐ ┌─╴    ╷ ╷ ┌─╴
Date : 1/7/2016    4:00pm    ￬ └─┤ ├─┐    └─┤ └─┐
                               ╶─┘ └─┘  .   ╵ ╶─┘
Open : 98.71    High : 100.13  Change : -4.25 - -4.22%                                                                     
Range: 96.43 - 100.13             Volume : 81446988                                                                        
----------------------------------------------------------------------                                                     
Code : IBM         Market : NYQ
                                 ╷ ╶─┐ ╶─┐    ┌─┐ ┌─╴
Date : 1/7/2016    4:02pm    ￬   │ ╶─┤ ┌─┘    ├─┤ ├─┐
                                 ╵ ╶─┘ └─╴  . └─┘ └─┘
Open : 133.46   High : 135.02  Change : -2.31 - -1.71%                                                                     
Range: 132.43 - 135.02             Volume : 7025943                                                                        
----------------------------------------------------------------------                                                     
Code : BP.L        Market : LSE
                               ╶─┐ ╶─┐ ╶─┐    ┌─╴ ┌─┐ ┌─┐ ┌─┐
Date : 1/8/2016    1:06pm    ￬ ╶─┤ ╶─┤ ╶─┤    └─┐ │ │ │ │ │ │
                               ╶─┘ ╶─┘ ╶─┘  . ╶─┘ └─┘ └─┘ └─┘
Open : 339.7000 High : 339.7130Change : -4.2000 - -1.2437%                                                                 
Range: 329.0000 - 339.7130             Volume : 10551455                                                                   
----------------------------------------------------------------------                                                     
Code : BAS.DE      Market : GER
                               ┌─╴ ╷ ╷    ┌─╴   ╷
Date : 1/8/2016    2:06pm    ￪ ├─┐ └─┤    ├─┐   │
                               └─┘   ╵  . └─┘   ╵
Open : 64.45    High : 65.17   Change : +0.14 - +0.22%                                                                     
Range: 64.05 - 65.17             Volume : 1659781                                                                          
----------------------------------------------------------------------                                                     

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Stocks Current Quote for TestPortfolio                                                                                     
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Code : SNP         Market : NYQ
                               ┌─╴ ╶─┐    ╶─┐   ╷
Date : 1/7/2016    4:02pm    ￬ └─┐ ╶─┤      │   │
                               ╶─┘ ╶─┘  .   ╵   ╵
Open : 53.52    High : 55.42   Change : -2.41 - -4.29%                                                                     
Range: 53.49 - 55.42             Volume : 223142                                                                           
----------------------------------------------------------------------                                                     
Code : SBUX        Market : NMS
                               ┌─╴ ┌─╴    ┌─╴ ┌─┐
Date : 1/7/2016    4:00pm    ￬ └─┐ ├─┐    ├─┐ └─┤
                               ╶─┘ └─┘  . └─┘ ╶─┘
Open : 56.88    High : 57.91   Change : -1.44 - -2.48%                                                                     
Range: 56.16 - 57.91             Volume : 11162152                                                                         
----------------------------------------------------------------------                                                     
Code : IBM         Market : NYQ
                                 ╷ ╶─┐ ╶─┐    ┌─┐ ┌─╴
Date : 1/7/2016    4:02pm    ￬   │ ╶─┤ ┌─┘    ├─┤ ├─┐
                                 ╵ ╶─┘ └─╴  . └─┘ └─┘
Open : 133.46   High : 135.02  Change : -2.31 - -1.71%                                                                     
Range: 132.43 - 135.02             Volume : 7025943                                                                        
----------------------------------------------------------------------                                                     
Code : BP.L        Market : LSE
                               ╶─┐ ╶─┐ ╶─┐    ┌─╴ ┌─┐ ┌─┐ ┌─┐
Date : 1/8/2016    1:06pm    ￬ ╶─┤ ╶─┤ ╶─┤    └─┐ │ │ │ │ │ │
                               ╶─┘ ╶─┘ ╶─┘  . ╶─┘ └─┘ └─┘ └─┘
Open : 339.7000 High : 339.7130Change : -4.2000 - -1.2437%                                                                 
Range: 329.0000 - 339.7130             Volume : 10551455                                                                   
----------------------------------------------------------------------                                                     
Code : ^GSPC       Market : SNP
                                 ╷ ┌─┐ ╷ ╷ ╶─┐    ┌─┐ ┌─┐
Date : 1/7/2016    4:29pm    ￬   │ └─┤ └─┤ ╶─┤    │ │ └─┤
                                 ╵ ╶─┘   ╵ ╶─┘  . └─┘ ╶─┘
Open : 1985.32  High : 1985.32  Change : -47.17 - -2.37%                                                                   
Range: 1938.83 - 1985.32                                                                                                   
----------------------------------------------------------------------                                                     
Code : ^GSPC       Market : SNP
                                 ╷ ┌─┐ ╷ ╷ ╶─┐    ┌─┐ ┌─┐
Date : 1/7/2016    4:29pm    ￬   │ └─┤ └─┤ ╶─┤    │ │ └─┤
                                 ╵ ╶─┘   ╵ ╶─┘  . └─┘ ╶─┘
Open : 1985.32  High : 1985.32  Change : -47.17 - -2.37%                                                                   
Range: 1938.83 - 1985.32                                                                                                   
----------------------------------------------------------------------                                                     
Code : ^HSI        Market : HKG
                               ╶─┐ ┌─┐ ╷ ╷ ┌─╴ ╶─┐    ╶─┐   ╷
Date : 1/8/2016    4:01pm    ￪ ┌─┘ │ │ └─┤ └─┐ ╶─┤      │   │
                               └─╴ └─┘   ╵ ╶─┘ ╶─┘  .   ╵   ╵
Open : 20491.88 High : 20596.42 Change : +120.37 - +0.59%                                                                  
Range: 20324.62 - 20596.42                                                                                                 
----------------------------------------------------------------------                                                     




⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Testing getSymbol3 - Additional stock info  ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘




Stock Code : AAPL
---------------------------------------------------------------------------------------------------------------------------
Price             :        96.45                                                                                           
Change            :        -4.25                                                                                           
Volume            :   8.1447e+07                                                                                           
Avg.DailyVolume   :  4.42366e+07                                                                                           
Market            :        "NMS"                                                                                           
MarketCap         :      537.74B                                                                                           
BookValue         :         21.4                                                                                           
Ebitda            :       82.49B                                                                                           
DividendPerShare  :         2.08                                                                                           
DividendPerYield  :         2.03                                                                                           
EarningsPerShare  :         9.22                                                                                           
52 Week High      :       134.54                                                                                           
52 Week Low       :           92                                                                                           
50 Day Mov. Avg   :       111.88                                                                                           
200 Day Mov. Avg  :       115.93                                                                                           
P/E               :        10.46                                                                                           
P/E Growth Ratio  :         0.74                                                                                           
Price Sales Ratio :          2.4                                                                                           
Price Book Ratio  :         4.71                                                                                           
Price Short Ratio :         1.92                                                                                           






⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Tests for Forex rates                      ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘



Yahoo Exchange Rates
Currencies       Cur  Rate
EURUSD           USD  1.0865                                                                                               
GBPUSD           USD  1.4585                                                                                               
GBPHKD           HKD  11.322                                                                                               
JPYUSD           USD  0.0085                                                                                               
AUDUSD           USD  0.7016                                                                                               
EURHKD           HKD  8.4345                                                                                               
JPYHKD           HKD  0.0656                                                                                               
CNYHKD           HKD  1.1783                                                                                               

Current EURUSD Rate : 1.0865                                                                                               
Current EURHKD Rate : 8.4345                                                                                               



⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Test for Kitco Metal Prices                ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘

Gold,Silver,Platinum Spot price : New York and Asia / Europe 
New York Spot Price                             MARKET IS OPEN
                        Will close in 8 hour 55 minutes
   ----------------------------------------------------------------------
   Metals          Bid        Ask           Change        Low       High 
   ----------------------------------------------------------------------
   Gold         1099.90     1100.90     -9.30  -0.84%    1099.40  1101.20 
   Silver         14.05       14.15     -0.25  -1.78%      13.97    14.15 
   Platinum      871.00      876.00     -4.00  -0.46%     869.00   876.00 
   Palladium     495.00      500.00     +4.00  +0.81%     495.00   500.00 
   ----------------------------------------------------------------------
   Last Update on Jan 08, 2016 at 08:21.27 New York Time
   ----------------------------------------------------------------------



⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘
⌘  Testing Utility Procs                      ⌘
⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘⌘


Test  : presentValue 
4778.206586496049
4778.206586496049

Test  : presentValueFV
5453.943226371459
5453.943226371459


___________________________________________________________________________________________________________________________
Application : nfT52 | Nim : 0.12.1 | cx : 0.9.6 | qqTop - 2016
Elapsed     : 9.994 secs

     

              
              
