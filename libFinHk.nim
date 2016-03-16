
##
## Program     : libFinHk
##
## Status      : Development
##
## License     : MIT opensource
##
## Version     : 0.0.7
##
## Compiler    : nim 0.13.1
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
##
import os,strutils,parseutils,sequtils,httpclient
import terminal,times,tables,random
import parsecsv,streams,algorithm,math,unicode
import stats,nimFinLib,cx

let LIBFINHKVERSION* = "0.0.7"

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
   let html = getContent(hx)
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

          var hkx = "hkex.csv"
          open(hkx, fmWrite).close()

          withFile(f, hkx, fmWrite):
             for x in 0.. <stockcodes.len:
                 f.write(stockcodes[x])
                 f.write(",")
                 f.write(companynames[x])
                 f.write(",")
                 f.writeln(boardlots[x])

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
        msgr() do : echo "File : ",fname," not found !"
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
              msgr() do: echo ("Cannot open file : " & fname)
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
                     msgr() do : echo("Error in hkex.csv data. Row count differs.")
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
  else: nhkexcodes = getHKEXcodesFromFile(fn)

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

     var stkdata = apfData.dx
     var hkexcodes = initHKEX()
     var stockseq = hkPfseq(apfData,hkexcodes)

     decho(2)
     # header for the table
     msgy() do : echo "Kurtosis , StdDev , EMA22 based on close price for ",apfdata.nx," Quote is latest info ex yahoo"
     msgg() do : echo fmtx(["<8",">9",">9",">9",">9",">15",">10",">9"],"Stock  ","   Kurtosis  ","StdDev  ","EMA22  ","    Close  ","Company  ","     Quote  "," BoardLot  ")
     try:
        for x in 0.. <stkdata.len:
            # to get ema we pass our data to the ema function
            # we want 22 days so ..
            # and we just want the newest ema data point which resides in tx[0]
            # ema returns a time series object dx,tx ,but we only need the latest ema value
            var emadata = ema(stkdata[x],22).tx[0]
            # get the newest stddev of the close price
            var stddev = stkdata[x].rc[0].standardDeviation
            # get the company name
            var compname = hkexcodes[companynames][stockseq[x]]
            # get boardlot
            var blot = hkexcodes[boardlots][stockseq[x]]
            # get the latest quote for a stock
            var cquote = getCurrentQuote(stkdata[x].stock)
            # display the data rows
            echo(fmtx(["<8","",">9.3f","",">9.3f","",">9.3f","",">9.3f","",">15","",">10","",">9"],stkdata[x].stock ," ", kurtosis(stkdata[x].close)," ", stddev," ",emadata," ",last(stkdata[x].close)," ",compname," ",cquote," ",blot))
     except IndexError:
         msgr() do: echo "Calculation failed . Insufficient Historical Data"


proc hkRandomPortfolio*(sz:int = 10,startdate:string = "2014-01-01",enddate:string = getDateStr()):(Portfolio, seq[int]) =
  ## hkRandomPf
  ##
  ## a fast automated random Portfolio generator
  ##
  ## just pass in number of stocks and optionally start and enddate
  ##
  ## the portfolio is also returned as Portfolio object for further use as desired
  ##
  ## for example use see nimFinT4.nim
  ##
  var hkexcodes = initHKEX()
  var hl = hkexcodes[0].len
  var maxstocks = sz
  if maxstocks > hl:
     echo()
     msgr() do : echo "Max Stocks Available : ",hl
     echo()
     maxstocks = hl

  var rndpf = initOrderedTable[int,string]()
  for x in 0.. <maxstocks:
      var z = randomInt(0,hl)
      discard rndpf.haskeyorput(z,$(hkexcodes[0][z]))

  decho(2)
  var pf1 = initPortfolio()
  pf1.nx = "RandomPortfolio - HK"
  var pfpool = initPool()
  var pfseq = newSeq[int]()
  for key,val in rndpf:
      var nval = hkexToYhoo(val)
      try:
         pfpool.add(getSymbol2(nval,startdate,enddate))
         pfseq.add(key)
      except:
         # we may come here if yahoo has no data or other issues for the
         # requested stock, currently we skip it
         discard
         echo()

  pf1.dx = pfpool
  result = (pf1,pfseq)

# end of HK Stock Exchange specific procs
