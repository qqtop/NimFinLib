
##
## Program     : libFinHk
##
## Status      : Development
##
## License     : MIT opensource
##
## Version     : 0.1.0
##
## Compiler    : tested on nim 0.16.1 dev
##
##
## Description : A library to support financial calculations with Nim
##
##               with focus on Hongkong Stock Exchange data 
##
##
## Project     : https://github.com/qqtop/NimFinLib
##
## Tested on   : Linux
##
## ProjectStart: 2015-07-07
## 
## Latest      : 2017-10-10 
##
## ToDo        :
##
## Programming : qqTop
##
## Contributors:
##
## Requires    : nimFinLib
##
## Notes       : it is assumed that terminal color is black background
##
##               and white text. Other color schemes may not show all output.
##
##               For comprehensive tests and usage see nimFinT3.nim & nimFinT4
##

import os,strutils,parseutils,sequtils,httpclient
import terminal,times,tables,stats
import parsecsv,streams,algorithm,math,unicode
# imports based on modules available via nimble
import nimFinLib,nimcx


let LIBFINHKVERSION* = "0.1.0"

proc hkexToYhoo*(stc:string):string =
   ## hkexToYhoo
   ##
   ## mainly used in conjunction with getHKEXcodes or getHKEXcodesFromFile
   ##
   ## converts a hkex stockcode like 00001 to 0001.HK only longer ones
   ##
   ## not starting with 0 need not be cut
   ##
   ## current yahoo historical data links for csv download need this format
   ##
   ##

   var stc1 = stc
   if stc1.len == 5 and stc.startswith("0"):
           stc1 = stc[1..4] & ".HK"
   else:
           stc1 = stc & ".HK"
   result = stc1


proc yhooToHKEX*(stc:string):string =
    ## yhooToHKEX
    ##
    ## convert a yahoo code of type 0001.HK into a HKEX code
    ##
    ## of type 00001
    ##

    var rst = ""
    if stc.endswith(".HK"):
        rst = stc.split(".HK")[0]
        while rst.len < 5:
          rst = "0" & rst
    result = rst


proc getHKEXcodes*(): seq[seq[string]] =
   ## getHKEXcodes
   ##
   ## this proc scraps public data from http://www.hkex.com.hk
   ##
   ## data returned are 3 seqs which hold stockcodes,companynames and boardlots
   ##
   ## of companies listed on the exchange mainboard .
   ##
   ## this allows to create custom portfolios,random portfolios
   ##
   ## the stock codes can be massaged into yahoo codes for further
   ##
   ## current or historical data downloads
   ##
   ## this routine was successfully tested in 2015-07
   ##
   ## it may take a few seconds as abt 1500 stocks are currently listed
   ##


   let hx ="http://www.hkex.com.hk/eng/market/sec_tradinfo/stockcode/eisdeqty_pf.htm"
   let zcli = newHttpClient(timeout = 5000)
   let html = zcli.getContent(hx)
   var stockcodes   = newSeq[string]()
   var companynames = newSeq[string]()
   var boardlots    = newSeq[string]()
   var hxcode = ""
   var coname = ""
   var boardlot = ""
   var compline = ""

   for line in html.splitLines:

       if line.contains("td class=\"verd_black12\" width=\"18%\">"):
             var ls = line.split("<td class=\"verd_black12\" width=\"18%\">")
             var ls1 = ls[1]
             var ls2 = ls1.split("</td>")
             hxcode = $ls2[0]
             if hxcode != "<b>STOCK CODE</b>":
                stockcodes.add(hxcode)

       compline = "<td class=\"verd_black12\" width=\"42%\"><a href=\"../../../invest/company/profile_page_e.asp?WidCoID=$1&amp;WidCoAbbName=&amp;Month=&amp;langcode=e\" target=\"_parent\">" % hxcode
       if line.contains(compline):
            var cls = line.split(compline)
            var cls1 = cls[1]
            var cls2 = cls1.split("</a></td>")
            coname = $cls2[0]
            coname = replace(coname,"&amp;","&")
            if coname != "<b>NAME OF LISTED SECURITIES</b>":
                companynames.add(coname)
       elif line.len < 125 and line.contains("<td class=\"verd_black12\" width=\"42%\">"):
            # there are some code w/o a profile profile_page_e
            var acls = line.split("<td class=\"verd_black12\" width=\"42%\">")
            var acls1 = acls[1]
            var acls2 = acls1.split("</td>")
            coname = $acls2[0]
            coname = replace(coname,"&amp;","&")
            if coname != "<b>NAME OF LISTED SECURITIES</b>":
               companynames.add(coname)

       if line.contains("<td class=\"verd_black12\" width=\"19%\">"):
            var bl = line.split("<td class=\"verd_black12\" width=\"19%\">")
            var bl1 = bl[1]
            var bl2 = bl1.split("</td>")
            boardlot = $bl2[0]
            if boardlot != "<b>BOARD LOT</b>":
               # we need to remove a comma
               boardlot = replace(boardlot,",","")
               boardlots.add(boardlot)

   # note that stockcodes are of form 00001
   # and like so not suitable yet for yahoo ,google or quandl etc
   # for massaging to yahoo format see hkexToYhoo

   if (stockcodes.len == companynames.len) and (companynames.len == boardlots.len):
          # save data, also overwrites any existing hkex.csv file

          let hkx = "hkex.csv"
          var f = open(hkx,fmWrite)  
          for x in 0.. <stockcodes.len:
                 f.write(stockcodes[x])
                 f.write(",")
                 f.write(companynames[x])
                 f.write(",")
                 f.writeLine(boardlots[x])
          f.close() 

          result = @[stockcodes,companynames,boardlots]
   else:
          result = @[]


