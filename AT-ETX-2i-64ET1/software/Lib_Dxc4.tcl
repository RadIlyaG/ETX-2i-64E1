# ***************************************************************************
# ToolsDxc4
# ***************************************************************************
proc ToolsDxc4 {} {
  global gaSet
  set gaSet(idDxc4-1)  [RLDxc4::Open $gaSet(comDxc1) -package RLCom -config default]
 	#set gaSet(idDxc4-2)  [RLDxc4::Open $gaSet(comDxc2) -package RLCom -config default]
  catch {RLDxc4::CloseAll}
  puts "[MyTime] ToolsDxc4" ; update
  return 0
}
# ***************************************************************************
# OpenDxc4
# ***************************************************************************
proc OpenDxc4 {} {
  global gaSet
  set gaSet(idDxc4-1)  [RLDxc4::Open $gaSet(comDxc1) -package RLCom ]; #-config default
 	puts "gaSet(idDxc4-1):<$gaSet(idDxc4-1)>"
   #set gaSet(idDxc4-2)  [RLDxc4::Open $gaSet(comDxc2) -package RLCom ]; #-config default  
  #if {[string is integer $gaSet(idDxc4-1)] && [string is integer $gaSet(idDxc4-2)] && \
      $gaSet(idDxc4-1)>0 && $gaSet(idDxc4-2)>0} { }
  if {[string is integer $gaSet(idDxc4-1)] && $gaSet(idDxc4-1)>0} {  
    SetDxc4  idDxc4-1 int Transparent unframe    
    set ret 0
  } else {
    set ret -1
  }
  puts "[MyTime] OpenDxc4 ret:$ret" ; update
  return $ret
}

# ***************************************************************************
# SetDxc4
## SetDxc4  idDxc4-1 int Transparent unframe
# ***************************************************************************
proc SetDxc4 {dxc4Num srcClk ts0 ts } {
	global gaSet
  Status "Set DXC-[string index $dxc4Num end] $srcClk $ts0 $ts"
  set fram unframe ;#g732n
	switch $ts {
    1 {set tsRange 1}
    31 {set tsRange "1-31"}
    24 {set tsRange "1-24"}
    unframe {set tsRange "unframe"}
  }
#   if {$gaSet(e1Port1) == "BNC"} {
#     set bal "no"
#   } else {
#     set bal "yes"
#   }  
  set bal "yes"
  set gaSet(frameType) E1
	RLDxc4::Stop  $gaSet(idDxc4-1)  bert
	#RLDxc4::Stop  $gaSet(idDxc4-2)  bert  
  RLDxc4::SysConfig $gaSet($dxc4Num) -srcClk $srcClk
	if {$gaSet(frameType) == "E1"} {
    RLDxc4::PortConfig $gaSet($dxc4Num) $gaSet(frameType) -updPort all -frameE1 $fram\
                        -intfE1 dsu -lineCodeE1 hdb3 -balanced $bal -idleCode 7C
   	RLDxc4::BertConfig $gaSet($dxc4Num) -updPort all -linkType $gaSet(frameType) -enabledBerts  all\
  	                   -pattern 2e15 -tsAssignm $tsRange -inserrRate single  -inserrBerts all
  } elseif {$gaSet(frameType) == "T1"} {
  	  RLDxc4::PortConfig $gaSet($dxc4Num) $gaSet(frameType) -updPort all -frameT1 $fram\
                                              -intfT1 dsu -lineCodeT1 b8zs -idleCode 7C
    	RLDxc4::BertConfig $gaSet($dxc4Num) -updPort all -linkType $gaSet(frameType)\
                          -enabledBerts  all -pattern 2e15 -tsAssignm $tsRange\
                          -inserrRate single  -inserrBerts all
  }
  return 0
}

