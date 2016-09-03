{.deadCodeElim: on.}
##
##   Library     : cx.nim
##
##   Status      : stable
##
##   License     : MIT opensource
##
##   Version     : 0.9.9
##
##   ProjectStart: 2015-06-20
##   
##   Latest      : 2016-08-31
##
##   Compiler    : Nim >= 0.14.2
##
##   OS          : Linux
##
##   Description :
##
##                 cx.nim is a collection of simple procs and templates
##
##                 for easy colored display in a linux terminal , 
##                 
##                 date handling and much more.
##
##                 some procs may mirror functionality found in other moduls for convenience
##
##
##   Usage       : import cx
##
##   Project     : https://github.com/qqtop/NimCx
##
##   Docs        : http://qqtop.github.io/cx.html
##
##   Tested      : OpenSuse 13.2 , OpenSuse Leap42.1 , Ubuntu 16.04 LTS 
##     
##                 Terminal set encoding to UTF-8  
##
##                 with var. terminal font : monospace size 9.0 - 15 depending on screen resolution
##
##                 xterm,bash,st terminals support truecolor ok
##
##                 some ubuntu based gnome-terminals may not be able to display all colors
##
##                 as they are not correctly linked for whatever reason , see ubuntu forum questions.
##
##                 run this awk script to see if your terminal supports truecolor
##
##                 script from : https://gist.github.com/XVilka/8346728
##
## .. code-block:: nim
##
##                  awk 'BEGIN{
##                      s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
##                      for (colnum = 0; colnum<77; colnum++) {
##                          r = 255-(colnum*255/76);
##                          g = (colnum*510/76);
##                          b = (colnum*255/76);
##                          if (g>255) g = 510-g;
##                          printf "\033[48;2;%d;%d;%dm", r,g,b;
##                          printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
##                          printf "%s\033[0m", substr(s,colnum+1,1);
##                      }
##                      printf "\n";
##                  }'
##
##
##   Related     :
##
##                * demo library: cxDemo.nim
##
##                * tests       : cxTest.nim   (run some rough demos from cxDemo)
##
##
##   Programming : qqTop
##
##   Note        : may be improved at any time
##
##                 mileage may vary depending on the available
##
##                 unicode libraries and terminal support in your system
##
##                 terminal x-axis position start with 1
##
##                 proc fmtx a formatting utility has been added
##
##                 to remove dependency on strfmt , which breaks sometimes
##
##                 after compiler updates .
##                 
##
##   Required    : random installed via nimble
##
##   Installation: nimble install nimFinLib ( a project which now uses cx.nim)
##
##                 will install this library . 
##
##
##   Optional    : xclip  
##               
##                 unicode font libraries 
##
##   Plans       : move some of the non core procs to a new module cxutils.nim
##   
##                 
##
##
##

import os,osproc,macros,posix,terminal,math,stats,times,tables,json,sets
import sequtils,parseutils,httpclient,rawsockets,browsers,intsets, algorithm
import strutils except toLower,toUpper
import unicode 

# imports based on modules available via nimble
import "random-0.5.3/random"

export strutils,sequtils,times,unicode
export terminal.Style,terminal.getch  # make terminal style constants available in the calling prog


when defined(macosx):
  {.warning : " \u2691 CX is only tested on Linux ! Your mileage may vary".}

when defined(windows):
  {.hint    : "Time to switch to Linux !".}
  {.fatal   : "CX does not support Windows at this stage and never will !".}

when defined(posix):
  {.hint    : "\x1b[38;2;154;205;50m \u2691 Delicious Os flavour detected .... CX loves Linux ! \u2691".}


const CXLIBVERSION* = "0.9.9"

let start* = epochTime()  ##  simple execution timing with one line see doFinish()


proc getfg(fg:ForegroundColor):string =
    var gFG = ord(fg)
    result = "\e[" & $gFG & 'm'

proc getbg(bg:BackgroundColor):string =
    var gBG = ord(bg)
    result = "\e[" & $gBG & 'm'

proc fbright(fg:ForegroundColor): string =
    var gFG = ord(fg)
    inc(gFG, 60)
    result = "\e[" & $gFG & 'm'

proc bbright(bg:BackgroundColor): string =
    var gBG = ord(bg)
    inc(gBG, 60)
    result = "\e[" & $gBG & 'm'

# type used in slim number printing
type
    T7 = object
      zx : seq[string]
      
# type used in getRandomPoint
type
    RpointInt*   = tuple[x, y : int]
    RpointFloat* = tuple[x, y : float]


# type used in Benchmark
type
    Benchmarkres* = tuple[bname,cpu,epoch : string]
# used to store all benchmarkresults   
var benchmarkresults* =  newSeq[Benchmarkres]()



const

      # Terminal consts for bash terminal cleanup
      # mileage may very on your system
      #
      # usage : print clearbol
      #         printLn(cleareol,green,red,xpos = 20)
      #
      clearbol*      =   "\x1b[1K"         ## clear to begin of line
      cleareol*      =   "\x1b[K"          ## clear to end of line
      clearscreen*   =   "\x1b[2J\x1b[H"   ## clear screen
      clearline*     =   "\x1b[2K\x1b[G"   ## clear line
      clearbos*      =   "\x1b[1J"         ## clear to begin of screen
      cleareos*      =   "\x1b[J"          ## clear to end of screen
      resetcols*     =   "\x1b[0m"         ## reset colors

const

      # Terminal consts for bash movements ( still testing )
      cup*      = "\x1b[A"      # ok
      cdown*    = "\x1b[B"      # ok
      cright*   = "\x1b[C"      # ok
      cleft*    = "\x1b[D"      # ok
      cend*     = "\x1b[F"      # no effect
      cpos1*    = "\x1b[H"      # ok moves cursor to screen position 0/0
      cins*     = "\x1b[2~"     # no effect
      cdel*     = "\x1b[3~"     # no effect
      cpgup*    = "\x1b[5~"     # no effect
      cpgdn*    = "\x1b[6~"     # no effect
      csave*     = "\x1b[s"     # ok saves last xpos (but not ypos)
      crestore*  = "\x1b[u"     # ok restores saved xpos
      chide*     = "\x1b[?25l"  # ok hide cursor
      cshow*     = "\x1b[?25h"  # ok show cursor


const
      # Terminal ForegroundColor Normal

      termred*              = getfg(fgRed)
      termgreen*            = getfg(fgGreen)
      termblue*             = getfg(fgBlue)
      termcyan*             = getfg(fgCyan)
      termyellow*           = getfg(fgYellow)
      termwhite*            = getfg(fgWhite)
      termblack*            = getfg(fgBlack)
      termmagenta*          = getfg(fgMagenta)

      # Terminal ForegroundColor Bright

      brightred*            = fbright(fgRed)
      brightgreen*          = fbright(fgGreen)
      brightblue*           = fbright(fgBlue)
      brightcyan*           = fbright(fgCyan)
      brightyellow*         = fbright(fgYellow)
      brightwhite*          = fbright(fgWhite)
      brightmagenta*        = fbright(fgMagenta)
      brightblack*          = fbright(fgBlack)

      clrainbow*            = "clrainbow"

      # Terminal BackgroundColor Normal

      bred*                 = getbg(bgRed)
      bgreen*               = getbg(bgGreen)
      bblue*                = getbg(bgBlue)
      bcyan*                = getbg(bgCyan)
      byellow*              = getbg(bgYellow)
      bwhite*               = getbg(bgWhite)
      bblack*               = getbg(bgBlack)
      bmagenta*             = getbg(bgMagenta)

      # Terminal BackgroundColor Bright

      bbrightred*           = bbright(bgRed)
      bbrightgreen*         = bbright(bgGreen)
      bbrightblue*          = bbright(bgBlue)
      bbrightcyan*          = bbright(bgCyan)
      bbrightyellow*        = bbright(bgYellow)
      bbrightwhite*         = bbright(bgWhite)
      bbrightmagenta*       = bbright(bgMagenta)
      bbrightblack*         = bbright(bgBlack)

      # Pastel color set

      pastelgreen*          =  "\x1b[38;2;179;226;205m"
      pastelorange*         =  "\x1b[38;2;253;205;172m"
      pastelblue*           =  "\x1b[38;2;203;213;232m"
      pastelpink*           =  "\x1b[38;2;244;202;228m"
      pastelyellowgreen*    =  "\x1b[38;2;230;245;201m"
      pastelyellow*         =  "\x1b[38;2;255;242;174m"
      pastelbeige*          =  "\x1b[38;2;241;226;204m"
      pastelwhite*          =  "\x1b[38;2;204;204;204m"


      # other colors of interest
      truetomato*           =   "\x1b[38;2;255;100;0m"


      # colors lifted from colors.nim and massaged into rgb escape seqs

      aliceblue*            =  "\x1b[38;2;240;248;255m"
      antiquewhite*         =  "\x1b[38;2;250;235;215m"
      aqua*                 =  "\x1b[38;2;0;255;255m"
      aquamarine*           =  "\x1b[38;2;127;255;212m"
      azure*                =  "\x1b[38;2;240;255;255m"
      beige*                =  "\x1b[38;2;245;245;220m"
      bisque*               =  "\x1b[38;2;255;228;196m"
      black*                =  "\x1b[38;2;0;0;0m"
      blanchedalmond*       =  "\x1b[38;2;255;235;205m"
      blue*                 =  "\x1b[38;2;0;0;255m"
      blueviolet*           =  "\x1b[38;2;138;43;226m"
      brown*                =  "\x1b[38;2;165;42;42m"
      burlywood*            =  "\x1b[38;2;222;184;135m"
      cadetblue*            =  "\x1b[38;2;95;158;160m"
      chartreuse*           =  "\x1b[38;2;127;255;0m"
      chocolate*            =  "\x1b[38;2;210;105;30m"
      coral*                =  "\x1b[38;2;255;127;80m"
      cornflowerblue*       =  "\x1b[38;2;100;149;237m"
      cornsilk*             =  "\x1b[38;2;255;248;220m"
      crimson*              =  "\x1b[38;2;220;20;60m"
      cyan*                 =  "\x1b[38;2;0;255;255m"
      darkblue*             =  "\x1b[38;2;0;0;139m"
      darkcyan*             =  "\x1b[38;2;0;139;139m"
      darkgoldenrod*        =  "\x1b[38;2;184;134;11m"
      darkgray*             =  "\x1b[38;2;169;169;169m"
      darkgreen*            =  "\x1b[38;2;0;100;0m"
      darkkhaki*            =  "\x1b[38;2;189;183;107m"
      darkmagenta*          =  "\x1b[38;2;139;0;139m"
      darkolivegreen*       =  "\x1b[38;2;85;107;47m"
      darkorange*           =  "\x1b[38;2;255;140;0m"
      darkorchid*           =  "\x1b[38;2;153;50;204m"
      darkred*              =  "\x1b[38;2;139;0;0m"
      darksalmon*           =  "\x1b[38;2;233;150;122m"
      darkseagreen*         =  "\x1b[38;2;143;188;143m"
      darkslateblue*        =  "\x1b[38;2;72;61;139m"
      darkslategray*        =  "\x1b[38;2;47;79;79m"
      darkturquoise*        =  "\x1b[38;2;0;206;209m"
      darkviolet*           =  "\x1b[38;2;148;0;211m"
      deeppink*             =  "\x1b[38;2;255;20;147m"
      deepskyblue*          =  "\x1b[38;2;0;191;255m"
      dimgray*              =  "\x1b[38;2;105;105;105m"
      dodgerblue*           =  "\x1b[38;2;30;144;255m"
      firebrick*            =  "\x1b[38;2;178;34;34m"
      floralwhite*          =  "\x1b[38;2;255;250;240m"
      forestgreen*          =  "\x1b[38;2;34;139;34m"
      fuchsia*              =  "\x1b[38;2;255;0;255m"
      gainsboro*            =  "\x1b[38;2;220;220;220m"
      ghostwhite*           =  "\x1b[38;2;248;248;255m"
      gold*                 =  "\x1b[38;2;255;215;0m"
      goldenrod*            =  "\x1b[38;2;218;165;32m"
      gray*                 =  "\x1b[38;2;128;128;128m"
      green*                =  "\x1b[38;2;0;128;0m"
      greenyellow*          =  "\x1b[38;2;173;255;47m"
      honeydew*             =  "\x1b[38;2;240;255;240m"
      hotpink*              =  "\x1b[38;2;255;105;180m"
      indianred*            =  "\x1b[38;2;205;92;92m"
      indigo*               =  "\x1b[38;2;75;0;130m"
      ivory*                =  "\x1b[38;2;255;255;240m"
      khaki*                =  "\x1b[38;2;240;230;140m"
      lavender*             =  "\x1b[38;2;230;230;250m"
      lavenderblush*        =  "\x1b[38;2;255;240;245m"
      lawngreen*            =  "\x1b[38;2;124;252;0m"
      lemonchiffon*         =  "\x1b[38;2;255;250;205m"
      lightblue*            =  "\x1b[38;2;173;216;230m"
      lightcoral*           =  "\x1b[38;2;240;128;128m"
      lightcyan*            =  "\x1b[38;2;224;255;255m"
      lightgoldenrodyellow* =  "\x1b[38;2;250;250;210m"
      lightgrey*            =  "\x1b[38;2;211;211;211m"
      lightgreen*           =  "\x1b[38;2;144;238;144m"
      lightpink*            =  "\x1b[38;2;255;182;193m"
      lightsalmon*          =  "\x1b[38;2;255;160;122m"
      lightseagreen*        =  "\x1b[38;2;32;178;170m"
      lightskyblue*         =  "\x1b[38;2;135;206;250m"
      lightslategray*       =  "\x1b[38;2;119;136;153m"
      lightsteelblue*       =  "\x1b[38;2;176;196;222m"
      lightyellow*          =  "\x1b[38;2;255;255;224m"
      lime*                 =  "\x1b[38;2;0;255;0m"
      limegreen*            =  "\x1b[38;2;50;205;50m"
      linen*                =  "\x1b[38;2;250;240;230m"
      magenta*              =  "\x1b[38;2;255;0;255m"
      maroon*               =  "\x1b[38;2;128;0;0m"
      mediumaquamarine*     =  "\x1b[38;2;102;205;170m"
      mediumblue*           =  "\x1b[38;2;0;0;205m"
      mediumorchid*         =  "\x1b[38;2;186;85;211m"
      mediumpurple*         =  "\x1b[38;2;147;112;216m"
      mediumseagreen*       =  "\x1b[38;2;60;179;113m"
      mediumslateblue*      =  "\x1b[38;2;123;104;238m"
      mediumspringgreen*    =  "\x1b[38;2;0;250;154m"
      mediumturquoise*      =  "\x1b[38;2;72;209;204m"
      mediumvioletred*      =  "\x1b[38;2;199;21;133m"
      midnightblue*         =  "\x1b[38;2;25;25;112m"
      mintcream*            =  "\x1b[38;2;245;255;250m"
      mistyrose*            =  "\x1b[38;2;255;228;225m"
      moccasin*             =  "\x1b[38;2;255;228;181m"
      navajowhite*          =  "\x1b[38;2;255;222;173m"
      navy*                 =  "\x1b[38;2;0;0;128m"
      oldlace*              =  "\x1b[38;2;253;245;230m"
      olive*                =  "\x1b[38;2;128;128;0m"
      olivedrab*            =  "\x1b[38;2;107;142;35m"
      orange*               =  "\x1b[38;2;255;165;0m"
      orangered*            =  "\x1b[38;2;255;69;0m"
      orchid*               =  "\x1b[38;2;218;112;214m"
      palegoldenrod*        =  "\x1b[38;2;238;232;170m"
      palegreen*            =  "\x1b[38;2;152;251;152m"
      paleturquoise*        =  "\x1b[38;2;175;238;238m"
      palevioletred*        =  "\x1b[38;2;216;112;147m"
      papayawhip*           =  "\x1b[38;2;255;239;213m"
      peachpuff*            =  "\x1b[38;2;255;218;185m"
      peru*                 =  "\x1b[38;2;205;133;63m"
      pink*                 =  "\x1b[38;2;255;192;203m"
      plum*                 =  "\x1b[38;2;221;160;221m"
      powderblue*           =  "\x1b[38;2;176;224;230m"
      purple*               =  "\x1b[38;2;128;0;128m"
      red*                  =  "\x1b[38;2;255;0;0m"
      rosybrown*            =  "\x1b[38;2;188;143;143m"
      royalblue*            =  "\x1b[38;2;65;105;225m"
      saddlebrown*          =  "\x1b[38;2;139;69;19m"
      salmon*               =  "\x1b[38;2;250;128;114m"
      sandybrown*           =  "\x1b[38;2;244;164;96m"
      seagreen*             =  "\x1b[38;2;46;139;87m"
      seashell*             =  "\x1b[38;2;255;245;238m"
      sienna*               =  "\x1b[38;2;160;82;45m"
      silver*               =  "\x1b[38;2;192;192;192m"
      skyblue*              =  "\x1b[38;2;135;206;235m"
      slateblue*            =  "\x1b[38;2;106;90;205m"
      slategray*            =  "\x1b[38;2;112;128;144m"
      snow*                 =  "\x1b[38;2;255;250;250m"
      springgreen*          =  "\x1b[38;2;0;255;127m"
      steelblue*            =  "\x1b[38;2;70;130;180m"
      tan*                  =  "\x1b[38;2;210;180;140m"
      teal*                 =  "\x1b[38;2;0;128;128m"
      thistle*              =  "\x1b[38;2;216;191;216m"
      tomato*               =  "\x1b[38;2;255;99;71m"
      turquoise*            =  "\x1b[38;2;64;224;208m"
      violet*               =  "\x1b[38;2;238;130;238m"
      wheat*                =  "\x1b[38;2;245;222;179m"
      white*                =  "\x1b[38;2;255;255;255m"    # same as brightwhite
      whitesmoke*           =  "\x1b[38;2;245;245;245m"
      yellow*               =  "\x1b[38;2;255;255;0m"
      yellowgreen*          =  "\x1b[38;2;154;205;50m"


 
