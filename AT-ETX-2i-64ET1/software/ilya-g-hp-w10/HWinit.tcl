set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
   1 {
      set gaSet(comUut1)    5
      set gaSet(comUut2)    6
      set gaSet(comGen1)    7
      set gaSet(comDxc1)    4   
      set gaSet(comAux1)    10
      set gaSet(comAux2)    9
      set gaSet(comGpib)   11
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT2C8LFP  
  } 
  
}  
source lib_PackSour.tcl
