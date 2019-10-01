# NimFinLib

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![Join the chat at https://gitter.im/qqtop/NimFinLib](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/qqtop/NimFinLib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Financial Library for Nim 
==========================
(Work in Progress)


Description: 

             Now using historic data via free apikey from Alpha Vantage. 
             Basic data fetching and data display is working.
             The indicator API does return data for some markets like USA , UK
             but not yet for others like Germany , Hongkong etc.
             The plan is to add portfolio management and analysis.
             Basic charts can currently be displayed via gnuplot.
       
Update Apr. 2018 :

             Data drawn from the API still seems to have occasional holes 
             especially for non US market stocks or is not available all
             the time . Often two or more hits are needed for the API
             to return data . Sometimes the API returns error messages
             of being hit too fast , despite one hit per second being
             the advertised capability and sufficient time spacing on the
             client side.
             Indicator data returns json data fine , but currently only for certain US stocks. 
             Batch fetching of stock data only works for US market components and may return
             a default timestamp of 1969 during off trading hours.
             
Update Oct. 2018

            Data quality and speed has slightly improved , unfortunately the free apikey now has a
            standard call-frequency limit of 4-5 requests per minute , which is much too low
            for any reasonable work.
            Of course there is the premium option which allows more requests / minute. 
            Kitco metal prices are not effected by this call limit . 
            The library has been updated to work with nim 0.19.x 
            If sudden crashes occure see : cat /dev/shm/avdata.csv
            most likely reason is inserted nagging lines by the api to ask for registration
            and once registered ask to visit their premium site.
            
             
Update Feb. 2019

            Made the library compile with latest nim devel
            Call frequency limit stated above has unfortunately not improved .
            The current nagging line is:
               "Thank you for using Alpha Vantage! Our standard API call frequency is 5 
               calls per minute and 500 calls per day."
            
            Next maybe will be looking into https://iextrading.com/developer/ , however this api is 
            mainly Us-market focused so of limited use for anyone not trading or researching there.
            At least they currently (2019-02) promise up to 100 request/sec , which is more like it.
            
            


| Library    | Status      | Version | License        | OS     | Compiler       |
|------------|-------------|---------|----------------|--------|----------------|
| nimFinLib  | Development | 0.3.0.x | MIT opensource | Linux  | Nim >= 1.0.0   |




Data gathering and calculations support 
----------------------------------------

                          
              Alpha Vantage Api support            
              
                         
              Dataframe for display and easy working with dataseries
              
              Multiple accounts and portfolios management
              
              Returns calculations and more
              
              Williams R% calculation
              
              Indicator displays
                      
              Kitco Metal Prices    
              
              US market spot prices
              
              Digital currencies 5 min intraday prices .               
              
              
              
API Docs
--------

      Planned to be in
      
      http://qqtop.github.io/nimFinLib.html

      # http://qqtop.github.io/libFinHk.html
      
  
   
Tests and Examples
------------------
    
      
      nimexrates  
      nfT53       
      nfT55  
      nfT60     
      nimmetal    
     

Requirements
------------
     
           
      nimcx         nimble install nimcx
      
      nimdataframe  nimble install https://github.com/qqtop/nimdataframe.git
      
          
 
Installation 
------------
  
       
      nimble install nimFinLib 
      
      Note : it is always a good idea to install the latest libraries
      
  
             
![Image](http://qqtop.github.io/quickStock.png?raw=true)             
Example screen from quickStock.nim   

![Image](http://qqtop.github.io/digitalcurrency.png?raw=true)             
Example screen from nfT58.nim   

![Image](http://qqtop.github.io/quickSpot.png?raw=true)             
Example screen from quickSpot.nim showing some quotes for Vanguard components.  



![Image](http://qqtop.github.io/williamsR.png?raw=true)             
Example screen from an attempt to plot williams R indicator output
plotting is done via gnuplot.nim ex https://github.com/dvolk/gnuplot.nim
             
![Image](http://qqtop.github.io/nfT53-1.png?raw=true)

![Image](http://qqtop.github.io/nfT53-2.png?raw=true)

![Image](http://qqtop.github.io/nfT53-3.png?raw=true)
Example screen from nfT53.nim


![Image](http://qqtop.github.io/nfT55.png?raw=true)
Example screen from nfT55.nim  displaying SMA,WMA,EMA Indicator data




Below screenshots of nimFinLib usage prior to demise of Yahoo Finance API on Nov 1 2017.


![Image](http://qqtop.github.io/nfT50.png?raw=true)
Example screen from nfT50.nim



![Image](http://qqtop.github.io/minifin1.png?raw=true)
Example screen from minifin.nim             
             
             
             
             
             
NOTE : 
  
     Improvements may be made at any time.              
     Forking ,testing, suggestions ,ideas are welcome.
     This is development code , use at your own risk.
     
     
     
     Tested on openSuse TumbleWeed, Debian Testing
              

![Image](http://qqtop.github.io/qqtop-small.png?raw=true)