proc getHKEXcodesFromFile*(fname : string):seq[seq[string]] =
      ## getHKEXcodesFromFile
      ##
      ## read a csv file created with getHKEXcodes into three seqs
      ##
      ## stockcodes,companynames,boardlots
      ##
      ##
      # if no such file we just leave

      if fileExists(fname) == false:
        printLn("File : " & fname & " not found !",red)
        result = @[]
      else:
          var stockcodes   = newSeq[string]()
          var companynames = newSeq[string]()
          var boardlots    = newSeq[string]()
          var hxcode = ""
          var coname = ""
          var boardlot = ""
          # another file check , maybe not necessary , but check if we can read fom stream
          var s = newFileStream(fname, fmRead)
          if s == nil:
              printLn("Cannot open file : " & fname,red)
              result = @[]
          else:
              var x: CsvParser
              open(x, s, fname)
              while readRow(x):
                var c = 0
                for val in items(x.row):
                     case c
                     of 0 : stockcodes.add(val)
                     of 1 : companynames.add(val)
                     of 2 : boardlots.add(val)
                     else : discard
                     inc c

              close(x)

              if (stockcodes.len == companynames.len) and (companynames.len == boardlots.len):
                     result = @[stockcodes,companynames,boardlots]
              else:
                     # try to give some indication where the error occured
                     printLn("Error in hkex.csv data. Row count differs.",red)
                     echo "Stockcodes Items   : ",stockcodes.len
                     echo "CompanyNames Items : ",companynames.len
                     echo "BoardLots Items    : ",boardlots.len
                     aline()
                     # on error we return empty
                     result = @[]



proc initHKEX*():seq[seq[string]]  =
  ## initHKEX
  ##
  ## convenience proc to load from web or read from file
  ##
  ## list of HK Stock Exchange mainboard listed stocks
  ##

  let fn = "hkex.csv"
  # check if file exists
  var nhkexcodes : seq[seq[string]]
  if fileExists(fn) == false:
       # does not exist so scrap data
       nhkexcodes = getHKEXcodes()
  # file exists so read data in
  else: 
       nhkexcodes = getHKEXcodesFromFile(fn)

  result = nhkexcodes


proc getHKEXseq*(stockslist:seq[string],acode:string):int =
    ## getHKEXseq
    ##
    ## this is used to get an index into the hkex.csv data
    ##
    ## for a single stockcode
    ##
    ## .. code-block:: nim
    ##    hkexcodes = initHKEX()
    ##    var bigMseq = newSeq[int]()
    ##    bigMseq.add(getHKEXseq(hkexcodes[0],"00880"))
    ##    echo bigMseq
    ##
    ## here hkexcodes[0] holds the list of stockcodes in HKEX format
    ## this is used to query the hkexcodes for company name and boardlots
    ##

    var c = 0
    for x in stockslist:
        if x == acode:
            result = c
            break
        else:
            result = -1
        inc c


proc hkPfseq*(anf: Portfolio;hkexcodes:seq[seq[string]]):seq[int]=
  ## hkPfseq
  ##
  ## hkPfseq returns the index seq of stocks in a Portfolio objects dx Stocks
  ##
  var pfseq = newSeq[int]()
  for x in 0.. <anf.dx.len:
      pfseq.add(getHKEXseq(hkexcodes[0],yhooToHKEX(anf.dx[x].stock)))
  result = pfseq


proc getCompanyName*(astock:Stocks):string = 
      ## getCompanyName
      ## 
      ## get the actual hk stock company name as registered in HKEX
      ##  
      ## 
      var hkexcodes = initHKEX()
      var stockseq = newSeq[int]()
      var dastock = $(astock.stock)
      dastock.removesuffix(".HK")
      if dastock.len < 5:
        dastock = "0" & dastock
      stockseq.add(getHKEXseq(hkexcodes[0],dastock))
      var compname = hkexcodes[1][stockseq[0]]
      result = compname
      


proc getBoardLot*(astock:Stocks):string = 
      ## getCompanyName
      ## 
      ## get the actual hk stock company name as registered in HKEX
      ##  
      ## 
      var hkexcodes = initHKEX()
      var stockseq = newSeq[int]()
      var dastock = $(astock.stock)
      dastock.removesuffix(".HK")
      if dastock.len < 5:
        dastock = "0" & dastock
      stockseq.add(getHKEXseq(hkexcodes[0],dastock))
      var boardlot = hkexcodes[2][stockseq[0]]
      result = boardlot
      