const
  # used by spellInteger
  tens =  ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
  small = ["zero", "one", "two", "three", "four", "five", "six", "seven",
           "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
           "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
  huge =  ["", "", "million", "billion", "trillion", "quadrillion",
           "quintillion", "sextillion", "septillion", "octillion", "nonillion","decillion"]
 

let a1 = "  ██   "
let a2 = " ██ █  "
let a3 = "██   █ "
let a4 = "██ █ █ "
let a5 = "██   █ "


let b1 = "███ █  "
let b2 = "██   █ "
let b3 = "███ █  "
let b4 = "██   █ "
let b5 = "███ █  "


let c1 = " █████ "
let c2 = "██     "
let c3 = "██     "
let c4 = "██     "
let c5 = " █████ "



let d1 = "███ █  "
let d2 = "██   █ "
let d3 = "██   █ "
let d4 = "██   █ "
let d5 = "███ █  "


let e1 = "█████  "
let e2 = "██     "
let e3 = "████   "
let e4 = "██     "
let e5 = "█████  "


let f1 = "█████  "
let f2 = "██     "
let f3 = "████   "
let f4 = "██     "
let f5 = "██     "



let g1 = " ████  "
let g2 = "██     "
let g3 = "██  ██ "
let g4 = "██   █ "
let g5 = " ████  "



let h1 = "██   █ "
let h2 = "██   █ "
let h3 = "██████ "
let h4 = "██   █ "
let h5 = "██   █ "


let i1 = "  ██   "
let i2 = "  ██   "
let i3 = "  ██   "
let i4 = "  ██   "
let i5 = "  ██   "



let j1 = "    ██ "
let j2 = "    ██ "
let j3 = "    ██ "
let j4 = " █  ██ "
let j5 = "  ██   "


let k1 = "██   █ "
let k2 = "██  █  "
let k3 = "██ █   "
let k4 = "██  █  "
let k5 = "██   █ "


let l1 = "██     "
let l2 = "██     "
let l3 = "██     "
let l4 = "██     "
let l5 = "██████ "



let m1 = "██  ██ "
let m2 = "█ ██ █ "
let m3 = "█  █ █ "
let m4 = "█  █ █ "
let m5 = "█    █ "


let n1 = "██   █ "
let n2 = "███  █ "
let n3 = "██ █ █ "
let n4 = "██  ██ "
let n5 = "██   █ "


let o1 = " ████  "
let o2 = "██   █ "
let o3 = "██   █ "
let o4 = "██   █ "
let o5 = " ████  "


let p1 = "██ ██  "
let p2 = "██   █ "
let p3 = "██ ██  "
let p4 = "██     "
let p5 = "██     "


let q1 = " ████  "
let q2 = "██   █ "
let q3 = "██   █ "
let q4 = "██ █ █ "
let q5 = " ██ █  "



let r1 = "███ █  "
let r2 = "██   █ "
let r3 = "███ █  "
let r4 = "██   █ "
let r5 = "██   █ "



let s1 = "  █ ██ "
let s2 = " █     "
let s3 = "   █   "
let s4 = "     █ "
let s5 = " ██ █  "


let t1 = "██████ "
let t2 = "  ██   "
let t3 = "  ██   "
let t4 = "  ██   "
let t5 = "  ██   "


let u1 = "██   █ "
let u2 = "██   █ "
let u3 = "██   █ "
let u4 = "██   █ "
let u5 = "██████ "



let v1 = "██   █ "
let v2 = "██   █ "
let v3 = "██   █ "
let v4 = " █  █  "
let v5 = "  ██   "




let w1 = "██   █ "
let w2 = "██   █ "
let w3 = "██ █ █ "
let w4 = " █ █ █ "
let w5 = "  █ █  "


let x1 = "██   █ "
let x2 = "  █ █  "
let x3 = "   █   "
let x4 = "  █ █  "
let x5 = "██   █ "



let y1 = "██   █ "
let y2 = "  █ █  "
let y3 = "   █   "
let y4 = "   █   "
let y5 = "   █   "



let z1 = "██████ "
let z2 = "    █  "
let z3 = "   █   "
let z4 = " █     "
let z5 = "██████ "



let hy1= "       "
let hy2= "       "
let hy3= " █████ "
let hy4= "       "
let hy5= "       "


let pl1= "       "
let pl2= "   █   "
let pl3= " █████ "
let pl4= "   █   "
let pl5= "       "


let ul1 = "      "
let ul2 = "      "
let ul3 = "      "
let ul4 = "      "
let ul5 = "██████"

let el1 = "      "
let el2 = "██████"
let el3 = "      "
let el4 = "██████"
let el5 = "      "



let clb1 = spaces(6)
let clb2 = spaces(6)
let clb3 = spaces(6)
let clb4 = spaces(6)
let clb5 = spaces(6)


let abx* = @[a1,a2,a3,a4,a5]
let bbx* = @[b1,b2,b3,b4,b5]
let cbx* = @[c1,c2,c3,c4,c5]
let dbx* = @[d1,d2,d3,d4,d5]
let ebx* = @[e1,e2,e3,e4,e5]
let fbx* = @[f1,f2,f3,f4,f5]
let gbx* = @[g1,g2,g3,g4,g5]
let hbx* = @[h1,h2,h3,h4,h5]
let ibx* = @[i1,i2,i3,i4,i5]
let jbx* = @[j1,j2,j3,j4,j5]
let kbx* = @[k1,k2,k3,k4,k5]
let lbx* = @[l1,l2,l3,l4,l5]
let mbx* = @[m1,m2,m3,m4,m5]
let nbx* = @[n1,n2,n3,n4,n5]
let obx* = @[o1,o2,o3,o4,o5]
let pbx* = @[p1,p2,p3,p4,p5]
let qbx* = @[q1,q2,q3,q4,q5]
let rbx* = @[r1,r2,r3,r4,r5]
let sbx* = @[s1,s2,s3,s4,s5]
let tbx* = @[t1,t2,t3,t4,t5]
let ubx* = @[u1,u2,u3,u4,u5]
let vbx* = @[v1,v2,v3,v4,v5]
let wbx* = @[w1,w2,w3,w4,w5]
let xbx* = @[x1,x2,x3,x4,x5]
let ybx* = @[y1,y2,y3,y4,y5]
let zbx* = @[z1,z2,z3,z4,z5]

let hybx* = @[hy1,hy2,hy3,hy4,hy5]
let plbx* = @[pl1,pl2,pl3,pl4,pl5]
let ulbx* = @[ul1,ul2,ul3,ul4,ul5]
let elbx* = @[el1,el2,el3,el4,el5]

let clbx* = @[clb1,clb2,clb3,clb4,clb5]

let bigLetters* = @[abx,bbx,cbx,dbx,ebx,fbx,gbx,hbx,ibx,jbx,kbx,lbx,mbx,nbx,obx,pbx,qbx,rbx,sbx,tbx,ubx,vbx,wbx,xbx,ybx,zbx,hybx,plbx,ulbx,elbx,clbx]

# a big block number set
#  can be used with printBigNumber

const number0 =
 @["██████"
  ,"██  ██"
  ,"██  ██"
  ,"██  ██"
  ,"██████"]

const number1 =
 @["    ██"
  ,"    ██"
  ,"    ██"
  ,"    ██"
  ,"    ██"]

const number2 =
 @["██████"
  ,"    ██"
  ,"██████"
  ,"██    "
  ,"██████"]

const number3 =
 @["██████"
  ,"    ██"
  ,"██████"
  ,"    ██"
  ,"██████"]

const number4 =
 @["██  ██"
  ,"██  ██"
  ,"██████"
  ,"    ██"
  ,"    ██"]

const number5 =
 @["██████"
  ,"██    "
  ,"██████"
  ,"    ██"
  ,"██████"]

const number6 =
 @["██████"
  ,"██    "
  ,"██████"
  ,"██  ██"
  ,"██████"]

const number7 =
 @["██████"
  ,"    ██"
  ,"    ██"
  ,"    ██"
  ,"    ██"]

const number8 =
 @["██████"
  ,"██  ██"
  ,"██████"
  ,"██  ██"
  ,"██████"]

const number9 =
 @["██████"
  ,"██  ██"
  ,"██████"
  ,"    ██"
  ,"██████"]


const colon =
 @["      "
  ,"  ██  "
  ,"      "
  ,"  ██  "
  ,"      "]


const clrb =
 @["      "
  ,"      "
  ,"      "
  ,"      "
  ,"      "]

const numberlen = 4

# big NIM in block letters

let NIMX1 = "██     █    ██    ███   ██"
let NIMX2 = "██ █   █    ██    ██ █ █ █"
let NIMX3 = "██  █  █    ██    ██  █  █"
let NIMX4 = "██   █ █    ██    ██  █  █"
let NIMX5 = "██     █    ██    ██     █"

let nimsx* = @[NIMX1,NIMX2,NIMX3,NIMX4,NIMX5]


let NIMX6  = "███   ██  ██  ██     █  ██"
let NIMX7  = "██ █ █ █  ██  ██ █   █  ██"
let NIMX8  = "██  █  █  ██  ██  █  █  ██"
let NIMX9  = "██  █  █  ██  ██   █ █  ██"
let NIMX10 = "██     █  ██  ██     █  ██"

let nimsx2* = @[NIMX6,NIMX7,NIMX8,NIMX9,NIMX10]



# slim numbers can be used with printSlimNumber

const snumber0* =
  @["┌─┐",
    "│ │",
    "└─┘"]


const snumber1* =
  @["  ╷",
    "  │",
    "  ╵"]

const snumber2* =
  @["╶─┐",
    "┌─┘",
    "└─╴"]

const snumber3* =
  @["╶─┐",
    "╶─┤",
    "╶─┘"]

const snumber4* =
  @["╷ ╷",
    "└─┤",
    "  ╵"]

const snumber5* =
  @["┌─╴",
    "└─┐",
    "╶─┘"]

const snumber6* =
  @["┌─╴",
    "├─┐",
    "└─┘"]

const snumber7* =
  @["╶─┐",
    "  │",
    "  ╵"]

const snumber8* =
  @["┌─┐",
    "├─┤",
    "└─┘"]

const snumber9* =
  @["┌─┐",
    "└─┤",
    "╶─┘"]


const scolon* =
  @["╷ ",
    "╷ ",
    "  "]


const scomma* =
   @["  ",
     "  ",
     "╷ "]

const sdot* =
   @["  ",
     "  ",
     ". "]


const sblank* =
   @["  ",
     "  ",
     "  "]


var slimNumberSet = newSeq[string]()
for x in 0.. 9: slimNumberSet.add($(x))
var slimCharSet   = @[",",".",":"," "]


# arrows

const 
      leftarrow*           = "\u2190"
      uparrow*             = "\u2191"
      rightarrow*          = "\u2192"
      downarrow*           = "\u2193"
      leftrightarrow*      = "\u2194"
      updownaarrow*        = "\u2195"
      northwestarrow*      = "\u2196"
      northeastarrow*      = "\u2197"
      southwestarrow*      = "\u2198"
      southeastarrow*      = "\u2199"

      phone*               = "\u260E"
      fullflag*            = "\u2691"

# emojis
# mileage here may vary depending on whatever your system supports

const
    # emoji len 3
    check*              =  "\xE2\x9C\x93"
    xmark*              =  "\xE2\x9C\x98"
    heart*              =  "\xE2\x9D\xA4"
    sun*                =  "\xE2\x98\x80"
    star*               =  "\xE2\x98\x85"
    darkstar*           =  "\xE2\x98\x86"
    umbrella*           =  "\xE2\x98\x82"
    flag*               =  "\xE2\x9A\x91"
    snowflake*          =  "\xE2\x9D\x84"
    music*              =  "\xE2\x99\xAB"
    scissors*           =  "\xE2\x9C\x82"
    trademark*          =  "\xE2\x84\xA2"
    copyright*          =  "\xC2\xA9"
    roof*               =  "\xEF\xA3\xBF"
    skull*              =  "\xE2\x98\xA0"
    smile*              =  "\xE2\x98\xBA"
    # emoji len 4
    smiley*             =  "😃"
    innocent*           =  "😇"
    lol*                =  "😂"
    tongue*             =  "😛"
    blush*              =  "😊"
    sad*                =  "😟"
    cry*                =  "😢"
    rage*               =  "😡"
    cat*                =  "😺"
    kitty*              =  "🐱"
    monkey*             =  "🐵"
    cow*                =  "🐮"


let emojis* = @[check,xmark,heart,sun,star,darkstar,umbrella,flag,snowflake,music,scissors,
               trademark,copyright,roof,skull,smile,smiley,innocent,lol,tongue,blush,
               sad,cry,rage,cat,kitty,monkey,cow]


# may or may not be available on all systems
const wideDot* = "\xE2\x9A\xAB" & " "

# all colors except original terminal colors
let colorNames* = @[
      ("aliceblue", aliceblue),
      ("antiquewhite", antiquewhite),
      ("aqua", aqua),
      ("aquamarine", aquamarine),
      ("azure", azure),
      ("beige", beige),
      ("bisque", bisque),
      ("black", black),
      ("blanchedalmond", blanchedalmond),
      ("blue", blue),
      ("blueviolet", blueviolet),
      ("brown", brown),
      ("burlywood", burlywood),
      ("cadetblue", cadetblue),
      ("chartreuse", chartreuse),
      ("chocolate", chocolate),
      ("coral", coral),
      ("cornflowerblue", cornflowerblue),
      ("cornsilk", cornsilk),
      ("crimson", crimson),
      ("cyan", cyan),
      ("darkblue", darkblue),
      ("darkcyan", darkcyan),
      ("darkgoldenrod", darkgoldenrod),
      ("darkgray", darkgray),
      ("darkgreen", darkgreen),
      ("darkkhaki", darkkhaki),
      ("darkmagenta", darkmagenta),
      ("darkolivegreen", darkolivegreen),
      ("darkorange", darkorange),
      ("darkorchid", darkorchid),
      ("darkred", darkred),
      ("darksalmon", darksalmon),
      ("darkseagreen", darkseagreen),
      ("darkslateblue", darkslateblue),
      ("darkslategray", darkslategray),
      ("darkturquoise", darkturquoise),
      ("darkviolet", darkviolet),
      ("deeppink", deeppink),
      ("deepskyblue", deepskyblue),
      ("dimgray", dimgray),
      ("dodgerblue", dodgerblue),
      ("firebrick", firebrick),
      ("floralwhite", floralwhite),
      ("forestgreen", forestgreen),
      ("fuchsia", fuchsia),
      ("gainsboro", gainsboro),
      ("ghostwhite", ghostwhite),
      ("gold", gold),
      ("goldenrod", goldenrod),
      ("gray", gray),
      ("green", green),
      ("greenyellow", greenyellow),
      ("honeydew", honeydew),
      ("hotpink", hotpink),
      ("indianred", indianred),
      ("indigo", indigo),
      ("ivory", ivory),
      ("khaki", khaki),
      ("lavender", lavender),
      ("lavenderblush", lavenderblush),
      ("lawngreen", lawngreen),
      ("lemonchiffon", lemonchiffon),
      ("lightblue", lightblue),
      ("lightcoral", lightcoral),
      ("lightcyan", lightcyan),
      ("lightgoldenrodyellow", lightgoldenrodyellow),
      ("lightgrey", lightgrey),
      ("lightgreen", lightgreen),
      ("lightpink", lightpink),
      ("lightsalmon", lightsalmon),
      ("lightseagreen", lightseagreen),
      ("lightskyblue", lightskyblue),
      ("lightslategray", lightslategray),
      ("lightsteelblue", lightsteelblue),
      ("lightyellow", lightyellow),
      ("lime", lime),
      ("limegreen", limegreen),
      ("linen", linen),
      ("magenta", magenta),
      ("maroon", maroon),
      ("mediumaquamarine", mediumaquamarine),
      ("mediumblue", mediumblue),
      ("mediumorchid", mediumorchid),
      ("mediumpurple", mediumpurple),
      ("mediumseagreen", mediumseagreen),
      ("mediumslateblue", mediumslateblue),
      ("mediumspringgreen", mediumspringgreen),
      ("mediumturquoise", mediumturquoise),
      ("mediumvioletred", mediumvioletred),
      ("midnightblue", midnightblue),
      ("mintcream", mintcream),
      ("mistyrose", mistyrose),
      ("moccasin", moccasin),
      ("navajowhite", navajowhite),
      ("navy", navy),
      ("oldlace", oldlace),
      ("olive", olive),
      ("olivedrab", olivedrab),
      ("orange", orange),
      ("orangered", orangered),
      ("orchid", orchid),
      ("palegoldenrod", palegoldenrod),
      ("palegreen", palegreen),
      ("paleturquoise", paleturquoise),
      ("palevioletred", palevioletred),
      ("papayawhip", papayawhip),
      ("peachpuff", peachpuff),
      ("peru", peru),
      ("pink", pink),
      ("plum", plum),
      ("powderblue", powderblue),
      ("purple", purple),
      ("red", red),
      ("rosybrown", rosybrown),
      ("royalblue", royalblue),
      ("saddlebrown", saddlebrown),
      ("salmon", salmon),
      ("sandybrown", sandybrown),
      ("seagreen", seagreen),
      ("seashell", seashell),
      ("sienna", sienna),
      ("silver", silver),
      ("skyblue", skyblue),
      ("slateblue", slateblue),
      ("slategray", slategray),
      ("snow", snow),
      ("springgreen", springgreen),
      ("steelblue", steelblue),
      ("tan", tan),
      ("teal", teal),
      ("thistle", thistle),
      ("tomato", tomato),
      ("turquoise", turquoise),
      ("violet", violet),
      ("wheat", wheat),
      ("white", white),
      ("whitesmoke", whitesmoke),
      ("yellow", yellow),
      ("yellowgreen", yellowgreen),
      ("pastelbeige",pastelbeige),
      ("pastelblue",pastelblue),
      ("pastelgreen",pastelgreen),
      ("pastelorange",pastelorange),
      ("pastelpink",pastelpink),
      ("pastelwhite",pastelwhite),
      ("pastelyellow",pastelyellow),
      ("pastelyellowgreen",pastelyellowgreen),
      ("truetomato",truetomato)]



let rxCol* = toSeq(colorNames.low.. colorNames.high) ## index into colorNames


template randCol*: string = colorNames[rxCol.randomChoice()][1]
   ## randCol
   ##
   ## get a randomcolor from colorNames
   ##
   ## .. code-block:: nim
   ##    # print a string 6 times in a random color selected from colorNames
   ##    loopy(0..5,printLn("Hello Random Color",randCol()))
   ##
   ##

# subsets of colorNames
#
# more colorsets may be added in the future  currently used in rainbow2
#
#
let pastelSet* = @[
      ("pastelbeige",pastelbeige),
      ("pastelblue",pastelblue),
      ("pastelgreen",pastelgreen),
      ("pastelorange",pastelorange),
      ("pastelpink",pastelpink),
      ("pastelwhite",pastelwhite),
      ("pastelyellow",pastelyellow),
      ("pastelyellowgreen",pastelyellowgreen)]

let rxPastelCol* = toSeq(pastelSet.low.. pastelSet.high) # index into pastelSet


let cards* = @[
 "🂡" ,"🂱" ,"🃁" ,"🃑",
 "🂢" ,"🂲" ,"🃂" ,"🃒",
 "🂣" ,"🂳" ,"🃃" ,"🃓",
 "🂤" ,"🂴" ,"🃄" ,"🃔",
 "🂥" ,"🂵" ,"🃅" ,"🃕",
 "🂦" ,"🂶" ,"🃆" ,"🃖",
 "🂧" ,"🂷" ,"🃇" ,"🃗",
 "🂨" ,"🂸" ,"🃈" ,"🃘",
 "🂩" ,"🂹" ,"🃉" ,"🃙",
 "🂪" ,"🂺" ,"🃊" ,"🃚",
 "🂫" ,"🂻" ,"🃋" ,"🃛",
 "🂬" ,"🂼" ,"🃌" ,"🃜",
 "🂭" ,"🂽" ,"🃍" ,"🃝",
 "🂮" ,"🂾" ,"🃎" ,"🃞",
 "🂠" ,"🂿" ,"🃏" ,"🃟"]

let rxCards* = toSeq(cards.low.. cards.high) # index into cards

converter toTwInt(x: cushort): int = result = int(x)

when defined(Linux):
    proc getTerminalWidth*() : int =
        ## getTerminalWidth
        ##
        ## and get linux terminal width in columns
        ## a terminalwith function now incorporated in Nim dev of 2016-09-02
        ## which is slightly slower than the one presented here
        ## 
       
        type WinSize = object
          row, col, xpixel, ypixel: cushort
        const TIOCGWINSZ = 0x5413
        proc ioctl(fd: cint, request: culong, argp: pointer)
          {.importc, header: "<sys/ioctl.h>".}
        var size: WinSize
        ioctl(0, TIOCGWINSZ, addr size)
        result = toTwInt(size.col)


    template tw* : int = getTerminalwidth() ## latest terminal width always available in tw


    proc getTerminalHeight*() : int =
        ## getTerminalHeight
        ##
        ## get linux terminal height in rows
        ##

        type WinSize = object
          row, col, xpixel, ypixel: cushort
        const TIOCGWINSZ = 0x5413
        proc ioctl(fd: cint, request: culong, argp: pointer)
          {.importc, header: "<sys/ioctl.h>".}
        var size: WinSize
        ioctl(0, TIOCGWINSZ, addr size)
        result = toTwInt(size.row)


    template th* : int = getTerminalheight() ## latest terminalheight always available in th


# forward declarations
proc ff*(zz:float,n:int64 = 5):string
proc ff2*(zz:float,n:int = 3):string
proc ff2*(zz:int,n:int = 0):string
converter colconv*(cx:string) : string
proc rainbow*[T](s : T,xpos:int = 0,fitLine:bool = false ,centered:bool = false)  ## forward declaration
proc print*[T](astring:T,fgr:string = termwhite ,bgr:string = bblack,xpos:int = 0,fitLine:bool = false ,centered:bool = false,styled : set[Style]= {},substr:string = "")
proc printBiCol*[T](s:T,sep:string = ":",colLeft:string = yellowgreen ,colRight:string = termwhite,xpos:int = 0,centered:bool = false) ## forward declaration
proc printLnBiCol*[T](s:T,sep:string = ":",colLeft:string = yellowgreen ,colRight:string = termwhite,xpos:int = 0,centered:bool = false) ## forward declaration
proc printRainbow*(s : string,styled:set[Style] = {}) 
proc hline*(n:int = tw,col:string = white) ## forward declaration
proc hlineLn*(n:int = tw,col:string = white) ## forward declaration
proc spellInteger*(n: int64): string ## forward declaration
proc splitty*(txt:string,sep:string):seq[string] ## forward declaration
proc getRandomInt*(mi:int = 0,ma:int = int.high):int {.inline.} ## forward declaration

# procs lifted from terminal.nim as they are currently not exported from there
proc styledEchoProcessArg(s: string) = write stdout, s
proc styledEchoProcessArg(style: Style) = setStyle({style})
proc styledEchoProcessArg(style: set[Style]) = setStyle style
proc styledEchoProcessArg(color: ForegroundColor) = setForegroundColor color
proc styledEchoProcessArg(color: BackgroundColor) = setBackgroundColor color



# macros

macro styledEchoPrint*(m: varargs[untyped]): typed =
  ## lifted from terminal.nim and removed new line
  ## used in print
  ##
  let m = callsite()
  result = newNimNode(nnkStmtList)

  for i in countup(1, m.len - 1):
      result.add(newCall(bindSym"styledEchoProcessArg", m[i]))

  result.add(newCall(bindSym"write", bindSym"stdout", newStrLitNode("")))
  result.add(newCall(bindSym"resetAttributes"))


# templates
template currentLine*: int = instantiationInfo().line
   ## currentLine
   ## 
   ## simple template to return line number ,usefull for debugging 
   

template randPastelCol*: string = pastelSet[rxPastelCol.randomChoice()][1]
   ## randPastelCol
   ##
   ## get a randomcolor from pastelSet
   ##
   ## .. code-block:: nim
   ##    # print a string 6 times in a random color selected from pastelSet
   ##    loopy(0..5,printLn("Hello Random Color",randPastelCol()))
   ##
   ##

template msgg*(code: typed): typed =
      ## msgX templates
      ## convenience templates for colored text output
      ## the assumption is that the terminal is white text and black background
      ## naming of the templates is like msg+color so msgy => yellow
      ## use like : msgg() do : echo "How nice, it's in green"
      ## these templates have by large been superceded by various print and echo procs
      ## but are useful in some circumstances where a statement needs to be passed.
      ##
      ##
      ## .. code-block:: nim
      ##  msgy() do: echo "yellow"
      ##
      ##

      setForeGroundColor(fgGreen)
      code
      setForeGroundColor(fgWhite)


template msggb*(code: typed): typed   =
      setForeGroundColor(fgGreen,true)
      code
      setForeGroundColor(fgWhite)


template msgy*(code: typed): typed =
      setForeGroundColor(fgYellow)
      code
      setForeGroundColor(fgWhite)


template msgyb*(code: typed): typed =
      setForeGroundColor(fgYellow,true)
      code
      setForeGroundColor(fgWhite)

template msgr*(code: typed): typed =
      setForeGroundColor(fgRed)
      code
      setForeGroundColor(fgWhite)

template msgrb*(code: typed): typed =
      setForeGroundColor(fgRed,true)
      code
      setForeGroundColor(fgWhite)

template msgc*(code: typed): typed =
      setForeGroundColor(fgCyan)
      code
      setForeGroundColor(fgWhite)

template msgcb*(code: typed): typed =
      setForeGroundColor(fgCyan,true)
      code
      setForeGroundColor(fgWhite)

template msgw*(code: typed): typed =
      setForeGroundColor(fgWhite)
      code
      setForeGroundColor(fgWhite)

template msgwb*(code: typed): typed =
      setForeGroundColor(fgWhite,true)
      code
      setForeGroundColor(fgWhite)

template msgb*(code: typed): typed =
      setForeGroundColor(fgBlack,true)
      code
      setForeGroundColor(fgWhite)

template msgbb*(code: typed): typed =
      # invisible on black background
      setForeGroundColor(fgBlack)
      code
      setForeGroundColor(fgWhite)

template msgbl*(code: typed): typed =
      setForeGroundColor(fgBlue)
      code
      setForeGroundColor(fgWhite)

template msgblb*(code: typed): typed =
      setForeGroundColor(fgBlue,true)
      code
      setForeGroundColor(fgWhite)

template msgm*(code: typed): typed =
      setForeGroundColor(fgMagenta)
      code
      setForeGroundColor(fgWhite)

template msgmb*(code: typed): typed =
      setForeGroundColor(fgMagenta,true)
      code
      setForeGroundColor(fgWhite)

template hdx*(code:typed,frm:string = "+",width:int = tw,nxpos:int = 0):typed =
   ## hdx
   ##
   ## a simple sandwich frame made with + default or any string passed in
   ##
   ## width and xpos can be adjusted
   ##
   ## .. code-block:: nim
   ##    hdx(printLn("Nice things happen randomly",yellowgreen,xpos = 9),width = 35,nxpos = 5)
   ##
   var xpos = nxpos
   var lx = repeat(frm,width div frm.len)
   printLn(lx,xpos = xpos)
   cursetx(xpos + 2)
   code
   printLn(lx,xpos = xpos)
   echo()
   

proc isBlank*(val:string):bool {.inline.} =
   ## isBlank
   ## 
   ## returns true if a string is blank
   ## 
   return val == nil or val == ""


proc isEmpty*(val:string):bool {.inline.} =
   ## isEmpty
   ## 
   ## returns true if a string is empty if spaces are removed
   ## 

   return val == nil or val.strip() == ""


proc getRandomSignI*(): int = 
    ## getRandomSignI
    ## 
    ## returns -1 or 1 integer  to have a random positive or negative multiplier
    ##  
    var s = getRandomInt(0,1) 
    if s == 0:
       result = -1
    else :
       result = 1

    
proc getRandomSignF*():float = 
    ## getRandomSignF
    ## 
    ## returns -1.0 or 1.0 float  to have a random positive or negative multiplier
    ##  
  
  
    var s = getRandomInt(0,1) 
    if s == 0:
       result = -1.0   
    else :
       result = 1


proc fmtengine[T](a:string,astring:T):string =
     ## fmtengine   used internally
     ##
     ## simple string formater to right or left align within given param
     ##
     ## also can take care of floating point precision
     ##
     ## called by fmtx to process alignment requests
     ##
     var okstring = $astring
     var op  = ""
     var dg  = "0"
     var pad = okstring.len
     var dotflag = false
     var textflag = false
     var df = ""

     if a.startswith("<") or a.startswith(">"):
           textflag = false
     elif isdigit($a[0]):
           textflag = false
     else: textflag = true

     for x in a:

        if isDigit(x) and dotflag == false:
             dg = dg & $x

        elif isDigit(x) and dotflag == true:
             df = df & $x

        elif $x == "<" or $x == ">" :
                op = op & x
        else:
            # we got a char to print so add it to the okstring
            if textflag == true and dotflag == false:
               okstring = okstring & $x

        if $x == ".":
              # a float wants to be formatted
              dotflag = true

     pad = parseInt(dg)

     if dotflag == true and textflag == false:
               # floats should not be shown with thousand seperator
               # like 1,234.56  instead of 1234.56
               okstring = ff2(parseFloat(okstring),parseInt(df))       

     var alx = spaces(max(0,pad - okstring.len))

     case op
       of "<"  :   okstring = okstring & alx 
       of ">"  :   okstring = alx & okstring
       else: discard

     result = okstring



proc fmtx*[T](fmts:openarray[string],fstrings:varargs[T, `$`]):string =
     ## fmtx
     ##
     ## simple format utility similar to strfmt to accommodate our needs
     ##
     ## implemented :  right or left align within given param and float precision
     ##
     ##  returns a string
     ##
     ##  Some observations:
     ##
     ##  If text starts with a digit it must be on the right side...
     ##
     ##  Function calls must be executed on the right side
     ##
     ##  Space adjustment can be done with any "" on left or right side
     ##
     ##  an assert error is thrown if format block left and data block right are imbalanced
     ##
     ##  the "" acts as suitable placeholder
     ##
     ##  If one of the operator chars are needed as a first char in some text put it on the right side
     ##
     ##  Operator chars : <  >  .
     ##
     ## <12  means align left and pad so that max length = 12 and any following char will be in position 13
     ## >12  means align right so that the most right char is in position 12
     ## >8.2 means align a float right so that most right char is position 8 with precision 2
     ##
     ## Examples :
     ##
     ## .. code-block:: nim
     ##    echo fmtx(["","","<8.3",""," High : ","<8","","","","","","","",""],lime,"OPen : ",unquote("1234.5986"),yellow,"",3456.67,red,showRune("FFEC"),white," Change:",unquote("-1.34 - 0.45%"),"  Range : ",lime,@[123,456,789])
     ##    echo fmtx(["","<18",":",">15","","",">8.2"],salmon,"nice something",steelblue,123,spaces(5),yellow,456.12345676)
     ##    ruler()
     ##    echo fmtx([">22"],"nice something"inc c )
     ##    printlnBiCol(fmtx(["",">15.3f"],"Result : ",123.456789))  # formats the float to a string with precision 3 the f is not necessary
     ##    echo fmtx([">22.3"],234.43324234)  # this formats float and aligns last char tp pos 22
     ##    echo fmtx(["22.3"],234.43324234)   # this formats float but ignores position as no align operator given
     ##

     var okresult = ""
     # if formatstrings count not same as vararg count we bail out
     doassert(fmts.len == fstrings.len)
     # now iterate and generate the desired output
     for cc in 0.. <fmts.len:
         okresult = okresult & fmtengine(fmts[cc],fstrings[cc])
     result = okresult


proc showRune*(s:string) : string  =
     ## showRune
     ##
     ## utility proc to show a single unicode char
     ##
     ## note that not all unicode chars may be available on all systems
     ##
     ## .. code-block : nim
     ##      print(showRune("FFEA"),lime)
     ##      print(showRune("FFEC"),red)
     ##
     ##
     result = $Rune(parseHexInt(s))


proc unquote*(s:string):string =
    ## unquote
    ##
    ## remove any double quotes from a string
    ##
    result = replace(s,$'"',"")



proc cleanScreen*() =
      ## cleanScreen
      ##
      ## clear screen with escape seqs
      ##
      ## similar to terminal.eraseScreen() but cleans the terminal window completely
      ##
      write(stdout,"\e[H\e[J")



proc centerX*() : int = tw div 2
     ## centerX
     ##
     ## returns an int with terminal center position
     ##
     ##

proc centerPos*(astring:string) =
     ## centerpos
     ##
     ## tries to move cursor so that string is centered when printing
     ##
     ## .. code-block:: nim
     ##    var s = "Hello I am centered"
     ##    centerPos(s)
     ##    printLn(s,gray)
     ##
     ##
     setCursorXPos(stdout,centerX() - astring.len div 2 - 1)



proc checkColor*(colname: string): bool =
     ## checkColor
     ##
     ## returns true if colname is a known color name in colorNames
     ##
     ##
     result = false
     for x in  colorNames:
         if x[0] == colname:
            result = true
               


converter colconv*(cx:string) : string =
     # converter so we can use the same terminal color names for
     # fore- and background colors in print and printLn procs.
     var bg : string = ""
     case cx
      of black        : bg = bblack
      of white        : bg = bwhite
      of green        : bg = bgreen
      of yellow       : bg = byellow
      of cyan         : bg = bcyan
      of magenta      : bg = bmagenta
      of red          : bg = bred
      of blue         : bg = bblue
      of brightred    : bg = bbrightred
      of brightgreen  : bg = bbrightgreen
      of brightblue   : bg = bbrightblue
      of brightcyan   : bg = bbrightcyan
      of brightyellow : bg = bbrightyellow
      of brightwhite  : bg = bbrightwhite
      of brightmagenta: bg = bbrightmagenta
      of brightblack  : bg = bbrightblack
      of gray         : bg = gray
      else            : bg = bblack # default
     result = bg




proc print*[T](astring:T,fgr:string = termwhite ,bgr:string = bblack,xpos:int = 0,fitLine:bool = false ,centered:bool = false,styled : set[Style]= {},substr:string = "") =
    ## print
    ##
    ## fgr / bgr  fore and background colors can be set
    ##
    ## xpos allows positioning on x-axis
    ##
    ## fitLine = true will try to write the text into the current line irrespective of xpos
    ##
    ## centered = true will try to center and disregard xpos
    ## 
    ## styled allows style parameters to be set 
    ##
    ## available styles :
    ##
    ## styleBright = 1,            # bright text
    ##
    ## styleDim,                   # dim text
    ##
    ## styleUnknown,               # unknown
    ##
    ## styleUnderscore = 4,        # underscored text
    ##
    ## styleBlink,                 # blinking/bold text
    ##
    ## styleReverse = 7,           # reverses currentforground and backgroundcolor
    ##
    ## styleHidden                 # hidden text
    ##
    ##
    ## for extended colorset background colors use styleReverse
    ##
    ## or use 2 or more print statements for the desired effect
    ##

    var npos = xpos

    if centered == false:

        if npos > 0:  # the result of this is our screen position start with 1
            setCursorXPos(npos)

        if ($astring).len + xpos >= tw:

            if fitLine == true:
                # force to write on same line within in terminal whatever the xpos says
                npos = tw - ($astring).len
                setCursorXPos(npos)

    else:
          # centered == true
          npos = centerX() - ($astring).len div 2 - 1
          setCursorXPos(npos)


    if styled != {}:
          var s = $astring
                    
          if substr.len > 0:
              var rx = s.split(substr)
              for x in rx.low.. rx.high:
                  writestyled(rx[x],{})
                  if x != rx.high:
                    case fgr
                      of clrainbow   : printRainbow(substr,styled)
                      else: styledEchoPrint(fgr,styled,substr,termwhite)
          else:
               case fgr
                    of clrainbow   : printRainbow($s,styled)
                    else: styledEchoPrint(fgr,styled,s,termwhite)

    else:
      
        case fgr
          of clrainbow: rainbow(" " & $astring,npos)
          else: write(stdout,fgr & colconv(bgr) & $astring)

    # reset to white/black only if any changes
    if fgr != $fgWhite or bgr != $bgBlack:
      setForeGroundColor(fgWhite)
      setBackGroundColor(bgBlack)
      
      



proc printLn*[T](astring:T,fgr:string = termwhite , bgr:string = bblack,xpos:int = 0,fitLine:bool = false,centered:bool = false,styled : set[Style]= {},substr:string = "") =
    ## printLn
    ##
    ## similar to echo but with additional settings
    ##
    ## foregroundcolor
    ## backgroundcolor
    ## position
    ## fitLine
    ## centered
    ## styled
    ##
    ## all colornames are supported for font color:
    ##
    ## color names supported for background color:
    ##
    ## white,red,green,blue,yellow,cyan,magenta,black
    ##
    ## brightwhite,brightred,brightgreen,brightblue,brightyellow,
    ##
    ## brightcyan,brightmagenta,brightblack
    ##
    ## .. code-block:: nim
    ##    printLn("Yes ,  we made it.",clrainbow,brightyellow) # background has no effect with font in  clrainbow
    ##    printLn("Yes ,  we made it.",green,brightyellow)
    ##    # or use it as a replacement of echo
    ##    printLn(red & "What's up ? " & green & "Grub's up ! "
    ##    printLn("No need to reset the original color")
    ##    println("Nim does it again",peru,centered = true ,styled = {styleDim,styleUnderscore},substr = "i")
    ##

    print($(astring) & "\L",fgr,bgr,xpos,fitLine,centered,styled,substr)


proc rainbow*[T](s : T,xpos:int = 0,fitLine:bool = false,centered:bool = false) =
    ## rainbow
    ##
    ## multicolored string
    ##
    ## may not work with certain Rune
    ##
    ## .. code-block:: nim
    ##
    ##    # equivalent output
    ##    rainbow("what's up ?",centered = true)
    ##    echo()
    ##    println("what's up ?",clrainbow,centered = true)
    ##
    ##
    ##
    var nxpos = xpos
    var astr = $s
    var c = 0
    var a = toSeq(1.. <colorNames.len)

    for x in 0.. <astr.len:
       c = a[randomInt(a.len)]
       if centered == false:
          print(astr[x],colorNames[c][1],black,xpos = nxpos,fitLine)
       else:
          # need to calc the center here and increment by x
          nxpos = centerX() - ($astr).len div 2  + x - 1
          print(astr[x],colorNames[c][1],black,xpos=nxpos,fitLine)
       inc nxpos



# output  horizontal lines
proc hline*(n:int = tw,col:string = white) =
     ## hline
     ##
     ## draw a full line in stated length and color no linefeed will be issued
     ##
     ## defaults full terminal width and white
     ##
     ## .. code-block:: nim
     ##    hline(30,green)
     ##

     print(repeat("_",n),col)



proc hlineLn*(n:int = tw,col:string = white) =
     ## hlineLn
     ##
     ## draw a full line in stated length and color a linefeed will be issued
     ##
     ## defaults full terminal width and white
     ##
     ## .. code-block:: nim
     ##    hlineLn(30,green)
     ##
     print(repeat("_",n),col)
     echo()




proc dline*(n:int = tw,lt:string = "-",col:string = termwhite) =
     ## dline
     ##
     ## draw a dashed line with given length in current terminal font color
     ## line char can be changed
     ##
     ## .. code-block:: nim
     ##    dline(30)
     ##    dline(30,"/+")
     ##    dline(30,col= yellow)
     ##
     if lt.len <= n: print(repeat(lt,n div lt.len),col)


proc dlineLn*(n:int = tw,lt:string = "-",col:string = termwhite) =
     ## dlineLn
     ##
     ## draw a dashed line with given length in current terminal font color
     ## line char can be changed
     ##
     ## and issue a new line
     ##
     ## .. code-block:: nim
     ##    dline(50,":",green)
     ##    dlineLn(30)
     ##    dlineLn(30,"/+/")
     ##    dlineLn(60,col = salmon)
     ##
     if lt.len <= n:
         print(repeat(lt,n div lt.len),col)
     writeLine(stdout,"")


proc decho*(z:int = 1)  =
    ## decho
    ##
    ## blank lines creator
    ##
    ## .. code-block:: nim
    ##    decho(10)
    ## to create 10 blank lines
    for x in 0.. <z: writeLine(stdout,"")


# simple navigation mostly mirrors terminal.nim functions

template curUp*(x:int = 1) =
     ## curUp
     ##
     ## mirrors terminal cursorUp
     cursorUp(stdout,x)


template curDn*(x:int = 1) =
     ## curDn
     ##
     ## mirrors terminal cursorDown
     cursorDown(stdout,x)


template curBk*(x:int = 1) =
     ## curBkn
     ##
     ## mirrors terminal cursorBackward
     cursorBackward(stdout,x)


template curFw*(x:int = 1) =
     ## curFw
     ##
     ## mirrors terminal cursorForward
     cursorForward(stdout,x)


template curSetx*(x:int) =
     ## curSetx
     ##
     ## mirrors terminal setCursorXPos
     setCursorXPos(stdout,x)


template curSet*(x:int = 0,y:int = 0) =
     ## curSet
     ##
     ## mirrors terminal setCursorPos
     ##
     ##
     setCursorPos(x,y)


template clearup*(x:int = 80) =
     ## clearup
     ##
     ## a convenience proc to clear monitor x rows
     ##
     erasescreen(stdout)
     curup(x)


proc curMove*(up:int=0,dn:int=0,fw:int=0,bk:int=0) =
     ## curMove
     ##
     ## conveniently move the cursor to where you need it
     ##
     ## relative of current postion , which you app need to track itself
     ##
     ## setting cursor off terminal will wrap output to next line
     ##
     curup(up)
     curdn(dn)
     curfw(fw)
     curbk(bk)

proc sleepy*[T:float|int](secs:T) =
  ## sleepy
  ##
  ## imitates sleep but in seconds
  ## suitable for shorter sleeps
  ##
  var milsecs = (secs * 1000).int
  sleep(milsecs)




# Var. convenience procs for colorised data output
# these procs have similar functionality


proc printRainbow*(s : string,styled:set[Style] = {}) =
    ## printRainbow
    ##
    ##
    ## print multicolored string with styles , for available styles see print
    ##
    ## may not work with certain Rune
    ##
    ## .. code-block:: nim
    ##    printRainBow("WoW So Nice",{styleUnderScore})
    ##    printRainBow("  --> No Style",{})
    ##

    var astr = s
    var c = 0
    var a = toSeq(1.. <colorNames.len)
    for x in 0.. <astr.len:
       c = a[randomInt(a.len)]
       print($astr[x],colorNames[c][1],styled = styled)


proc printLnRainbow*[T](s : T,styled:set[Style]) =
    ## printLnRainbow
    ##
    ##
    ## print multicolored string with styles , for available styles see print
    ##
    ## and issues a new line
    ##
    ## may not work with certain Rune
    ##
    ## .. code-block:: nim
    ##    printLnRainBow("WoW So Nice",{styleUnderScore})
    ##    printLnRainBow("Aha --> No Style",{})
    ##
    printRainBow($(s) & "\L",styled)



proc printBiCol*[T](s:T,sep:string = ":",colLeft:string = yellowgreen ,colRight:string = termwhite,xpos:int = 0,centered:bool = false) =
     ## printBiCol
     ##
     ## echos a line in 2 colors based on a seperators first occurance
     ##
     ## default seperator = ":"
     ##
     ## Note : clrainbow not useable for right side color
     ##
     ## .. code-block:: nim
     ##    import cx,strutils,strfmt
     ##
     ##    for x  in 0.. <3:
     ##       # here use default colors for left and right side of the seperator
     ##       printBiCol("Test $1  : Ok this was $1 : what" % $x,":")
     ##
     ##    for x  in 4.. <6:
     ##        # here we change the default colors
     ##        printBiCol("Test $1  : Ok this was $1 : what" % $x,":",cyan,red)
     ##
     ##    # following requires strfmt module
     ##    printBiCol("{} : {}     {}".fmt("Good Idea","Number",50),":",yellow,green)
     ##
     ##
     var nosepflag:bool = false
     var zz = $s
     var z = zz.splitty(sep)  # using splitty we retain the sep on the left side

     # in case sep occures multiple time we only consider the first one
     if z.len > 1:
       for x in 2.. <z.len:
          # this now should contain the right part to be colored differently
          z[1] = z[1] & z[x]

     else:
          # when the separator is not found
          nosepflag = true
          # no separator so we just execute print with left color
          print(zz,fgr=colLeft,xpos=xpos,centered=centered)

     if nosepflag == false:

            if centered == false:
                  print(z[0],fgr = colLeft,bgr = black,xpos = xpos)
                  print(z[1],fgr = colRight,bgr = black)
            else:  # centered == true
                  let npos = centerX() - (zz).len div 2 - 1
                  print(z[0],fgr = colLeft,bgr = black,xpos = npos)
                  print(z[1],fgr = colRight,bgr = black)





proc printLnBiCol*[T](s:T,sep:string = ":", colLeft:string = yellowgreen, colRight:string = termwhite,xpos:int = 0,centered:bool = false) =
     ## printLnBiCol
     ##
     ## same as printBiCol but issues a new line
     ##
     ## default seperator = ":"  if not found we execute println with available params
     ##
     ## .. code-block:: nim
     ##    import cx,strutils,strfmt
     ##
     ##    for x  in 0.. <3:
     ##       # here use default colors for left and right side of the seperator
     ##       printLnBiCol("Test $1  : Ok this was $1 : what" % $x,":")
     ##
     ##    for x  in 4.. <6:
     ##        # here we change the default colors
     ##        printLnBiCol("Test $1  : Ok this was $1 : what" % $x,":",cyan,red)
     ##
     ##    # following requires strfmt module
     ##    printLnBiCol("{} : {}     {}".fmt("Good Idea","Number",50),":",yellow,green)
     ##
     ##
     var nosepflag:bool = false
     var zz = $s
     var z = zz.splitty(sep)  # using splitty we retain the sep on the left side
     # in case sep occures multiple time we only consider the first one

     if z.len > 1:
       for x in 2.. <z.len:
           z[1] = z[1] & z[x]
     else:
          # when the separator is not found
          nosepflag = true
          # no separator so we just execute println with left color
          println(zz,fgr=colLeft,xpos=xpos,centered=centered)

     if nosepflag == false:

        if centered == false:
              print(z[0],fgr = colLeft,bgr = black,xpos = xpos)
              if colRight == clrainbow:   # we currently do this as rainbow implementation has changed
                    printLn(z[1],fgr = randcol(),bgr = black)
              else:
                    printLn(z[1],fgr = colRight,bgr = black)

        else:  # centered == true
              let npos = centerX() - zz.len div 2 - 1
              print(z[0],fgr = colLeft,bgr = black,xpos = npos)
              if colRight == clrainbow:   # we currently do this as rainbow implementation has changed
                    printLn(z[1],fgr = randcol(),bgr = black)
              else:
                    printLn(z[1],fgr = colRight,bgr = black)




proc printHl*(s:string,substr:string,col:string = termwhite) =
      ## printHl
      ##
      ## print and highlight all appearances of a char or substring of a string
      ##
      ## with a certain color
      ##
      ## .. code-block:: nim
      ##    printHl("HELLO THIS IS A TEST","T",green)
      ##
      ## this would highlight all T in green
      ##

      var rx = s.split(substr)
      for x in rx.low.. rx.high:
          print(rx[x])
          if x != rx.high:
             print(substr,col)


proc printLnHl*(s:string,substr:string,col:string = termwhite) =
      ## printLnHl
      ##
      ## print and highlight all appearances of a char or substring of a string
      ##
      ## with a certain color and issue a new line
      ##
      ## .. code-block:: nim
      ##    printLnHl("HELLO THIS IS A TEST","T",yellowgreen)
      ##
      ## this would highlight all T in yellowgreen
      ##

      printHl($(s) & "\L",substr,col)


proc cecho*(col:string,ggg: varargs[string, `$`] = @[""] )  =
      ## cecho
      ##
      ## color echo w/o new line this also automically resets the color attribute
      ##
      ##
      ## .. code-block:: nim
      ##     import cx,strfmt
      ##     cechoLn(salmon,"{:<10} : {} ==> {} --> {}".fmt("this ", "zzz ",123 ," color is something else"))
      ##     echo("ok")  # color resetted
      ##     echo(salmon,"{:<10} : {} ==> {} --> {}".fmt("this ", "zzz ",123 ," color is something else"))
      ##     echo("ok")  # still salmon

      case col
       of clrainbow :
                for x in ggg:  rainbow(x)
       else:
         write(stdout,col)
         write(stdout,ggg)
         
      write(stdout,termwhite)


proc cechoLn*(col:string,ggg: varargs[string, `$`] = @[""] )  =
      ## cechoLn
      ##
      ## color echo with new line
      ##
      ## so it is easy to color your output by just replacing
      ##
      ## echo something  with   cechoLn yellowgreen,something
      ##
      ## in your exisiting projects.
      ##
      ## .. code-block:: nim
      ##     import cx,strutils
      ##     cechoLn(steelblue,"We made it in $1 hours !" % $5)
      ##
      ##
      var z = ""
      for x in ggg: z = $(x)
      z = z & "\L"
      cecho(col ,z)


proc showColors*() =
  ## showColors
  ##
  ## display all colorNames in color !
  ##
  for x in colorNames:
     print(fmtx(["<22"],x[0]) & spaces(2) & "▒".repeat(10) & spaces(2) & "⌘".repeat(10) & spaces(2) & "ABCD abcd 1234567890 --> " & " Nim Colors  " , x[1],black)
     printLn(fmtx(["<23"],"  " & x[0]) ,x[1],styled = {styleReverse},substr =  fmtx(["<23"],"  " & x[0]))
     sleepy(0.075)
  decho(2)



macro dotColors*(): untyped =
  ## dotColors
  ## 
  ## another way to show all colors
  ##  
  result = parseStmt"""for x in colornames : println(widedot & x[0],x[1])"""



proc doty*(d:int,fgr:string = white, bgr:string = black,xpos:int = 1) =
     ## doty
     ##
     ## prints number d of widedot ⏺  style dots in given fore/background color
     ##
     ## each dot is of char length 4 added a space in the back to avoid half drawn dots
     ##
     ## if it is available on your system otherwise a rectangle may be shown
     ##
     ## .. code-block:: nimble
     ##      import cx
     ##      printLnBiCol("Test for  :  doty\n",":",truetomato,lime)
     ##      dotyLn(22 ,lime)
     ##      dotyLn(18 ,salmon,blue)
     ##      dotyLn(centerX(),red)  # full widedotted line
     ##
     ## color clrainbow is not supported and will be in white
     ##

     var astr = $(wideDot.repeat(d))
     if fgr == clrainbow: print(astring = astr,white,bgr,xpos)
     else: print(astring = astr,fgr,bgr,xpos)


proc dotyLn*(d:int,fgr:string = white, bgr:string = black,xpos:int = 1) =
     ## dotyLn
     ##
     ## prints number d of widedot ⏺  style dots in given fore/background color and issues new line
     ##
     ## each dot is of char length 4

     ## .. code-block:: nimble
     ##      import cx
     ##      loopy(0.. 100,loopy(1.. tw div 2, dotyLn(1,randcol(),xpos = random(tw - 1))))
     ##      printlnBiCol("coloredSnow","d",greenyellow,salmon)

     ##
     ## color clrainbow is not supported and will be in white
     ##
     ##
     doty(d,fgr,bgr,xpos)
     writeLine(stdout,"")



proc printDotPos*(xpos:int,dotCol:string,blink:bool) =
      ## printDotPos
      ##
      ## prints a widedot at xpos in col dotCol and may blink ...
      ##

      curSetx(xpos)
      if blink == true: print(wideDot,dotCol,styled = {styleBlink},substr = wideDot)
      else: print(wideDot,dotCol,styled = {},substr = wideDot)


proc drawRect*(h:int = 0 ,w:int = 3, frhLine:string = "_", frVLine:string = "|",frCol:string = darkgreen,dotCol = truetomato,xpos:int = 1,blink:bool = false) =
      ## drawRect
      ##
      ## a simple proc to draw a rectangle with corners marked with widedots.
      ## widedots are of len 4.
      ##
      ##
      ## h  height
      ## w  width
      ## frhLine framechar horizontal
      ## frVLine framechar vertical
      ## frCol   color of line
      ## dotCol  color of corner dotCol
      ## xpos    topleft start position
      ## blink   true or false to blink the dots
      ##
      ##
      ## .. code-block:: nim
      ##    import cx
      ##    clearUp(18)
      ##    curSet()
      ##    drawRect(15,24,frhLine = "+",frvLine = wideDot , frCol = randCol(),xpos = 8)
      ##    curup(12)
      ##    drawRect(9,20,frhLine = "=",frvLine = wideDot , frCol = randCol(),xpos = 10,blink = true)
      ##    curup(12)
      ##    drawRect(9,20,frhLine = "=",frvLine = wideDot , frCol = randCol(),xpos = 35,blink = true)
      ##    curup(10)
      ##    drawRect(6,14,frhLine = "~",frvLine = "$" , frCol = randCol(),xpos = 70,blink = true)
      ##    decho(5)
      ##    doFinish()
      ##
      ##

      # topline
      printDotPos(xpos,dotCol,blink)
      print(frhLine.repeat(w - 3),frcol)
      if frhLine == widedot: printDotPos(xpos + w * 2 - 1 ,dotCol,blink)
      else: printDotPos(xpos + w,dotCol,blink)
      writeLine(stdout,"")
      # sidelines
      for x in 2.. h:
         print(frVLine,frcol,xpos = xpos)
         if frhLine == widedot: print(frVLine,frcol,xpos = xpos + w * 2 - 1)
         else: print(frVLine,frcol,xpos = xpos + w)
         writeLine(stdout,"")
      # bottom line
      printDotPos(xpos,dotCol,blink)
      print(frhLine.repeat(w - 3),frcol)
      if frhLine == widedot:printDotPos(xpos + w * 2 - 1 ,dotCol,blink)
      else: printDotPos(xpos + w,dotCol,blink)

      writeLine(stdout,"")


# Var. date and time handling procs mainly to provide convenience for
# date format yyyy-MM-dd handling

proc validdate*(adate:string):bool =
      ## validdate
      ##
      ## try to ensure correct dates of form yyyy-MM-dd
      ##
      ## correct : 2015-08-15
      ##
      ## wrong   : 2015-08-32 , 201508-15, 2015-13-10 etc.
      ##
      let m30 = @["04","06","09","11"]
      let m31 = @["01","03","05","07","08","10","12"]
      let xdate = parseInt(aDate.replace("-",""))
      # check 1 is our date between 1900 - 3000
      if xdate > 19000101 and xdate < 30001212:
          var spdate = aDate.split("-")
          if parseInt(spdate[0]) >= 1900 and parseInt(spdate[0]) <= 3000:
              if spdate[1] in m30:
                  #  day max 30
                  if parseInt(spdate[2]) > 0 and parseInt(spdate[2]) < 31:
                    result = true
                  else:
                    result = false

              elif spdate[1] in m31:
                  # day max 31
                  if parseInt(spdate[2]) > 0 and parseInt(spdate[2]) < 32:
                    result = true
                  else:
                    result = false

              else:
                    # so its february
                    if spdate[1] == "02" :
                        # check leapyear
                        if isleapyear(parseInt(spdate[0])) == true:
                            if parseInt(spdate[2]) > 0 and parseInt(spdate[2]) < 30:
                              result = true
                            else:
                              result = false
                        else:
                            if parseInt(spdate[2]) > 0 and parseInt(spdate[2]) < 29:
                              result = true
                            else:
                              result = false


proc day*(aDate:string) : string =
   ## day,month year extracts the relevant part from
   ##
   ## a date string of format yyyy-MM-dd
   ##
   aDate.split("-")[2]

proc month*(aDate:string) : string =
    var asdm = $(parseInt(aDate.split("-")[1]))
    if len(asdm) < 2: asdm = "0" & asdm
    result = asdm


proc year*(aDate:string) : string = aDate.split("-")[0]
     ## Format yyyy



proc intervalsecs*(startDate,endDate:string) : float =
      ## interval procs returns time elapsed between two dates in secs,hours etc.
      #  since all interval routines call intervalsecs error message display also here
      #
      if validdate(startDate) and validdate(endDate):
          var f     = "yyyy-MM-dd"
          result = toSeconds(toTime(endDate.parse(f)))  - toSeconds(toTime(startDate.parse(f)))
      else:
          println("Error: " &  startDate & "/" & endDate & " --> Format yyyy-MM-dd required",red)
          #result = -0.0

proc intervalmins*(startDate,endDate:string) : float =
           var imins = intervalsecs(startDate,endDate) / 60
           result = imins


proc intervalhours*(startDate,endDate:string) : float =
         var ihours = intervalsecs(startDate,endDate) / 3600
         result = ihours


proc intervaldays*(startDate,endDate:string) : float =
          var idays = intervalsecs(startDate,endDate) / 3600 / 24
          result = idays

proc intervalweeks*(startDate,endDate:string) : float =
          var iweeks = intervalsecs(startDate,endDate) / 3600 / 24 / 7
          result = iweeks


proc intervalmonths*(startDate,endDate:string) : float =
          var imonths = intervalsecs(startDate,endDate) / 3600 / 24 / 365  * 12
          result = imonths

proc intervalyears*(startDate,endDate:string) : float =
          var iyears = intervalsecs(startDate,endDate) / 3600 / 24 / 365
          result = iyears


proc compareDates*(startDate,endDate:string) : int =
     # dates must be in form yyyy-MM-dd
     # we want this to answer
     # s == e   ==> 0
     # s >= e   ==> 1
     # s <= e   ==> 2
     # -1 undefined , invalid s date
     # -2 undefined . invalid e and or s date
     if validdate(startDate) and validdate(enddate):
        var std = startDate.replace("-","")
        var edd = endDate.replace("-","")
        if std == edd:
          result = 0
        elif std >= edd:
          result = 1
        elif std <= edd:
          result = 2
        else:
          result = -1
     else:
          result = -2


proc dayOfWeekJulianA*(day, month, year: int): WeekDay =
  #
  # may be part of times.nim later
  # This is for the Julian calendar
  # Day & month start from one.
  # original code from coffeepot
  # but seems to be off for dates after 2100-03-01 which should be a monday
  # but it returned a tuesday ..
  #
  let
    a = (14 - month) div 12
    y = year - a
    m = month + (12 * a) - 2
  var d  = (5 + day + y + (y div 4) + (31 * m) div 12) mod 7
  # The value of d is 0 for a Sunday, 1 for a Monday, 2 for a Tuesday, etc. so we must correct
  # for the WeekDay type.
  result = d.WeekDay


proc dayOfWeekJulian*(datestr:string): string =
   ## dayOfWeekJulian
   ##
   ## returns the day of the week of a date given in format yyyy-MM-dd as string
   ##
   ## valid for dates up to 2099-12-31
   ##
   ## actually starts to fail with 2100-03-01 which shud be a monday but this proc says tuesday
   ##
   ##
   if parseInt(year(datestr)) < 2100:
     let dw = dayofweekjulianA(parseInt(day(datestr)),parseInt(month(datestr)),parseInt(year(datestr)))
     result = $dw
   else:
     result = "Not defined for years > 2099"


proc fx(nx:TimeInfo):string =
        result = nx.format("yyyy-MM-dd")


proc plusDays*(aDate:string,days:int):string =
   ## plusDays
   ##
   ## adds days to date string of format yyyy-MM-dd  or result of getDateStr()
   ##
   ## and returns a string of format yyyy-MM-dd
   ##
   ## the passed in date string must be a valid date or an error message will be returned
   ##
   if validdate(aDate) == true:
      var rxs = ""
      let tifo = parse(aDate,"yyyy-MM-dd") # this returns a TimeInfo type
      var myinterval = initInterval()
      myinterval.days = days
      rxs = fx(tifo + myinterval)
      result = rxs
   else:
      cechoLn(red,"Date error : ",aDate)
      result = "Error"


proc minusDays*(aDate:string,days:int):string =
   ## minusDays
   ##
   ## subtracts days from a date string of format yyyy-MM-dd  or result of getDateStr()
   ##
   ## and returns a string of format yyyy-MM-dd
   ##
   ## the passed in date string must be a valid date or an error message will be returned
   ##

   if validdate(aDate) == true:
      var rxs = ""
      let tifo = parse(aDate,"yyyy-MM-dd") # this returns a TimeInfo type
      var myinterval = initInterval()
      myinterval.days = days
      rxs = fx(tifo - myinterval)
      result = rxs
   else:
      cechoLn(red,"Date error : ",aDate)
      result = "Error"


proc getFirstMondayYear*(ayear:string):string =
    ## getFirstMondayYear
    ##
    ## returns date of first monday of any given year
    ## should be ok for the next years but after 2100-02-28 all bets are off
    ##
    ##
    ## .. code-block:: nim
    ##    echo  getFirstMondayYear("2015")
    ##
    ##
 
    for x in 1.. 8:
       var datestr= ayear & "-01-0" & $x
       if validdate(datestr) == true:
          if dayofweekjulian(datestr) == "Monday": result = datestr



proc getFirstMondayYearMonth*(aym:string):string =
    ## getFirstMondayYearMonth
    ##
    ## returns date of first monday in given year and month
    ##
    ## .. code-block:: nim
    ##    echo  getFirstMondayYearMonth("2015-12")
    ##    echo  getFirstMondayYearMonth("2015-06")
    ##    echo  getFirstMondayYearMonth("2015-2")
    ##
    ## in case of invalid dates nil will be returned
    ## should be ok for the next years but after 2100-02-28 all bets are off

    #var n:WeekDay
    var amx = aym
    for x in 1.. 8:
       if aym.len < 7:
          let yr = year(amx)
          let mo = month(aym)  # this also fixes wrong months
          amx = yr & "-" & mo
       var datestr = amx & "-0" & $x
       if validdate(datestr) == true:
          if dayofweekjulian(datestr) == "Monday":
            result = datestr



proc getNextMonday*(adate:string):string =
    ## getNextMonday
    ##
    ## .. code-block:: nim
    ##    echo  getNextMonday(getDateStr())
    ##
    ##
    ## .. code-block:: nim
    ##      import cx
    ##      # get next 10 mondays
    ##      var dw = "2015-08-10"
    ##      for x in 1.. 10:
    ##          dw = getNextMonday(dw)
    ##          echo dw
    ##
    ##
    ## in case of invalid dates nil will be returned
    ##

    #var n:WeekDay
    var ndatestr = ""
    if isNil(adate) == true :
        print("Error received a date with value : nil",red)
    else:

        if validdate(adate) == true:
            var z = dayofweekjulian(adate)

            if z == "Monday":
              # so the datestr points to a monday we need to add a
              # day to get the next one calculated
                ndatestr = plusDays(adate,1)

            else:
                ndatestr = adate

            for x in 0.. <7:
              if validdate(ndatestr) == true:
                z = dayofweekjulian(ndatestr)

                if z.strip() != "Monday":
                    ndatestr = plusDays(ndatestr,1)
                else:
                    result = ndatestr


# large font printing, numbers are implemented

proc printBigNumber*(xnumber:string|int,fgr:string = yellowgreen ,bgr:string = black,xpos:int = 1,fun:bool = false) =
    ## printBigNumber
    ##
    ## prints a string in big block font
    ##
    ## available 1234567890:
    ##
    ##
    ## if fun parameter = true then foregrouncolor will be ignored and every block
    ##
    ## element colored individually
    ##
    ##
    ## xnumber can be given as int or string
    ##
    ## usufull for big counter etc , a clock can also be build easily but
    ## running in a tight while loop just uses up cpu cycles needlessly.
    ##
    ## .. code-block:: nim
    ##    for x in 990.. 1105:
    ##         cleanScreen()
    ##         printBigNumber(x)
    ##         sleepy(3)
    ##
    ##    cleanScreen()
    ##
    ##    printBigNumber($23456345,steelblue)
    ##
    ## .. code-block:: nim
    ##    import cx
    ##    for x in countdown(9,0):
    ##         cleanScreen()
    ##         if x == 5:
    ##             for y in countup(10,25):
    ##                 cleanScreen()
    ##                 printBigNumber($y,tomato)
    ##                 sleepy(0.5)
    ##         cleanScreen()
    ##         printBigNumber($x)
    ##         sleepy(0.5)
    ##    doFinish()

    var anumber = $xnumber
    var asn = newSeq[string]()
    var printseq = newSeq[seq[string]]()
    for x in anumber: asn.add($x)
    for x in asn:
      case  x
        of "0": printseq.add(number0)
        of "1": printseq.add(number1)
        of "2": printseq.add(number2)
        of "3": printseq.add(number3)
        of "4": printseq.add(number4)
        of "5": printseq.add(number5)
        of "6": printseq.add(number6)
        of "7": printseq.add(number7)
        of "8": printseq.add(number8)
        of "9": printseq.add(number9)
        of ":": printseq.add(colon)
        of " ": printseq.add(clrb)
        else: discard

    for x in 0.. numberlen:
        curSetx(xpos)
        for y in 0.. <printseq.len:
            if fun == false:
               print(" " & printseq[y][x],fgr,bgr)
            else:
                # we want to avoid black
                var funny = randcol()
                while funny == black:
                     funny = randcol()
                print(" " & printseq[y][x],funny,bgr)
        echo()
    curup(5)




proc printBigLetters*(aword:string,fgr:string = yellowgreen ,bgr:string = black,xpos:int = 1,k:int = 7,fun:bool = false) =
  ## printBigLetters
  ##
  ## prints big block letters in desired color at desired position
  ##
  ## note position must be specified as global in format :   var xpos = 5
  ##
  ## if fun parameter = true then foregrouncolor will be ignored and every block
  ##
  ## element colored individually
  ##
  ## k parameter specifies character distance reasonable values are 7,8,9,10 . Default = 7
  ##
  ## also note that depending on terminal width only a limited number of chars can be displayed
  ##
  ##
  ##
  ## .. code-block:: nim
  ##       printBigLetters("ABA###RR#3",xpos = 1)
  ##       printBigLetters("#",xpos = 1)   # the '#' char is used to denote a blank space or to overwrite
  ##

  var xpos = xpos
  template abc(s:typed,xpos:int) =
      # abc
      #
      # template to support printBigLetters
      #

      for x in 0.. 4:
        if fun == false:
           printLn(s[x],fgr = fgr,bgr = bgr ,xpos = xpos)
        else:
           # we want to avoid black
           var funny = randcol()
           while funny == black:
               funny = randcol()
           printLn(s[x],fgr = funny,bgr = bgr ,xpos = xpos)
      curup(5)
      xpos = xpos + k

  for aw in aword:
      var aws = $aw
      var ak = aws.toLower()
      case ak
      of "a" : abc(abx,xpos)
      of "b" : abc(bbx,xpos)
      of "c" : abc(cbx,xpos)
      of "d" : abc(dbx,xpos)
      of "e" : abc(ebx,xpos)
      of "f" : abc(fbx,xpos)
      of "g" : abc(gbx,xpos)
      of "h" : abc(hbx,xpos)
      of "i" : abc(ibx,xpos)
      of "j" : abc(jbx,xpos)
      of "k" : abc(kbx,xpos)
      of "l" : abc(lbx,xpos)
      of "m" : abc(mbx,xpos)
      of "n" : abc(nbx,xpos)
      of "o" : abc(obx,xpos)
      of "p" : abc(pbx,xpos)
      of "q" : abc(qbx,xpos)
      of "r" : abc(rbx,xpos)
      of "s" : abc(sbx,xpos)
      of "t" : abc(tbx,xpos)
      of "u" : abc(ubx,xpos)
      of "v" : abc(vbx,xpos)
      of "w" : abc(wbx,xpos)
      of "x" : abc(xbx,xpos)
      of "y" : abc(ybx,xpos)
      of "z" : abc(zbx,xpos)
      of "-" : abc(hybx,xpos)
      of "+" : abc(plbx,xpos)
      of "_" : abc(ulbx,xpos)
      of "=" : abc(elbx,xpos)
      of "#" : abc(clbx,xpos)
      of "1","2","3","4","5","6","7","8","9","0",":":
               printBigNumber($aw,fgr = fgr , bgr = bgr,xpos = xpos,fun = fun)
               curup(5)
               xpos = xpos + k
      of " " : xpos = xpos + 2
      else: discard




proc printNimSxR*(nimsx:seq[string],col:string = yellowgreen, xpos: int = 1) =
    ## printNimSxR
    ##
    ## prints large Letters or a word which have been predefined
    ##
    ## see values of nimsx1 and nimsx2 above
    ##
    ##
    ## .. code-block:: nim
    ##    printNimSxR(nimsx,xpos = 10)
    ##
    ## allows x positioning
    ##
    ## in your calling code arrange that most right one is printed first
    ##

    var sxpos = xpos
    var maxl = 0

    for x in nimsx:
      if maxl < x.len:
          maxl = x.len

    var maxpos = cx.tw - maxl div 2

    if xpos > maxpos:
          sxpos = maxpos

    for x in nimsx :
          printLn(" ".repeat(xpos) & x,randcol())



proc printSlimNumber*(anumber:string,fgr:string = yellowgreen ,bgr:string = black,xpos:int = 1) =
    ## printSlimNumber
    ##
    ## # will shortly be deprecated use:  printSlim
    ##
    ## prints an string in big slim font
    ##
    ## available chars 123456780,.:
    ##
    ##
    ## usufull for big counter etc , a clock can also be build easily but
    ## running in a tight while loop just uses up cpu cycles needlessly.
    ##
    ## .. code-block:: nim
    ##    for x in 990.. 1005:
    ##         cleanScreen()
    ##         printSlimNumber($x)
    ##         sleep(750)
    ##    echo()
    ##
    ##    printSlimNumber($23456345,blue)
    ##    decho(2)
    ##    printSlimNumber("1234567:345,23.789",fgr=salmon,xpos=20)
    ##    sleep(1500)
    ##    import times
    ##    cleanScreen()
    ##    decho(2)
    ##    printSlimNumber($getClockStr(),fgr=salmon,xpos=20)
    ##    decho(5)
    ##
    ##    for x in rxCol:
    ##       printSlimNumber($x,colorNames[x][1])
    ##       curup(3)
    ##       sleep(500)
    ##    curdn(3)

    var asn = newSeq[string]()
    var printseq = newSeq[seq[string]]()
    for x in anumber: asn.add($x)
    for x in asn:
      case  x
        of "0": printseq.add(snumber0)
        of "1": printseq.add(snumber1)
        of "2": printseq.add(snumber2)
        of "3": printseq.add(snumber3)
        of "4": printseq.add(snumber4)
        of "5": printseq.add(snumber5)
        of "6": printseq.add(snumber6)
        of "7": printseq.add(snumber7)
        of "8": printseq.add(snumber8)
        of "9": printseq.add(snumber9)
        of ":": printseq.add(scolon)
        of ",": printseq.add(scomma)
        of ".": printseq.add(sdot)
        else: discard

    for x in 0.. 2:
        curSetx(xpos)
        for y in 0.. <printseq.len:
            print(" " & printseq[y][x],fgr,bgr)
        writeLine(stdout,"")



proc slimN(x:int):T7 =
  # supporting slim number printing
  var nnx : T7
  case x
    of 0: nnx.zx = snumber0
    of 1: nnx.zx = snumber1
    of 2: nnx.zx = snumber2
    of 3: nnx.zx = snumber3
    of 4: nnx.zx = snumber4
    of 5: nnx.zx = snumber5
    of 6: nnx.zx = snumber6
    of 7: nnx.zx = snumber7
    of 8: nnx.zx = snumber8
    of 9: nnx.zx = snumber9
    else: discard
  result = nnx


proc slimC(x:string):T7 =
  # supporting slim chars printing
  var nnx:T7
  case x
    of ".": nnx.zx = sdot
    of ",": nnx.zx = scomma
    of ":": nnx.zx = scolon
    of " ": nnx.zx = sblank
    else : discard
  result = nnx


proc prsn(x:int,fgr:string = termwhite,bgr:string = termblack,xpos:int = 0) =
     # print routine for slim numbers
     for x in slimN(x).zx: println(x,fgr = fgr,bgr = bgr,xpos = xpos)

proc prsc(x:string,fgr:string = termwhite,bgr:string = termblack,xpos:int = 0) =
     # print routine for slim chars
     for x in slimc(x).zx: println($x,fgr = fgr,bgr = bgr,xpos = xpos)


proc printSlim* (ss:string = "", frg:string = termwhite,bgr:string = termblack,xpos:int = 0,align:string = "left") =
    ## printSlim
    ##
    ## prints available slim numbers and slim chars
    ##
    ## right alignment : the string will be written left of xpos position
    ## left  alignment : the string will be written right of xpos position
    ##
    ## make sure enough space is available left or right of xpos
    ##
    ## .. code-block:: nim
    ##      printSlim($"82233.32",salmon,xpos = 25,align = "right")
    ##      decho(3)
    ##      printSlim($"33.87",salmon,xpos = 25,align = "right")
    ##      ruler(25,lime)
    ##      decho(3)
    ##      printSlim($"82233.32",peru,xpos = 25)
    ##      decho(3)
    ##      printSlim($"33.87",peru,xpos = 25)
    ##

    var npos = xpos
    #if we want to right align we need to know the overall length, which needs a scan
    var sswidth = 0
    if align.toLower() == "right":
      for x in ss:
         if $x in slimCharSet:
           sswidth = sswidth + 1
         else:
           sswidth = sswidth + 3

    for x in ss:
      if $x in slimcharset:
        prsc($x ,frg,bgr, xpos = npos - sswidth)
        npos = npos + 1
        curup(3)
      else:
        var mn:int = parseInt($x)
        prsn(mn ,frg,bgr, xpos = npos - sswidth)
        npos = npos + 3
        curup(3)



# Framed headers with var. colorising options

proc superHeader*(bstring:string) =
      ## superheader
      ##
      ## a framed header display routine
      ##
      ## suitable for one line headers , overlong lines will
      ##
      ## be cut to terminal window width without ceremony
      ##
      ## for box with or without intersections see drawBox
      ##
      var astring = bstring
      # minimum default size that is string max len = 43 and
      # frame = 46
      let mmax = 43
      var mddl = 46
      ## max length = tw-2
      let okl = tw - 6
      let astrl = astring.len
      if astrl > okl :
        astring = astring[0.. okl]
        mddl = okl + 5
      elif astrl > mmax :
          mddl = astrl + 4
      else :
          # default or smaller
          let n = mmax - astrl
          for x in 0.. <n:
              astring = astring & " "
          mddl = mddl + 1

      # some framechars choose depending on what the system has installed
      #let framechar = "▒"
      let framechar = "⌘"
      #let framechar = "⏺"
      #let framechar = "~"
      let pdl = framechar.repeat(mddl)
      # now show it with the framing in yellow and text in white
      # really want a terminal color checker to avoid invisible lines
      echo()
      printLn(pdl,yellowgreen)
      print(framechar & " ",yellowgreen)
      print(astring)
      printLn(" " & framechar,yellowgreen)
      printLn(pdl,yellowgreen)
      echo()



proc superHeader*(bstring:string,strcol:string,frmcol:string) =
        ## superheader
        ##
        ## a framed header display routine
        ##
        ## suitable for one line headers , overlong lines will
        ##
        ## be cut to terminal window size without ceremony
        ##
        ## the color of the string can be selected, available colors
        ##
        ## green,red,cyan,white,yellow and for going completely bonkers the frame
        ##
        ## can be set to clrainbow too .
        ##
        ## .. code-block:: nim
        ##    import cx
        ##
        ##    superheader("Ok That's it for Now !",clrainbow,white)
        ##    echo()
        ##
        var astring = bstring
        # minimum default size that is string max len = 43 and
        # frame = 46
        let mmax = 43
        var mddl = 46
        let okl = tw - 6
        let astrl = astring.len
        if astrl > okl :
          astring = astring[0.. okl]
          mddl = okl + 5
        elif astrl > mmax :
            mddl = astrl + 4
        else :
            # default or smaller
            let n = mmax - astrl
            for x in 0.. <n:
                astring = astring & " "
            mddl = mddl + 1

        let framechar = "⌘"
        #let framechar = "~"
        let pdl = framechar.repeat(mddl)
        # now show it with the framing in yellow and text in white
        # really want to have a terminal color checker to avoid invisible lines
        echo()

        # frame line
        proc frameline(pdl:string) =
            print(pdl,frmcol)
            echo()

        proc framemarker(am:string) =
            print(am,frmcol)

        proc headermessage(astring:string)  =
            print(astring,strcol)


        # draw everything
        frameline(pdl)
        #left marker
        framemarker(framechar & " ")
        # header message sring
        headermessage(astring)
        # right marker
        framemarker(" " & framechar)
        # we need a new line
        echo()
        # bottom frame line
        frameline(pdl)
        # finished drawing


proc superHeaderA*(bb:string = "",strcol:string = white,frmcol:string = green,anim:bool = true,animcount:int = 1) =
      ## superHeaderA
      ##
      ## attempt of an animated superheader , some defaults are given
      ##
      ## parameters for animated superheaderA :
      ##
      ## headerstring, txt color, frame color, left/right animation : true/false ,animcount
      ##
      ## Example :
      ##
      ## .. code-block:: nim
      ##    import cx
      ##    cleanScreen()
      ##    let bb = "NIM the system language for the future, which extends to as far as you need !!"
      ##    superHeaderA(bb,white,red,true,1)
      ##    clearup(3)
      ##    superheader("Ok That's it for Now !",salmon,yellowgreen)
      ##    doFinish()

      for am in 0..<animcount:
          for x in 0.. <1:
            cleanScreen()
            for zz in 0.. bb.len:
                  cleanScreen()
                  superheader($bb[0.. zz],strcol,frmcol)
                  sleep(500)
                  curup(80)
            if anim == true:
                for zz in countdown(bb.len,-1,1):
                      superheader($bb[0.. zz],strcol,frmcol)
                      sleep(100)
                      cleanScreen()
            else:
                cleanScreen()
            sleep(500)

      echo()


# Var. internet related procs

proc getWanIp*():string =
   ## getWanIp
   ##
   ## get your wan ip from heroku
   ##
   ## problems ? check : https://status.heroku.com/

   var z = "Wan Ip not established. "
   try:
      z = getContent("http://my-ip.heroku.com",timeout = 1000)
      z = z.replace(sub = "{",by = " ").replace(sub = "}",by = " ").replace(sub = "\"ip\":"," ").replace(sub = '"' ,' ').strip()
   except:
       print("Ip checking failed. See if heroku is still here",red)
       print("Check Heroku Status : https://status.heroku.com",red)
       try:
         opendefaultbrowser("https://status.heroku.com")
       except:
         discard
   result = z


proc showWanIp*() =
     ## showWanIp
     ##
     ## show your current wan ip
     ##
     printBiCol("Current Wan Ip  : " & getwanip(),":",yellowgreen,gray)


proc getIpInfo*(ip:string):JsonNode =
     ## getIpInfo
     ##
     ## use ip-api.com free service limited to abt 250 requests/min
     ##
     ## exceeding this you will need to unlock your wan ip manually at their site
     ##
     ## the JsonNode is returned for further processing if needed
     ##
     ## and can be queried like so
     ##
     ## .. code-block:: nim
     ##   var jj = getIpInfo("208.80.152.201")
     ##   echo mpairs(jz)
     ##   echo jj["city"].getstr
     ##
     ##
     if ip != "":
        result = parseJson(getContent("http://ip-api.com/json/" & ip))



proc showIpInfo*(ip:string) =
      ## showIpInfo
      ##
      ## Displays details for a given IP
      ##
      ## Example:
      ##
      ## .. code-block:: nim
      ##    showIpInfo("208.80.152.201")
      ##    showIpInfo(getHosts("bbc.com")[0])
      ##
      var jj:JsonNode = getIpInfo(ip)
      decho(2)
      printLn("Ip-Info for " & ip,lightsteelblue)
      dlineln(40,col = yellow)
      for x in jj.mpairs() :
          echo fmtx(["<15","",""],$x.key ," : " ,unquote($x.val))
      printLnBiCol(fmtx(["<15","",""],"Source"," : ","ip-api.com"),":",yellowgreen,salmon)




proc getHosts*(dm:string):seq[string] =
    ## getHosts
    ##
    ## returns IP addresses inside a seq[string] for a domain name and
    ##
    ## may resolve multiple IP pointing to same domain
    ##
    ## .. code-block:: Nim
    ##    import cx
    ##    var z = getHosts("bbc.co.uk")
    ##    for x in z:
    ##      echo x
    ##    doFinish()
    ##
    ##
    var rx = newSeq[string]()
    try:
      for i in getHostByName(dm).addrList:
        if i.len > 0:
          var s = ""
          var cc = 0
          for c in i:
              if s != "":
                  if cc == 3:
                    s.add(",")
                    cc = 0
                  else:
                    cc += 1
                    s.add('.')
              s.add($int(c))
          var ss = s.split(",")
          for x in 0.. <ss.len:
              rx.add(ss[x])

        else:
          rx = @[]
    except:
           rx = @[]
    var rxs = rx.toSet # removes doubles
    rx = @[]
    for x in rxs:
        rx.add(x)
    result = rx


proc showHosts*(dm:string) =
    ## showHosts
    ##
    ## displays IP addresses for a domain name and
    ##
    ## may resolve multiple IP pointing to same domain
    ##
    ## .. code-block:: Nim
    ##    import cx
    ##    showHosts("bbc.co.uk")
    ##    doFinish()
    ##
    ##
    cechoLn(yellowgreen,"Hosts Data for " & dm)
    var z = getHosts(dm)
    if z.len < 1:
         printLn("Nothing found or not resolved",red)
    else:
       for x in z:
         printLn(x)


proc reverseMe*[T](xs: openarray[T]): seq[T] =
  ## reverseMe
  ##
  ## reverse a sequence
  ##
  ## .. code-block:: nim
  ##
  ##    var z = @["nice","bad","abc","zztop","reverser"]
  ##    printLn(z,lime)
  ##    println(z.reverseMe,red)
  ##

  result = newSeq[T](xs.len)
  for i, x in xs:
    result[^i-1] = x # or: result[xs.high-i] = x

proc reverseText*(text:string):string = 
  ## reverseText
  ## 
  ## reverses words in a sentence
  ## 
  for line in text.splitLines: result = line.split(" ").reversed.join(" ")

proc reverseString*(text:string):string = 
  ## reverseString
  ## 
  ## reverses chars in a word   
  ## 
  ## 
  ## ..code-block:: nim
  ## 
  ##    var s = "A text to reverse could be this example 12345.0"
  ##    echo "Original      : " & s  
  ##    echo "reverseText   : " & reverseText(s)
  ##    echo "reverseString : " & reverseString(s)
  ##    # check if back to original is correct
  ##    assert s == reverseString(reverseString(s))
  ##    
   
  result = ""
  for x in reverseMe(text): result = result & x



# Convenience procs for random data creation and handling


# init the MersenneTwister
var rng* = initMersenneTwister(urandom(2500))


proc getRandomInt*(mi:int = 0,ma:int = int.high):int =
    ## getRandomInt
    ##
    ## convenience proc so we do not need to import random in calling prog
    ## 
    ## get positive or negative random ints by using the random sign mulitplier
    ##
    ## .. code-block:: nim 
    ##    echo  getRandomInt() * getRandomSignI()
    ##
    ##
    ## .. code-block:: nim
    ##    import cx,stats
    ##    var ps : Runningstat
    ##    loopy(0.. 1000000,ps.push(getRandomInt(0,10000)))
    ##    showStats(ps)
    ##    doFinish()
    ##
    ##

    # we do this to avoid overflow error if a int exceeding int.high is specified
    if ma >= int.high :
       result = rng.randomInt(mi,int.high)
    else:
       result = rng.randomInt(mi,ma + 1)


proc createSeqInt*(n:int = 10,mi:int = 0,ma:int = 1000) : seq[int] {.inline.} =
    ## createSeqInt
    ##
    ## convenience proc to create a seq of random int with
    ##
    ## default length 10
    ##
    ## gives @[4556,455,888,234,...] or similar
    ##
    ## .. code-block:: nim
    ##    # create a seq with 50 random integers ,of set 100 .. 2000
    ##    # including the limits 100 and 2000
    ##    echo createSeqInt(50,100,2000)

    result = newSeq[int]()
    case  mi <= ma
      of true :
                for x in 0.. <n: result.add(getRandomInt(mi,ma))
      of false: print("Error : Wrong parameters for min , max ",red)



proc sum*[T](aseq: seq[T]): T = foldl(aseq, a + b)
     ## sum
     ## code per idea from http://rnduja.github.io/2015/10/21/scientific-nim/
     ##
     ##
     ## returns sum of float or int seqs
     ## 
     ## same effect as math.sum
     ##


proc ff*(zz:float,n:int64 = 5):string =
     ## ff
     ##
     ## formats a float to string with n decimals
     ##
     result = $formatFloat(zz,ffDecimal,n)



proc ff2*(zz:float , n:int = 3):string =
  ## ff2
  ## 
  ## formats a float into form 12,345,678.234 that is thousands separators are shown
  ## 
  ## 
  ## precision is after comma given by n with default set to 3
  ## 
  ## .. code-block:: nim
  ##    import cx
  ##    
  ##    # floats example
  ##    for x in 1.. 2000:
  ##       # generate some positve and negative random float
  ##       var z = getrandomfloat() * 2345243.132310 * getRandomSignF()
  ##       printlnBiCol(fmtx(["",">6","",">20"],"NZ ",$x," : ",ff2(z)))
  ##  
  ##       
  
  var sc = 0
  var nz = ""
  var zok = ""
  var zrs = ""
  var zs = split($zz,".")
  var zrv = reverseme(zs[0])
 
  for x in 0 .. <zrv.len: 
     zrs = zrs & $zrv[x]
 
  for x in 0.. <zrs.len:
    if sc == 2:
        nz = "," & $zrs[x] & nz
        sc = 0
    else:
        nz = $zrs[x] & nz
        inc sc     
     
  for x in 0.. <zs[1].len:
    if x < n:
      zok = zok & zs[1][x]
  
  if n > 0:
        nz = nz & "." & zok
        
  if nz.startswith(",") == true:
     nz = strip(nz,true,false,{','})
  elif nz.startswith("-,") == true:
     nz = nz.replace("-,","-")
     
  result = nz


proc ff2*(zz:int , n:int = 0):string =
  ## ff2
  ## 
  ## formats a integer into form 12,345,678 that is thousands separators are shown
  ## 
  ## 
  ## precision is after comma given by n with default set to 3
  ## 
  ## .. code-block:: nim
  ##    import cx
  ##    
  ##    # int example
  ##    for x in 1.. 20:
  ##       # generate some positve and negative random integer
  ##       var z = getrandomInt(50000,100000000) * getRandomSignI()
  ##       printlnBiCol(fmtx(["",">6","",">20.0"],"NIM ",$x," : ",z))
  ##       
  ##       
  
  var sc = 0
  var nz = ""
  var zok = ""
  var zrs = ""
  var zs = split($zz,".")
  var zrv = reverseme(zs[0])
 
  for x in 0 .. <zrv.len: 
     zrs = zrs & $zrv[x]
 
  for x in 0.. <zrs.len:
    if sc == 2:
        nz = "," & $zrs[x] & nz
        sc = 0
    else:
        nz = $zrs[x] & nz
        inc sc     
     
  for x in 0.. <zs[1].len:
    if x < n:
      zok = zok & zs[1][x]
  
  if n > 0:
        nz = nz & "." & zok
        
  if nz.startswith(",") == true:
     nz = strip(nz,true,false,{','})
  elif nz.startswith("-,") == true:
     nz = nz.replace("-,","-")
     
  result = nz




proc getRandomFloat*():float =
     ## getRandomFloat
     ##
     ## convenience proc so we do not need to import random in calling prog
     ##
     ## to get positive or negative random floats multiply with getRandomSignF
     ## 
     ## Note: changed so to get positive and or negative floats
     ## 
     ## .. code-block:: nim
     ##    echo  getRandomFloat() * 10000.00 * getRandomSignF()
     ##
     result = rng.random()  


proc createSeqFloat*(n:BiggestInt = 10,prec:int = 3) : seq[float] =
     ## createSeqFloat
     ##
     ## convenience proc to create an unsorted seq of random floats with
     ##
     ## default length 10 ( always consider how much memory is in the system )
     ##
     ## prec enables after comma precision up to 16 positions after comma
     ##
     ## this is on a best attempt basis and may not work all the time
     ##
     ## default after comma positions is prec = 3 max
     ##
     ## form @[0.34,0.056,...] or similar
     ##
     ## .. code-block:: nim
     ##    # create a seq with 50 random floats
     ##    echo createSeqFloat(50)
     ##
     ##
     ## .. code-block:: nim
     ##    # create a seq with 50 random floats formated
     ##    echo createSeqFloat(50,3)
     ##
     var ffnz = prec
     if ffnz > 16: ffnz = 16
     var z = newSeq[float]()
     for x in 0.. <n:
          var af = ff(getRandomFloat(),ffnz)
          z.add(parseFloat(af))
     result = z




proc getRandomPointInCircle*(radius:float) : seq[float] =
    ## getRandomPointInCircle
    ##
    ## based on answers found in
    ##
    ## http://stackoverflow.com/questions/5837572/generate-a-random-point-within-a-circle-uniformly
    ##
    ##
    ##
    ## .. code-block:: nim
    ##    import cx,math,strfmt
    ##    # get randompoints in a circle
    ##    var crad:float = 1
    ##    for x in 0.. 100:
    ##       var k = getRandomPointInCircle(crad)
    ##       assert k[0] <= crad and k[1] <= crad
    ##       printLnBiCol(fmtx([">25","<6",">25"],$k[0]," :",$k[1])))
    ##    doFinish()
    ##
    ##

    let t = 2 * math.Pi * getRandomFloat()
    let u = getRandomFloat() + getRandomFloat()
    var r = 0.00
    if u > 1 :
      r = 2-u
    else:
      r = u
    var z = newSeq[float]()
    z.add(radius * r * math.cos(t))
    z.add(radius * r * math.sin(t))
    return z



proc getRandomPoint*(minx:float = -500.0,maxx:float = 500.0,miny:float = -500.0,maxy:float = 500.0) : RpointFloat =
    ## getRandomPoint
    ##
    ## generate a random x,y float point pair and return it as RpointFloat
    ## 
    ## minx  min x  value
    ## maxx  max x  value
    ## miny  min y  value
    ## maxy  max y  value
    ##
    ## .. code-block:: nim
    ##    for x in 0.. 10:
    ##    var n = getRandomPoint(-500.00,200.0,-100.0,300.00)
    ##    printLnBiCol(fmtx([">4",">5","",">6",">5"],"x:",$n.x,spaces(7),"y:",$n.y),spaces(7))
    ## 

    var point : RpointFloat
    var rx:    float
    var ry:    float
      
      
    if minx < 0.0:   rx = minx - 1.0 
    else        :    rx = minx + 1.0  
    if maxy < 0.0:   rx = maxx - 1.0 
    else        :    rx = maxx + 1.0 
        
    if miny < 0.0:   ry = miny - 1.0 
    else        :    ry = miny + 1.0  
    if maxy < 0.0:   ry = maxy - 1.0 
    else        :    ry = maxy + 1.0 
              
        
    var mpl = abs(maxx) * 1000     
    
    while rx < minx or rx > maxx:
       rx =  getRandomSignF() * mpl * getRandomFloat() 
       
       
    mpl = abs(maxy) * 1000   
    while ry < miny or ry > maxy:  
          ry =  getRandomSignF() * mpl * getRandomFloat()
        
    point.x = rx
    point.y = ry  
    result =  point
      
  
proc getRandomPoint*(minx:int = -500 ,maxx:int = 500 ,miny:int = -500 ,maxy:int = 500 ) : RpointInt =
    ## getRandomPoint 
    ##
    ## generate a random x,y int point pair and return it as RpointInt
    ## 
    ## min    x or y value
    ## max    x or y value
    ##
    ## .. code-block:: nim
    ##    for x in 0.. 10:
    ##    var n = getRandomPoint(-500,500,-500,200)
    ##    printLnBiCol(fmtx([">4",">5","",">6",">5"],"x:",$n.x,spaces(7),"y:",$n.y),spaces(7))
    ## 
  
    var point : RpointInt
        
    point.x =  getRandomSignI() * getRandomInt(minx,maxx) 
    point.y =  getRandomSignI() * getRandomInt(miny,maxy)
          
    result =  point



# Misc. routines

 

proc memCheck*(stats:bool = false) =
  ## memCheck
  ## 
  ## memCheck shows memory before and after a GC_FullCollect run
  ## 
  ## set stats to true for full GC_getStatistics
  ## 
  echo()
  printLn("MemCheck            ",yellowgreen,styled = {styleUnderscore},substr = "MemCheck            ")
  echo()
  println("Status    : Current ",salmon)
  println(yellowgreen & "Mem: " &  lightsteelblue & "Used : " & white & ff2(getOccupiedMem()) & lightsteelblue & "  Free : " & white & ff2(getFreeMem()) & lightsteelblue & "  Total : " & white & ff2(getTotalMem() ))
  if stats == true:
    echo GC_getStatistics()
  GC_fullCollect()
  println("Status    : GC_FullCollect executed",salmon)
  println(yellowgreen & "Mem: " &  lightsteelblue & "Used : " & white & ff2(getOccupiedMem()) & lightsteelblue & "  Free : " & white & ff2(getFreeMem()) & lightsteelblue & "  Total : " & white & ff2(getTotalMem() ))
  if stats == true:
     echo GC_getStatistics()
 


proc checkNimCi*(title:string) =
  ## checkNimCi
  ## 
  ## checks nim-ci for recent ok or failed nimble packages install test
  ## 
  ## use full title for exact output or partial title for all matches found.
  ## 
  ## 
  ## Note : needs compilation with -d:ssl  and result may not be up to date 
  ##        for reference only in case such a system is actually taken live.
  ##
  ## 
  ## .. code-block:: nim
  ##    checkNimCi("nimFinLib")  
  ##    
  
  
  var url = getcontent("https://136-60803270-gh.circle-artifacts.com/0/home/ubuntu/nim-ci/output/nimble_install_report.json")
  var z:JsonNode  = parseJson(url)
  println("\nResults for last nim-ci evaluation : \n",salmon)
  for x in z.items():
    if find(x["title"].getstr.toLower(),title.toLower()) != -1:  
        printLnBiCol("Title     : " & unquote($x["title"]),":",yellowgreen,skyblue)
        printLnBiCol("Url       : " & unquote($x["url"]))
        printLnBiCol("Version   : " &  unquote($x["version"]))
        if unquote($x["test_result"]) == "FAIL":
          printLnBiCol("TestResult: " & unquote($x["test_result"]),":",yellowgreen,red)
        else:
          printLnBiCol("TestResult: " & unquote($x["test_result"]),":",yellowgreen,brightyellow)
        echo()
   
 
template benchmark*(benchmarkName: string, code: typed) =
  ## benchmark
  ## 
  ## a quick benchmark template showing cpu and epoch times
  ## 
  ## .. code-block:: nim
  ##    benchmark("whatever"):
  ##      let z = 0.. 1000
  ##      loopy(z,printLn("Kami makan tiga kali setiap hari.",randcol()))
  ##
  ##
  ## .. code-block:: nim
  ##    proc doit() =
  ##      var s = createSeqFloat(10,3)
  ##      var c = 0
  ##      for x in sortMe(s):
  ##          inc c 
  ##          printLnBiCol(fmtx([">4","<6","<f2.4"],$c," :",$x))
  ##
  ##    benchmark("doit"):
  ##      for x in 0.. 100:
  ##          doit()
  ##
  ##    showBench() 
  ##    
  ##    
  
  var zbres:Benchmarkres
  let t0 = epochTime()
  let t1 = cpuTime()
  code
  let elapsed  = epochTime() - t0
  let elapsed1 = cpuTime()   - t1
  zbres.epoch  = ff(elapsed,4)  
  zbres.cpu = ff(elapsed1,4) 
  zbres.bname = benchmarkName
  benchmarkresults.add(zbres)



proc showBench*() =
 ## showBench
 ## 
 ## Displays results of all benchmarks
 ## 
 if benchmarkresults.len > 0: 
    for x in  benchmarkresults:
      echo()
      var tit = " BenchMark        Timing " & spaces(25)
      printLn(tit,chartreuse,styled = {styleUnderScore},substr = tit)
      println(dodgerblue & " [" & salmon & x.bname & dodgerblue & "]" & spaces(7) & cornflowerblue & "Epoch Time : " & white & x.epoch & " secs")
      println(dodgerblue & " [" & salmon & x.bname & dodgerblue & "]" & spaces(7) & cornflowerblue & "Cpu   Time : " & white & x.cpu & " secs")    
    echo()
    benchmarkresults = @[]
    println("Benchmark results end. Results cleared.",goldenrod)
 else:
    printLn("Benchmark results emtpy.Nothing to show",red)   




proc sortMe*[T](xs:var seq[T],order = Ascending): seq[T] =
     ## sortMe
     ##
     ## sorts seqs of int,float,string and returns a sorted seq
     ##
     ## with order Ascending or Descending
     ##
     ## .. code-block:: nim
     ##    var z = createSeqFloat()
     ##    println(sortMe(z),salmon)
     ##    println(sortMe(z,Descending),peru)
     ##
     ##
     xs.sort(proc(x,y:T):int = cmp(x,y),order = order)
     result = xs

template getCard* :auto =
    ## getCard
    ##
    ## gets a random card from the Cards seq
    ##
    ## .. code-block:: nim
    ##    import cx
    ##    print(getCard(),randCol(),xpos = centerX())  # get card and print in random color at xpos
    ##    doFinish()
    ##
    cards[rxCards.randomChoice()]



proc ruler* (xpos:int=0,xposE:int=0,ypos:int = 0,fgr:string = termwhite,bgr:string = termblack , vert:bool = false) =
     ## ruler
     ##
     ## simple terminal ruler indicating dot x positions to give a feedback
     ##
     ## available for horizontal --> vert = false
     ##           for vertical   --> vert = true
     ##
     ## see cxDemo and cxTest for more usage examples
     ##
     ## .. code-block::nim
     ##   # this will show a full terminal width ruler
     ##   ruler(fgr=pastelblue)
     ##   decho(3)
     ##   # this will show a specified position only
     ##   ruler(xpos =22,xposE = 55,fgr=pastelgreen)
     ##   decho(3)
     ##   # this will show a full terminal width ruler starting at a certain position
     ##   ruler(xpos = 75,fgr=pastelblue)
     echo()
     var fflag:bool = false
     var npos  = xpos
     var nposE = xposE
     if xpos ==  0: npos  = 1
     if xposE == 0: nposE = tw - 1

     if vert == false :  # horizontalruler

          for x in npos.. nposE:

            if x == 1:
                curup(1)
                print(".",lime,bgr,xpos = 1)
                curdn(1)
                print(x,fgr,bgr,xpos = 1)
                curup(1)
                fflag = true

            elif x mod 5 > 0 and fflag == false:
                curup(1)
                print(".",goldenrod,bgr,xpos = x)
                curdn(1)

            elif x mod 5 == 0:
                if fflag == false:
                  curup(1)
                print(".",lime,bgr,xpos = x)
                curdn(1)
                print(x,fgr,bgr,xpos = x)
                curup(1)
                fflag = true

            else:
                fflag = true
                print(".",truetomato,bgr,xpos = x)


     else : # vertical ruler

            if  ypos >= th : curset()
            else: curup(ypos + 2)

            for x in 0.. ypos:
                  if x == 0: println(".",lime,bgr,xpos = xpos + 3)
                  elif x mod 2 == 0:
                         print(x,fgr,bgr,xpos = xpos)
                         println(".",fgr,bgr,xpos = xpos + 3)
                  else: println(".",truetomato,bgr,xpos = xpos + 3)
     decho(3)



proc centerMark*(showpos :bool = false) =
     ## centerMark
     ##
     ## draws a red dot in the middle of the screen xpos only
     ## and also can show pos
     ##
     centerPos(".")
     print(".",truetomato)
     if showpos == true:  print "x" & $(tw/2)


proc tupleToStr*(xs: tuple): string =
     ## tupleToStr
     ##
     ## tuple to string unpacker , returns a string
     ##
     ## code ex nim forum
     ##
     ## .. code-block:: nim
     ##    echo tupleToStr((1,2))         # prints (1, 2)
     ##    echo tupleToStr((3,4))         # prints (3, 4)
     ##    echo tupleToStr(("A","B","C")) # prints (A, B, C)

     result = "("
     for x in xs.fields:
       if result.len > 1:
           result.add(", ")
       result.add($x)
     result.add(")")





template withFile*(f:untyped,filename: string, mode: FileMode, body: untyped): typed =
     ## withFile
     ##
     ## file open close utility template
     ##
     ## Example 1
     ##
     ## .. code-block:: nim
     ##   let curFile="/data5/notes.txt"    # some file
     ##   withFile(txt, curFile, fmRead):
     ##       while true:
     ##          try:
     ##             printLn(txt.readLine())   # do something with the lines
     ##          except:
     ##             break
     ##   echo()
     ##   printLn("Finished",clRainbow)
     ##   doFinish()
     ##
     ##
     ## Example 2
     ##
     ## .. code-block:: nim
     ##    import cx,strutils,strfmt
     ##
     ##    let curFile="/data5/notes.txt"
     ##    var lc = 0
     ##    var oc = 0
     ##    withFile(txt, curFile, fmRead):
     ##           while 1 == 1:
     ##               try:
     ##                  inc lc
     ##                  var al = $txt.readline()
     ##                  var sw = "the"   # find all lines containing : the
     ##                  if al.contains(sw) == true:
     ##                     inc oc
     ##                     msgy() do: write(stdout,"{:<8}{:>6} {:<7}{:>6}  ".fmt("Line :",lc,"Count :",oc))
     ##                     printhl(al,sw,green)
     ##                     echo()
     ##               except:
     ##                  break
     ##
     ##    echo()
     ##    printLn("Finished",clRainbow)
     ##    doFinish()
     ##

     let fn = filename
     var f: File

     if open(f, fn, mode):
         try:
             body
         finally:
             close(f)
     else:
         echo()
         printLnBiCol("Error : Cannot open file " & filename,":",red,yellow)
         quit()



template loopy*[T](ite:T,st:typed) =
     ## loopy
     ##
     ## the lazy programmer's quick simple for-loop template
     ##
     ## .. code-block:: nim
     ##       loopy(0.. 10,printLn("The house is in the back.",randcol()))
     ##
     for x in ite: st



proc shift*[T](x: var seq[T], zz: Natural = 0): T =
     ## shift takes a seq and returns the first , and deletes it from the seq
     ##
     ## build in pop does the same from the other side
     ##
     ## .. code-block:: nim
     ##    var a: seq[float] = @[1.5, 23.3, 3.4]
     ##    echo shift(a)
     ##    echo a
     ##
     ##
     result = x[zz]
     x.delete(zz)


proc nonzero(c: string, n: int, connect=""): string =
  # used by spellInteger
  if n == 0: "" else: connect & c & spellInteger(n)
 
proc lastAnd[T](num:T): string =
  # used by spellInteger
  var num = num
  if "," in num:
    let pos =  num.rfind(",")
    var (pre, last) =
      if pos >= 0: (num[0 .. pos-1], num[pos+1 .. num.high])
      else: ("", num)
    if " and " notin last:
      last = " and" & last
    num = [pre, ",", last].join()
  return num
 
proc big(e:int, n:int): string =
  # used by spellInteger
  if e == 0:
    spellInteger(n)
  elif e == 1:
    spellInteger(n) & " thousand"
  else:
    spellInteger(n) & " " & huge[e]
 
iterator base1000Rev(n:int64): int =
  # used by spellInteger 
  var n = n
  while n != 0:
    let r = n mod 1000
    n = n div 1000
    yield r
 
proc spellInteger*(n: int64): string =
  ## spellInteger
  ## 
  ## code adapted from rosettacode and slightly updated to make it actually compile
  ## 

  if n < 0:
    "minus " & spellInteger(-n)
  elif n < 20:
    small[int(n)]
  elif n < 100:
    let a = n div 10
    let b = n mod 10
    tens[int(a)] & nonzero(" ", b)
  elif n < 1000:
    let a = n div 100
    let b = n mod 100
    small[int(a)] & " hundred" & nonzero(" ", b, "")
  else:
    var sq = newSeq[string]()
    var e = 0
    for x in base1000Rev(n):
      if x > 0:
        sq.add big(e, x)
      inc e
    reverse sq
    lastAnd(sq.join(" "))
 

 
proc spellFloat*(n:float64,sep:string = ".",sepname:string = " dot "):string = 
  ## spellFloat
  ## 
  ## writes out a float number in english 
  ## sep and sepname can be adjusted as needed
  ## default sep = "."
  ## default sepname = " dot "
  ## 
  ## .. code-block:: nim
  ##  println spellFloat(0.00)
  ##  println spellFloat(234)
  ##  println spellFloat(-2311.345)
  ## 
  var ok = ""
  if n == 0.00:
      ok = spellInteger(0)
  else:
      #split it into two integer parts
      var nss = split($n,".")
      if nss[0].len == 0:  nss[0] = $0
      if nss[1].len == 0:  nss[1] = $0
      ok = spellInteger(parseInt(nss[0])) & sepname &  spellInteger(parseInt(nss[1]))
       
  result = ok   
    

proc showStats*(x:Runningstat,n:int = 3) =
     ## showStats
     ##
     ## quickly display runningStat data
     ## 
     ## adjust decimals
     ##
     ## .. code-block:: nim
     ##
     ##    import cx,stats
     ##    var rs:Runningstat
     ##    var z =  createSeqFloat(500000)
     ##    for x in z:
     ##        rs.push(x)
     ##    showStats(rs)
     ##    doFinish()
     ##
     var sep = ":"
     printLnBiCol("Sum     : " & ff(x.sum,n),sep,yellowgreen,white)
     printLnBiCol("Mean    : " & ff(x.mean,n),sep,yellowgreen,white)
     printLnBiCol("Var     : " & ff(x.variance,n),sep,yellowgreen,white)
     printLnBiCol("Var  S  : " & ff(x.varianceS,n),sep,yellowgreen,white)
     printLnBiCol("Kurt    : " & ff(x.kurtosis,n),sep,yellowgreen,white)
     printLnBiCol("Kurt S  : " & ff(x.kurtosisS,n),sep,yellowgreen,white)
     printLnBiCol("Skew    : " & ff(x.skewness,n),sep,yellowgreen,white)
     printLnBiCol("Skew S  : " & ff(x.skewnessS,n),sep,yellowgreen,white)
     printLnBiCol("Std     : " & ff(x.standardDeviation,n),sep,yellowgreen,white)
     printLnBiCol("Std  S  : " & ff(x.standardDeviationS,n),sep,yellowgreen,white)
     printLnBiCol("Min     : " & ff(x.min,n),sep,yellowgreen,white)
     printLnBiCol("Max     : " & ff(x.max,n),sep,yellowgreen,white)
     println("S --> sample",peru)

proc showRegression*(x, y: openArray[float | int]) =
     ## showRegression
     ##
     ## quickly display RunningRegress data based on input of two openarray data series
     ## 
     ## .. code-block:: nim
     ##    import cx
     ##    var a = @[1,2,3,4,5] 
     ##    var b = @[1,2,3,4,7] 
     ##    showRegression(a,b)
     ##
     ##
     var sep = ":"
     var rr :RunningRegress
     rr.push(x,y)
     printLnBiCol("Intercept     : " & ff(rr.intercept()),sep,yellowgreen,white)
     printLnBiCol("Slope         : " & ff(rr.slope()),sep,yellowgreen,white)
     printLnBiCol("Correlation   : " & ff(rr.correlation()),sep,yellowgreen,white)
    

proc showRegression*(rr: RunningRegress) =
     ## showRegression
     ##
     ## Displays RunningRegress data from an already formed RunningRegress
     ## 
  
     var sep = ":"
          
     printLnBiCol("Intercept     : " & ff(rr.intercept()),sep,yellowgreen,white)
     printLnBiCol("Slope         : " & ff(rr.slope()),sep,yellowgreen,white)
     printLnBiCol("Correlation   : " & ff(rr.correlation()),sep,yellowgreen,white)
    


proc newDir*(dirname:string) =
     ## newDir
     ##
     ## creates a new directory and provides some feedback

     if not existsDir(dirname):
          try:
            createDir(dirname)
            printLn("Directory " & dirname & " created ok",green)
          except OSError:
            printLn(dirname & " creation failed. Check permissions.",red)
     else:
        printLn("Directory " & dirname & " already exists !",red)



proc remDir*(dirname:string) =
     ## remDir
     ##
     ## deletes an existing directory , all subdirectories and files  and provides some feedback
     ##
     ## root and home directory removal is disallowed
     ##

     if dirname == "/home" or dirname == "/" :
        printLn("Directory " & dirname & " removal not allowed !",brightred)

     else:

        if existsDir(dirname):

            try:
                removeDir(dirname)
                printLn("Directory " & dirname & " deleted ok",yellowgreen)
            except OSError:
                printLn("Directory " & dirname & " deletion failed",red)
        else:
            printLn("Directory " & dirname & " does not exists !",red)



proc dayOfYear*() : range[0..365] = getLocalTime(getTime()).yearday + 1
    ## dayOfYear
    ##
    ## returns the day of the year for a given Time
    ##
    ## note Nim yearday starts with Jan 1 being 0 however many application
    ##
    ## actually need to start on day 1 being actually 1 , which is provided here.
    ##
    ## .. code-block:: nim
    ##     var afile = "cx.nim"
    ##     var mday = getLastModificationTime(afile).dayofyear
    ##     var today = dayofyear
    ##     printlnBiCol("Last Modified on day  : " & $mday)
    ##     printLnBiCol("Day of Current year   : " & $today)
    ##
    ##



proc dayOfYear*(tt:Time) : range[0..365] = getLocalTime(tt).yearday + 1
    ## dayOfYear
    ##
    ## returns the day of the year for a given Time
    ##
    ## note Nim yearday starts with Jan 1 being 0 however many application
    ##
    ## actually need to start on day 1 being actually 1 , which is provided here.
    ##
    ## .. code-block:: nim
    ##     var afile = "cx.nim"
    ##     var mday  = getLastModificationTime(afile).dayofyear
    ##     var today = dayofyear
    ##     printlnBiCol("Last Modified on day  : " & $mday)
    ##     printLnBiCol("Day of Current year   : " & $today)
    ##
    ##


proc doNimUp*(xpos = 5, rev:bool = true) = 
      ## doNimUp
      ## 
      ## A Nim dumbs up logo 
      ## 
      ## 
      cleanScreen()
      decho(2)
      if rev == true:
          
          println("        $$$$               ".reversed,randcol(),xpos = xpos)
          println("       $$  $               ".reversed,randcol(),xpos = xpos)
          println("       $   $$              ".reversed,randcol(),xpos = xpos)
          println("       $   $$              ".reversed,randcol(),xpos = xpos)
          println("       $$   $$             ".reversed,randcol(),xpos = xpos)
          println("        $    $$            ".reversed,randcol(),xpos = xpos)
          println("        $$    $$$          ".reversed,randcol(),xpos = xpos)
          println("         $$     $$         ".reversed,randcol(),xpos = xpos)
          println("         $$      $$        ".reversed,randcol(),xpos = xpos)
          println("          $       $$       ".reversed,randcol(),xpos = xpos)
          println("    $$$$$$$        $$      ".reversed,randcol(),xpos = xpos)
          println("  $$$               $$$$$  ".reversed,randcol(),xpos = xpos)
          println(" $$    $$$$            $$$ ".reversed,randcol(),xpos = xpos)
          println(" $   $$$  $$$            $$".reversed,randcol(),xpos = xpos)
          println(" $$        $$$            $".reversed,randcol(),xpos = xpos)
          println("  $$    $$$$$$            $".reversed,randcol(),xpos = xpos)
          println("  $$$$$$$    $$           $".reversed,randcol(),xpos = xpos)
          println("  $$       $$$$           $".reversed,randcol(),xpos = xpos)
          println("   $$$$$$$$$  $$         $$".reversed,randcol(),xpos = xpos)
          println("    $        $$$$     $$$$ ".reversed,randcol(),xpos = xpos)
          println("    $$    $$$$$$    $$$$$$ ".reversed,randcol(),xpos = xpos)
          println("     $$$$$$    $$  $$      ".reversed,randcol(),xpos = xpos)
          println("       $     $$$ $$$       ".reversed,randcol(),xpos = xpos)
          println("        $$$$$$$$$$         ".reversed,randcol(),xpos = xpos)

      else:
        
          println("        $$$$               ",randcol(),xpos=60)
          println("       $$  $               ",randcol(),xpos=60)
          println("       $   $$              ",randcol(),xpos=60)
          println("       $   $$              ",randcol(),xpos=60)
          println("       $$   $$             ",randcol(),xpos=60)
          println("        $    $$            ",randcol(),xpos=60)
          println("        $$    $$$          ",randcol(),xpos=60)
          println("         $$     $$         ",randcol(),xpos=60)
          println("         $$      $$        ",randcol(),xpos=60)
          println("          $       $$       ",randcol(),xpos=60)
          println("    $$$$$$$        $$      ",randcol(),xpos=60)
          println("  $$$               $$$$$  ",randcol(),xpos=60)
          println(" $$    $$$$            $$$ ",randcol(),xpos=60)
          println(" $   $$$  $$$            $$",randcol(),xpos=60)
          println(" $$        $$$            $",randcol(),xpos=60)
          println("  $$    $$$$$$            $",randcol(),xpos=60)
          println("  $$$$$$$    $$           $",randcol(),xpos=60)
          println("  $$       $$$$           $",randcol(),xpos=60)
          println("   $$$$$$$$$  $$         $$",randcol(),xpos=60)
          println("    $        $$$$     $$$$ ",randcol(),xpos=60)
          println("    $$    $$$$$$    $$$$$$ ",randcol(),xpos=60)
          println("     $$$$$$    $$  $$      ",randcol(),xpos=60)
          println("       $     $$$ $$$       ",randcol(),xpos=60)
          println("        $$$$$$$$$$         ",randcol(),xpos=60)

      curup(15)
      printBigLetters("NIM",fgr=randcol(),xpos = xpos + 33)
      curdn(15)


 
  
proc checkClip*(sel:string = "primary"):string  = 
     ## checkClip
     ## 
     ## returns the newest entry from the Clipboard
     ## needs linux utility xclip installed
     ## 
     ## .. code-block:: nim
     ##     printLnBiCol("Last Clipboard Entry : " & checkClip())
     ##
          
     let (outp, errC) = execCmdEx("xclip -selection $1 -quiet -silent -o" % $sel)
     var rx = ""
     if errC == 0:
         let r = split($outp," ")
         for x in 0.. <r.len:
             rx = rx & " " & r[x]
     else:
         rx = "xclip returned errorcode : " & $errC & ". Clipboard not accessed correctly"

     result = rx
       

# Unicode random word creators

proc newWordCJK*(minwl:int = 3 ,maxwl:int = 10):string =
      ## newWordCJK
      ##
      ## creates a new random string consisting of n chars default = max 10
      ##
      ## with chars from the cjk unicode set
      ##
      ## http://unicode-table.com/en/#cjk-unified-ideographs
      ##
      ## requires unicode
      ##
      ## .. code-block:: nim
      ##    # create a string of chinese or CJK chars
      ##    # with max length 20 and show it in green
      ##    msgg() do : echo newWordCJK(20,20)
      # set the char set
      let chc = toSeq(parsehexint("3400").. parsehexint("4DB5"))
      var nw = ""
      # words with length range 3 to maxwl
      let maxws = toSeq(minwl.. maxwl)
      # get a random length for a new word choosen from between 3 and maxwl
      let nwl = maxws.randomChoice()
      for x in 0.. <nwl:
            nw = nw & $Rune(chc.randomChoice())
      result = nw



proc newWord*(minwl:int=3,maxwl:int = 10 ):string =
    ## newWord
    ##
    ## creates a new lower case random word with chars from Letters set
    ##
    ## default min word length minwl = 3
    ##
    ## default max word length maxwl = 10
    ##

    if minwl <= maxwl:
        var nw = ""
        # words with length range 3 to maxwl
        let maxws = toSeq(minwl.. maxwl)
        # get a random length for a new word
        let nwl = maxws.randomChoice()
        let chc = toSeq(33.. 126)
        while nw.len < nwl:
          var x = chc.randomChoice()
          if char(x) in Letters:
              nw = nw & $char(x)
        result = normalize(nw)   # return in lower case , cleaned up

    else:
         cechoLn(red,"Error : minimum word length larger than maximum word length")
         result = ""



proc newWord2*(minwl:int=3,maxwl:int = 10 ):string =
    ## newWord2
    ##
    ## creates a new lower case random word with chars from IdentChars set
    ##
    ## default min word length minwl = 3
    ##
    ## default max word length maxwl = 10
    ##
    if minwl <= maxwl:
        var nw = ""
        # words with length range 3 to maxwl
        let maxws = toSeq(minwl.. maxwl)
        # get a random length for a new word
        let nwl = maxws.randomChoice()
        let chc = toSeq(33.. 126)
        while nw.len < nwl:
          var x = chc.randomChoice()
          if char(x) in IdentChars:
              nw = nw & $char(x)
        result = normalize(nw)   # return in lower case , cleaned up

    else:
         cechoLn(red,"Error : minimum word length larger than maximum word length")
         result = ""


proc newWord3*(minwl:int=3,maxwl:int = 10 ,nflag:bool = true):string =
    ## newWord3
    ##
    ## creates a new lower case random word with chars from AllChars set if nflag = true
    ##
    ## creates a new anycase word with chars from AllChars set if nflag = false
    ##
    ## default min word length minwl = 3
    ##
    ## default max word length maxwl = 10
    ##
    if minwl <= maxwl:
        var nw = ""
        # words with length range 3 to maxwl
        let maxws = toSeq(minwl.. maxwl)
        # get a random length for a new word
        let nwl = maxws.randomChoice()
        let chc = toSeq(33.. 126)
        while nw.len < nwl:
          var x = chc.randomChoice()
          if char(x) in AllChars:
              nw = nw & $char(x)
        if nflag == true:
           result = normalize(nw)   # return in lower case , cleaned up
        else :
           result = nw

    else:
         cechoLn(red,"Error : minimum word length larger than maximum word length")
         result = ""


proc newHiragana*(minwl:int=3,maxwl:int = 10 ):string =
    ## newHiragana
    ##
    ## creates a random hiragana word without meaning from the hiragana unicode set
    ##
    ## default min word length minwl = 3
    ##
    ## default max word length maxwl = 10
    ##
    if minwl <= maxwl:
        var nw = ""
        # words with length range 3 to maxwl
        let maxws = toSeq(minwl.. maxwl)
        # get a random length for a new word
        let nwl = maxws.randomChoice()
        let chc = toSeq(12353.. 12436)
        while nw.len < nwl:
           var x = chc.randomChoice()
           nw = nw & $Rune(x)

        result = nw

    else:
         cechoLn(red,"Error : minimum word length larger than maximum word length")
         result = ""



proc newKatakana*(minwl:int=3,maxwl:int = 10 ):string =
    ## newKatakana
    ##
    ## creates a random katakana word without meaning from the katakana unicode set
    ##
    ## default min word length minwl = 3
    ##
    ## default max word length maxwl = 10
    ##
    if minwl <= maxwl:
        var nw = ""
        # words with length range 3 to maxwl
        let maxws = toSeq(minwl.. maxwl)
        # get a random length for a new word
        let nwl = maxws.randomChoice()
        let chc = toSeq(parsehexint("30A0") .. parsehexint("30FF"))
        while nw.len < nwl:
           var x = chc.randomChoice()
           nw = nw & $Rune(x)

        result = nw

    else:
         cechoLn(red,"Error : minimum word length larger than maximum word length")
         result = ""



proc iching*():seq[string] =
    ## iching
    ##
    ## returns a seq containing iching unicode chars
    var ich = newSeq[string]()
    for j in 119552..119638:
           ich.add($Rune(j))
    result = ich



proc apl*():seq[string] =
    ## apl
    ##
    ## returns a seq containing apl language symbols
    ##
    var adx = newSeq[string]()
    # s U+30A0–U+30FF.
    for j in parsehexint("2300") .. parsehexint("23FF"):
        adx.add($Rune(j))
    result = adx



proc hiragana*():seq[string] =
    ## hiragana
    ##
    ## returns a seq containing hiragana unicode chars
    var hir = newSeq[string]()
    # 12353..12436 hiragana
    for j in 12353..12436:
           hir.add($Rune(j))
    result = hir


proc katakana*():seq[string] =
    ## full width katakana
    ##
    ## returns a seq containing full width katakana unicode chars
    ##
    var kat = newSeq[string]()
    # s U+30A0–U+30FF.
    for j in parsehexint("30A0") .. parsehexint("30FF"):
        kat.add($RUne(j))
    result = kat



proc rainbow2*[T](s : T,xpos:int = 0,fitLine:bool = false,centered:bool = false, colorset:seq[(string, string)] = colorNames) =
    ## rainbow2
    ##
    ## multicolored string  based on colorsets  see pastelSet
    ##
    ## may not work with certain Rune
    ##
    ## .. code-block:: nim
    ##    rainbow2("what's up ?\n",centered = true,colorset = pastelSet)
    ##
    ##
    ##
    var nxpos = xpos
    var astr = $s
    var c = 0
    var a = toSeq(1.. <colorset.len)

    if astr in emojis or astr in hiragana() or astr in katakana() or astr in iching():
        c = a[randomInt(a.len)]
        if centered == false:
            print(astr,colorset[c][1],black,xpos = nxpos,fitLine)

        else:
              # need to calc the center here and increment by x
              nxpos = centerX() - ($astr).len div 2  - 1
              print(astr,colorset[c][1],black,xpos=nxpos,fitLine)

        inc nxpos


    else :

          for x in 0.. <astr.len:
            c = a[randomInt(a.len)]
            if centered == false:
                print(astr[x],colorset[c][1],black,xpos = nxpos,fitLine)

            else:
                # need to calc the center here and increment by x
                nxpos = centerX() - ($astr).len div 2  + x - 1
                print(astr[x],colorset[c][1],black,xpos=nxpos,fitLine)

            inc nxpos



proc boxChars*():seq[string] =

    ## chars to draw a box
    ##
    ## returns a seq containing unicode box drawing chars
    ##
    var boxy = newSeq[string]()
    # s U+2500–U+257F.
    for j in parsehexint("2500") .. parsehexint("257F"):
        boxy.add($RUne(j))
    result = boxy



proc drawBox*(hy:int = 1, wx:int = 1 , hsec:int = 1 ,vsec:int = 1,frCol:string = yellowgreen,brCol:string = black ,cornerCol:string = truetomato,xpos:int = 1,blink:bool = false) =
     ## drawBox
     ##
     ## WORK IN PROGRESS FOR A BOX DRAWING PROC USING UNICODE BOX CHARS
     ##
     ## Note you must make sure that the terminal is large enough to display the
     ##
     ##      box or it will look messed up
     ##
     ##
     ## .. code-block:: nim
     ##    import cx,unicode
     ##    cleanscreen()
     ##    decho(5)
     ##    drawBox(hy=10, wx= 60 , hsec = 5 ,vsec = 5,frCol = randcol(),brCol= black ,cornerCol = truetomato,xpos = 1,blink = false)
     ##    curmove(up=2,bk=11)
     ##    print(widedot & "NIM " & widedot,yellowgreen)
     ##    decho(5)
     ##    showTerminalSize()
     ##    doFinish()
     ##
     ##
     # http://unicode.org/charts/PDF/U2500.pdf
     # almost ok we need to find a way to to make sure that grid size is fine
     # if we use dynamic sizes like width = tw - 1 etc.
     #
     # given some data should the data be printed into a drawn box
     # or the box around the data ?
     #

     var h = hy
     var w = wx
     if h > th:
       h = th
     if w > tw:
       w = tw

     curSetx(xpos)
     # top
     if blink == true:
       
           print($Rune(parsehexint("250C")),cornerCol,styled = {styleBlink},substr = $Rune(parsehexint("250C")))
     else:
           print($Rune(parsehexint("250C")),cornerCol,styled = {},substr = $Rune(parsehexint("250C")))

     print(repeat($Rune(parseHexInt("2500")),w - 1) ,fgr = frcol)

     if blink == true:
           printLn($Rune(parsehexint("2510")),cornerCol,styled = {styleBlink},substr = $Rune(parsehexint("2510")))
     else:
           printLn($Rune(parsehexint("2510")),cornerCol,styled = {} ,substr = $Rune(parsehexint("2510")))


     #sides
     for x in 0.. h - 2 :
           print($Rune(parsehexint("2502")),fgr = frcol,xpos=xpos)
           printLn($Rune(parsehexint("2502")),fgr = frcol,xpos=xpos + w )


     # bottom left corner and bottom right
     print($Rune(parsehexint("2514")),fgr = cornercol,xpos=xpos)
     print(repeat($Rune(parsehexint("2500")),w-1),fgr = frcol)
     printLn($Rune(parsehexint("2518")),fgr=cornercol)

     # try to build some dividers
     var vsecwidth = w
     if vsec > 1:
       vsecwidth = w div vsec
       curup(h + 1)
       for x in 1.. <vsec:
           print($Rune(parsehexint("252C")),fgr = truetomato,xpos=xpos + vsecwidth * x)
           curdn(1)
           for y in 0.. h - 2 :
               printLn($Rune(parsehexint("2502")),fgr = frcol,xpos=xpos + vsecwidth * x)
           print($Rune(parsehexint("2534")),fgr = truetomato,xpos=xpos + vsecwidth * x)
           curup(h)

     var hsecheight = h
     var hpos = xpos
     var npos = hpos
     if hsec > 1:
       hsecheight = h div hsec
       cursetx(hpos)
       curdn(hsecheight)

       for x in 1.. <hsec:
           print($Rune(parsehexint("251C")),fgr = truetomato,xpos=hpos)
           #print a full line right thru the vlines
           print(repeat($Rune(parsehexint("2500")),w - 1),fgr = frcol)
           # now we add the cross points
           for x in 1.. <vsec:
               npos = npos + vsecwidth
               cursetx(npos)
               print($Rune(parsehexint("253C")),fgr = truetomato)
           # print the right edge
           npos = npos + vsecwidth + 1
           print($Rune(parsehexint("2524")),fgr = truetomato,xpos=npos - 1)
           curdn(hsecheight)
           npos = hpos




proc randpos*():int =
    ## randpos
    ##
    ## sets cursor to a random position in the visible terminal window
    ##
    ## returns x position
    ##
    ## .. code-block:: nim
    ##
    ##    while 1 == 1:
    ##       for z in 1.. 50:
    ##          print($z,randcol(),xpos = randpos())
    ##       sleepy(0.0015)
    ##
    curset()
    let x = getRandomInt(0, tw - 1)
    let y = getRandomInt(0, th - 1)
    curdn(y)
    #print($x & "/" & $y,xpos = x)
    result = x



# string splitters with additional capabilities to original split()

proc fastsplit*(s: string, sep: char): seq[string] =
  ## fastsplit
  ##
  ## code by jehan lifted from Nim Forum
  ##
  ## maybe best results compile prog with : nim cc -d:release --gc:markandsweep
  ##
  ## seperator must be a char type
  ##
  var count = 1
  for ch in s:
    if ch == sep:
      count += 1
  result = newSeq[string](count)
  var fieldNum = 0
  var start = 0
  for i in 0..high(s):
    if s[i] == sep:
      result[fieldNum] = s[start.. i - 1]
      start = i + 1
      fieldNum += 1
  result[fieldNum] = s[start..^1]



proc splitty*(txt:string,sep:string):seq[string] =
   ## splitty
   ##
   ## same as build in split function but this retains the
   ##
   ## separator on the left side of the split
   ##
   ## z = splitty("Nice weather in : Djibouti",":")
   ##
   ## will yield:
   ##
   ## Nice weather in :
   ## Djibouti
   ##
   ## rather than:
   ##
   ## Nice weather in
   ## Djibouti
   ##
   ## with the original split()
   ##
   ##
   var rx = newSeq[string]()
   let z = txt.split(sep)
   for xx in 0.. <z.len:
     if z[xx] != txt and z[xx] != nil:
        if xx < z.len-1:
             rx.add(z[xx] & sep)
        else:
             rx.add(z[xx])
   result = rx


proc showTerminalSize*() =
      ## showTerminalSize
      ##
      ## displays current terminal dimensions
      ##
      ## width is always available via tw
      ##
      ## height is always available via th
      ##
      ##
      cechoLn(yellowgreen,"Terminal : " & lime & " W " & white & $tw & red & " x" & lime & " H " & white & $th)


# Info and handlers procs for quick information


proc qqTop*() =
  ## qqTop
  ##
  ## prints qqTop in custom color
  ##
  print("qq",cyan)
  print("T",brightgreen)
  print("o",brightred)
  print("p",cyan)


proc doInfo*() =
  ## doInfo
  ##
  ## A more than you want to know information proc
  ##
  ##
  let filename= extractFileName(getAppFilename())
  #var accTime = getLastAccessTime(filename)
  let modTime = getLastModificationTime(filename)
  let sep = ":"
  superHeader("Information for file " & filename & " and System      ")
  printLnBiCol("Last compilation on           : " & CompileDate &  " at " & CompileTime,sep,yellowgreen,lightgrey)
  # this only makes sense for non executable files
  #printLnBiCol("Last access time to file      : " & filename & " " & $(fromSeconds(int(getLastAccessTime(filename)))),sep,yellowgreen,lightgrey)
  printLnBiCol("Last modificaton time of file : " & filename & " " & $(fromSeconds(int(modTime))),sep,yellowgreen,lightgrey)
  printLnBiCol("Local TimeZone                : " & $(getTzName()),sep,yellowgreen,lightgrey)
  printLnBiCol("Offset from UTC  in secs      : " & $(getTimeZone()),sep,yellowgreen,lightgrey)
  printLnBiCol("Now                           : " & getDateStr() & " " & getClockStr(),sep,yellowgreen,lightgrey)
  printLnBiCol("Local Time                    : " & $getLocalTime(getTime()),sep,yellowgreen,lightgrey)
  printLnBiCol("GMT                           : " & $getGMTime(getTime()),sep,yellowgreen,lightgrey)
  printLnBiCol("Environment Info              : " & getEnv("HOME"),sep,yellowgreen,lightgrey)
  printLnBiCol("File exists                   : " & $(existsFile filename),sep,yellowgreen,lightgrey)
  printLnBiCol("Dir exists                    : " & $(existsDir "/"),sep,yellowgreen,lightgrey)
  printLnBiCol("AppDir                        : " & getAppDir(),sep,yellowgreen,lightgrey)
  printLnBiCol("App File Name                 : " & getAppFilename(),sep,yellowgreen,lightgrey)
  printLnBiCol("User home  dir                : " & getHomeDir(),sep,yellowgreen,lightgrey)
  printLnBiCol("Config Dir                    : " & getConfigDir(),sep,yellowgreen,lightgrey)
  printLnBiCol("Current Dir                   : " & getCurrentDir(),sep,yellowgreen,lightgrey)
  let fi = getFileInfo(filename)
  printLnBiCol("File Id                       : " & $(fi.id.device) ,sep,yellowgreen,lightgrey)
  printLnBiCol("File No.                      : " & $(fi.id.file),sep,yellowgreen,lightgrey)
  printLnBiCol("Kind                          : " & $(fi.kind),sep,yellowgreen,lightgrey)
  printLnBiCol("Size                          : " & $(float(fi.size)/ float(1000)) & " kb",sep,yellowgreen,lightgrey)
  printLnBiCol("File Permissions              : ",sep,yellowgreen,lightgrey)
  for pp in fi.permissions:
      printLnBiCol("                              : " & $pp,sep,yellowgreen,lightgrey)
  printLnBiCol("Link Count                    : " & $(fi.linkCount),sep,yellowgreen,lightgrey)
  # these only make sense for non executable files
  #printLnBiCol("Last Access                   : " & $(fi.lastAccessTime),sep,yellowgreen,lightgrey)
  #printLnBiCol("Last Write                    : " & $(fi.lastWriteTime),sep,yellowgreen,lightgrey)
  printLnBiCol("Creation                      : " & $(fi.creationTime),sep,yellowgreen,lightgrey)

  when defined windows:
        printLnBiCol("System                        : Windows ..... Really ??",sep,red,lightgrey)
  elif defined linux:
        printLnBiCol("System                        : Running on Linux" ,sep,brightcyan,yellowgreen)
  else:
        printLnBiCol("System                        : Interesting Choice" ,sep,yellowgreen,lightgrey)

  when defined x86:
        printLnBiCol("Code specifics                : x86" ,sep,yellowgreen,lightgrey)

  elif defined amd64:
        printLnBiCol("Code specifics                : amd86" ,sep,yellowgreen,lightgrey)
  else:
        printLnBiCol("Code specifics                : generic" ,sep,yellowgreen,lightgrey)

  printLnBiCol("Nim Version                   : " & $NimMajor & "." & $NimMinor & "." & $NimPatch,sep,yellowgreen,lightgrey)
  printLnBiCol("Processor count               : " & $countProcessors(),sep,yellowgreen,lightgrey)
  printBiCol("OS                            : "& hostOS,sep,yellowgreen,lightgrey)
  printBiCol(" | CPU: "& hostCPU,sep,yellowgreen,lightgrey)
  printLnBiCol(" | cpuEndian: "& $cpuEndian,sep,yellowgreen,lightgrey)
  let pd = getpid()
  printLnBiCol("Current pid                   : " & $pd,sep,yellowgreen,lightgrey)



proc infoLine*() =
    ## infoLine
    ##
    ## prints some info for current application
    ##
    hlineLn()
    print(fmtx(["<14"],"Application :"),yellowgreen)
    print(extractFileName(getAppFilename()),brightblack)
    print(" | ",brightblack)
    print("Nim : ",lime)
    print(NimVersion & " | ",brightblack)
    print("cx : ",peru)
    print(CXLIBVERSION,brightblack)
    print(" | ",brightblack)
    qqTop()


proc doFinish*() =
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
    print(fmtx(["<14"],"Elapsed     : "),yellowgreen)
    printLn(fmtx(["<",">5"],ff(epochtime() - cx.start,3),"secs"),goldenrod)
    echo()
    quit 0

proc handler*() {.noconv.} =
    ## handler
    ##
    ## this runs if ctrl-c is pressed
    ##
    ## and provides some feedback upon exit
    ##
    ## just by using this module your project will have an automatic
    ##
    ## exit handler via ctrl-c
    ##
    ## this handler may not work if code compiled into a .dll or .so file
    ##
    ## or under some circumstances like being called during readLineFromStdin
    ##
    ##
    eraseScreen()
    echo()
    hlineLn()
    cechoLn(yellowgreen,"Thank you for using     : ",getAppFilename())
    printLn(fmtx(["<","<11",">9"],"Last compilation on     : " , CompileDate , CompileTime),cyan)
    hlineLn()
    printBiCol("Nim Version   : " & NimVersion)
    print(" | ",brightblack)
    printLnBiCol("cx Version     : " & CXLIBVERSION)
    print(fmtx(["<14"],"Elapsed       : "),yellow)
    printLn(fmtx(["<",">5"],epochtime() - cx.start,"secs"),brightblack)
    echo()
    rainbow(" Have a Nice Day !")  ## change or add custom messages as required
    decho(2)
    system.addQuitProc(resetAttributes)
    quit(0)



# putting decho here will put two blank lines before anyting else runs
decho(2)

# putting this here we can stop most programs which use this lib and get the
# automatic exit messages , it may not work in tight loops involving execCMD or
# waiting for readLine() inputs.
setControlCHook(handler)
# this will reset any color changes in the terminal
# so no need for this line in the calling prog
system.addQuitProc(resetAttributes)
# end of cx.nim


when isMainModule:
  let smm = " import cx and your terminal comes alive with color .."
  for x in 0.. 10:
        cleanScreen()
        decho(5)
        printBigLetters("NIM-CX",xpos = 1,fun=true)
        decho(8)
        printLnBiCol(smm,sep = "and ",colLeft = yellowgreen,colRight = clrainbow,centered = false)
        sleepy(0.2)
        curup(1)
        rainbow2(smm,centered = false,colorset=pastelSet)
        echo()
  clearup()      
  printLn(kitty,lime,black,centered=true)
  decho(2)
  doInfo()
  showIpInfo(getWanIp())
  memCheck()
  doFinish()
