import nimcx,nimFinLib


# display the kitco metal price
cleanScreen()
decho(2)
showKitcoMetal(xpos = 3)
decho(1)       
printBiCol(fmtx([""]," Data Source :  KITCO "),colleft=slategray,colright=pastelwhite,sep=": ",xpos = 4,false,{styleReverse})       
doFinish()   