proc showQuoteTableHk*(apfData: Portfolio) =
     ## showQuoteTable
     ##
     ## a table with kurtosis, stdDev close ,ema22 , company name and latest quote from yahoo
     ##
     ## for usage example see nimFinT3
     ##
     const
        stockcodes   = 0
        companynames = 1
        boardlots    = 2

     var apfd      = apfData 
     var stkdata   = apfd.dx
     var hkexcodes = initHKEX()
     var stockseq  = hkPfseq(apfd,hkexcodes)

     decho(2)
     # header for the table
     println(fmtx(["<8",">10",">10",">10",">10",">16",">11",">10"],"Stock","Kurtosis","StdDev","EMA22","Close","Company","Quote","BoardLot"),green)
     try:
        for x in 0.. <stkdata.len:
            # to get ema we pass our data to the ema function
            # we want 22 days so ..
            # and we just want the newest ema data point which resides in tx[0]
            # ema returns a time series object dx,tx ,but we only need the latest ema value
            var emadata = ema(stkdata[x],22).tx.seqfirst
            # get the newest stddev of the close price
            var stddev = stkdata[x].rc[0].standardDeviation
            # get the company name
            var compname = hkexcodes[companynames][stockseq[x]]
            # get boardlot
            var blot = hkexcodes[boardlots][stockseq[x]]
            # get the latest quote for a stock
            var cquote = getCurrentQuote(stkdata[x].stock)
            # display the data rows
            echo(fmtx(["<8","",">9.3f","",">9.3f","",">9.3f","",">9.3f","",">15","",">10","",">9"],stkdata[x].stock ," ", kurtosis(stkdata[x].close)," ", stddev," ",emadata," ",seqlast(stkdata[x].close)," ",compname," ",cquote," ",blot))
     except IndexError:
         println("Calculation failed . Insufficient Historical Data",red)


proc hkRndPortfolioData*(rc:int = 10,startdate:string = "2014-01-01",enddate:string = getDateStr()):seq[Stocks] =
        # we will return a seq[Stocks] of random stocks to be selected from hkexcodes
        
        result = initPool()

        var hkexcodes= initHKEX()
        # hkexcodes now holds three seqs namely : stockcodes,companynames,boardlots
        # for easier reading we can introduce constants
        const
            stockcodes   = 0
            companynames = 1
            boardlots    = 2 

        var rc1 = 0
        while rc1 < rc:
                    # get a random number between 1 and max no of items in hkexcodes[0]
                    var rdn = getRndInt(1,hkexcodes[stockcodes].len)
                    
                    # pick the stock with index number rdn from hxc[stockcodes]
                    # and convert to yahoo format 
                    var arandomstock = hkexToYhoo(hkexcodes[stockcodes][rdn])
                                                    
                    #load the historic data for arandomstock into result
                    if arandomstock.startswith("    ") == true: discard
                    else:
                        try:  #try...except to avoid error when yahoo has no hist data for a random stock
                          var dxz = getSymbol2(arandomstock,startdate,enddate)
                          if dxz.stock.startswith("Error") == false:     # effect of errstflag in nimFinLib
                              if dxz.stock.startswith("    ") == false:  # in case of yahoo data issues
                                result.add(dxz)
                                doassert result.seqfirst.stock == dxz.stock
                                inc rc1
                        except:
                           discard

proc quickPortfolioHk*(n:int = 5):Portfolio =
    ## quickPortfolioHk
    ## 
    ## just show a random portfolio of Hongkong stocks for quick demoing
    ## 
    ## n = number of stocks in portfolio
    ## 
    ## .. code-block:: nim
    ##    import nimFinLib,libFinHk
    ##    var mypf = quickPortfolioHk()
    ##    doFinish()
    ## 
    ## 
    var rpf = initPortfolio()
    # rpf.nx holds the relevant portfolio name
    rpf.nx = "RandomTestPortfolio"
    # rpf.dx will hold the relevant historic data for all stocks
    # here we get new data and load it into the new portfolio
    rpf.dx = hkRndPortfolioData(n)                             
    decho(2)
    printLn("\nshowQuoteTableHk\n",salmon)
    showQuoteTableHk(rpf)
    printLn("\nshowStocksTable\n",salmon)
    showStocksTable(rpf)
    result = rpf


proc doFinishHk*() =
    ## doFinish
    ##
    ## a end of program routine which displays some information
    ##
    ## can be changed to anything desired
    ##
    ## and should be the last line of the application
    ##
    decho(2)
    infoLine()
    printLn(" - " & year(getDateStr()),brightblack)
    print(fmtx(["","","","",""],"Library     : ","libFinHk : ",LIBFINHKVERSION," - " ,"qqTop "),dodgerblue)
    printLn(" - " & year(getDateStr()),brightblack)
    print(fmtx(["<14"],"Elapsed     : "),yellowgreen)
    printLn(fmtx(["<",">5"],ff(epochtime() - cxstart,3),"secs"),goldenrod)
    echo()
    quit(0)



# end of HK Stock Exchange specific procs