# ***************************************************************************
# Dxc4Start
# ***************************************************************************
proc Dxc4Start {} {
  global gaSet
  Status "Dxc4 Start"
  #foreach dxc4Num {idDxc4-1 idDxc4-2} { }
  foreach dxc4Num {idDxc4-1 } {
    RLDxc4::Start  $gaSet($dxc4Num)  bert
    RLDxc4::Start  $gaSet($dxc4Num)  bert
  }
  RLTime::Delay 2
#   if {$gaSet(dutFam)=="f35"} {
#     set port 1-4
#   } else {
#     set port 1
#   } 
  set port 1
	foreach dxc4Num {idDxc4-1} {
   	RLDxc4::Clear  $gaSet($dxc4Num)  bert $port
    RLTime::Delay 1	
   	RLDxc4::Clear  $gaSet($dxc4Num)  bert $port
  }  
}
# ***************************************************************************
# Dxc4InjErr
# ***************************************************************************
proc Dxc4InjErr {} {
  global gaSet gRes
  Status "Dxc4 Inject Errors"
  #foreach dxc4Num {idDxc4-1 idDxc4-2} { }
  foreach dxc4Num {idDxc4-1} {  	
   	RLDxc4::BertInject $gaSet($dxc4Num)
   	RLTime::Delay 1
   	RLDxc4::BertInject $gaSet($dxc4Num)
   	RLTime::Delay 1
  }
  #foreach dxc4Num {idDxc4-1 idDxc4-2} d {DXC-1 DXC-2} { }
  foreach dxc4Num {idDxc4-1} d {DXC-1} {
    #for {set i 1} {$i <= 4} {incr i 1} {}
    for {set i 1} {$i <= 1} {incr i 1} {
      if {$i == 2} {
        ## ???? continue 
      }
      RLDxc4::GetStatistics $gaSet($dxc4Num)  gRes  -statistic bertStatis -port $i
     	parray gRes
    	if {$gRes(id$gaSet($dxc4Num),errorSec,Port$i) != 2 || $gRes(id$gaSet($dxc4Num),errorBits,Port$i) != 2} {
        #RLDxc4::Stop  $gaSet(idDxc4-1)  bert
        #RLDxc4::Stop  $gaSet(idDxc4-2)  bert
        set gaSet(fail) "$d port $i - Inject Error Failed"
    		return -1
    	}
      RLDxc4::Clear  $gaSet($dxc4Num)  bert $i
#       if {$gaSet(dutFam)!="f35"} {
#         break
#       }
    }
  }
  return 0
}
# ***************************************************************************
# Dxc4Check
# ***************************************************************************
proc Dxc4Check {} {
  global gaSet gRes  
  #foreach dxc4Num {idDxc4-1 idDxc4-2} d {DXC-1 DXC-2} { }
  foreach dxc4Num {idDxc4-1} d {DXC-1} {
    Status "$d Check .. [MyTime]" ; update
    #for {set i 1} {$i <= 4} {incr i 1} { }
    for {set i 1} {$i <= 1} {incr i 1} {
      if {$i == 2} {
        ### ???continue
      }
      RLDxc4::GetStatistics $gaSet($dxc4Num)  gRes  -statistic bertStatis -port $i
      parray gRes
    	if {$gRes(id$gaSet($dxc4Num),syncLoss,Port$i) || $gRes(id$gaSet($dxc4Num),errorSec,Port$i) || $gRes(id$gaSet($dxc4Num),errorBits,Port$i)} {
        #RLDxc4::Stop  $gaSet(idDxc4-1)  bert
        #RLDxc4::Stop  $gaSet(idDxc4-2)  bert
        set gaSet(fail) "$d port $i - Data Test Failed"
    		return -1
    	}
      puts ""
#       if {$gaSet(dutFam)!="f35"} {
#         break
#       }
    }
  }
	
  return 0
}
# ***************************************************************************
# Dxc4Stop
# ***************************************************************************
proc Dxc4Stop {} {
  global gaSet
  RLDxc4::Stop  $gaSet(idDxc4-1)  bert
# 	RLDxc4::Stop  $gaSet(idDxc4-2)  bert
}
