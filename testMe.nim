import os,httpclient,osproc

## of course one can not be bothered to get all this stuff
## 
## from github via fork , git clone etc.
##
## just todo a trial run to see if it works  
##
## hence here comes testMe.
## 
## if you have not done so install strfmt and random beforehand
## 
## nimble install strfmt
##
## nimble install random
## 
## then 
## 
## get this file only and compile it like so :
## 
## nim c -r -d:ssl testMe 
##
##


proc source() = 
   # get it
   var afile = "https://raw.githubusercontent.com/qqtop/NimFinLib/master/nimFinLib.nim"
   downloadFile(afile,"nimFinLib.nim")
   afile = "https://raw.githubusercontent.com/qqtop/NimFinLib/master/example1.nim"
   downloadFile(afile,"example1.nim")
   afile = "https://raw.githubusercontent.com/qqtop/NimFinLib/master/statistics.nim"
   downloadFile(afile,"statistics.nim")
   afile = "https://raw.githubusercontent.com/qqtop/NimCx/master/cx.nim"
   downloadFile(afile,"statistics.nim")

proc janitation() =
    # here comes the janitor and does some quick cleaning
    removeFile("nimFinLib.nim")
    removeFile("example1.nim")
    removeFile("example1")
    removeFile("testMe")
    removeFile("statistics.nim")
    removeFile("cx.nim")
    removeDir("nimcache")

source()
var exitCode = execCmd("nim -d:release  -d:ssl --gc:boehm  --opt:speed --hints:off --verbosity:0 -w:off c -r " & "example1.nim") 
janitation()

echo()
echo "Thank you for testing nimFinLib"
echo()
