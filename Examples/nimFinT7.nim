import nimFinLib,libFinHk,cx

# nimFinT7.nim
#
# this example shows usage of function hkRandomPortfolio from libFinHk
# every run creates a new portfolio . Errors may occure if stock
# selected is very new and/or insufficient datapoints available from yahoo
# Portfolios can be processed for further usage

# tested ok 2017-06-06  with HK stocks , may need several attempts if yahoo data not available

let stc = 5  # Desired Number of stocks in portfolio  , default = 10
hdx(echo "Random Portfolio of Stocks listed on Hongkong Stock Exchange ")
var myPf = quickPortfolioHk(stc)
printLnBiCol(fmtx(["<20","",""],"Name",": ",myPf.nx))
printLnBiCol(fmtx(["<20","",""],"Number of Stocks",": ",myPf.dx.len))
doFinish()
