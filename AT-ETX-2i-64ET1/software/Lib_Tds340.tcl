# ***************************************************************************
# GpibOpen
# ***************************************************************************
proc GpibOpen {} {
  global gaSet
  set ret -1
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Open $id 
  } else {
    set com $gaSet(comGpib)
    ##set ret [RLSerial::Open $com 9600 n 8 1]
    set ret [RLCom::Open $com 9600 8 NONE 1]
    GpibSet "++auto"
    set ret 0
  }
  return $ret
}

# ***************************************************************************
# GpibClose
# ***************************************************************************
proc GpibClose {} {
  global gaSet
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Close $id 
  } else {
    set com $gaSet(comGpib)
    RLCom::Close $com
    ##RLSerial::Close $com
  }
}


# ***************************************************************************
# GpibSet
# ***************************************************************************
proc GpibSet {cmd} {
  global gaSet
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Set $id "$cmd"
  } else {
    set com $gaSet(comGpib)
    RLCom::Send $com "$cmd\r"
    ##RLSerial::Send $com "$cmd\r"
    puts "send:$cmd"; update
    after 100 
  } 
}

# ***************************************************************************
# GpibGet
# ***************************************************************************
proc GpibGet {cmd res} {
  global gaSet buffer
  upvar $res buff
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Set $id "$cmd"
    RLGpib::Get $id buff
  } else {
    set com $gaSet(comGpib)
    ##RLCom::Send $com "$cmd\r" buffer ":" 10 
    Send $com "$cmd\r" ":" 2; #10
    set buff $buffer
    #puts "send:$cmd, recieve:$buffer"
    after 100 
  }
}
# ***************************************************************************
# ExistTds520B
# ***************************************************************************
proc ExistTds520B {} {
  global gaSet 
  catch {GpibGet "*idn?" buffer} err
  if {[string match "*TDS 340*" $buffer]==0} {
    set gaSet(fail) "Wrong scope identification - $buffer (expected TDS 340)"
    return -1
  }
  return 0
}
# ***************************************************************************
# DefaultTds520b
# ***************************************************************************
proc DefaultTds520b {} {
  Status "Set the TDS340 to default"
  GpibSet "autoset execute"
  GpibSet "horizontal:trigger:position 50"
}
# ***************************************************************************
# ClearTds520b
# ***************************************************************************
proc ClearTds520b {} {
  GpibSet "clearmenu"
  GpibSet "measurement:meas1:state off"
  GpibSet "measurement:meas2:state off"
  GpibSet "measurement:meas3:state off"
  GpibSet "measurement:meas4:state off"
  GpibSet "select:ch1 off"
  GpibSet "select:ch2 off"
  GpibSet "select:ch3 off"
  GpibSet "select:ch4 off"
}


# ***************************************************************************
# SetLockClkTds
# ***************************************************************************
proc SetLockClkTds {} {
  Status "Set Scope : Lock Clock test"

  ClearTds520b
  GpibSet "select:control ch1"
  GpibSet "select:ch1 on"
  GpibSet "select:ch2 on"
  GpibSet "data:source CH1"
  GpibSet "ch1:volts 5"
  GpibSet "ch2:volts 5"
  GpibSet "ch1:coupling dc"
  GpibSet "ch1:position 2"
  GpibSet "ch2:coupling dc"
  GpibSet "ch2:position -2"
  GpibSet "horizontal:secdiv 2.5E-7"
  after 1000


  GpibSet "trigger:main:mode auto"
  GpibSet "trigger:main:level 1.5"
  GpibSet "trigger:main:edge:coupling dc"
  GpibSet "trigger:main:edge:slope fall"
  GpibSet "trigger:main:edge:source ch1"
#  GpibSet "ch1:volts 1"
#  GpibSet "ch2:volts 1"
  GpibSet "trigger force"
}

# ***************************************************************************
# ChkLockClkTds
# ***************************************************************************
proc ChkLockClkTds {} {
  global gaSet
  Status "Get Scope : Lock clock test"

  GpibSet "select:ch1 on"
  GpibSet "select:control ch1"
  GpibSet "measurement:meas1:type freq"
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:state on"
  after 2000
  GpibGet "measurement:meas1:value?" freq1
  #puts "freq1:<$freq1>" ; update
  if {[expr $freq1]>2060000 || [expr $freq1]<2030000} {
    set gaSet(fail) "Ch-1 is not 2.048MHz freqency (found [expr $freq1])"
    return -1
  }
  GpibSet "select:ch2 on"
  GpibSet "select:control ch2"
  GpibSet "measurement:meas2:type freq"
  GpibSet "measurement:meas2:source1 ch2"
  GpibSet "measurement:meas2:state on"
  after 2000
  GpibGet "measurement:meas2:value?" freq2
  #puts "freq2:<$freq2>" ; update
  if {[expr $freq2]>2060000 || [expr $freq2]<2030000} {
    set gaSet(fail) "Ch-2 is not 2.048MHz freqency (found [expr $freq2])"
    return -1
  }

  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 1000"
  
  after 1000
  Status "Getting CH's 1 graph, curve 0"
  GpibGet "curve?" buffer1
  set bufCh1 [split $buffer1 ,]
  set bufCh1 [lrange $bufCh1 250 750]
  after 2000
  for {set j 1} {$j<=1} {incr j} {
    Status "Getting CH's 1 graph, curve $j"
    GpibGet "curve?" buffer1
    set buf1 [split $buffer1 ,]
    set buf1 [lrange $buf1 250 750]
    set listGap1 [CompareGraph $bufCh1 $buf1] 
    set avg1 [AvgGraph $listGap1] 
    if {$avg1>2} {
      set gaSet(fail) "Ch-1 freqency is not stable"
      #puts "Ch-1=$listGap1"
      puts "avg=$avg1"
      return -1
    }
  }
  
  Wait "Wait for clock locking" 10
  ##delayn 10
  GpibSet "data:source CH2"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 1000"
  after 1000
  
  Status "Getting CH's 2 graph, curve 0"
  GpibGet "curve?" buffer2
  set bufCh2 [split $buffer2 ,]
  set bufCh2 [lrange $bufCh2 250 750]
  after 2000
  for {set j 1} {$j<=3} {incr j} {
    Status "Getting CH's 2 graph, curve $j"
    GpibGet "curve?" buffer2
    set buf2 [split $buffer2 ,]
    set buf2 [lrange $buf2 250 750]
    set listGap2 [CompareGraph $bufCh2 $buf2] 
    set avg2 [AvgGraph $listGap2] 
    puts "j:$j avg2:$avg2"
    set max 3
    if {$avg2>$max} {
      set gaSet(fail) "Ch-2 freqency is not stable"
      #puts "Ch-2=$listGap2"
      puts "avg=$avg2, max:$max"
      return -1
    }
  }
  return 0
}

# ***************************************************************************
# CompareGraph
# ***************************************************************************
proc CompareGraph {buf1 buf2} {
  set g ""
  foreach i "$buf1" j "$buf2" {
    lappend g [expr abs($i-$j)]
  }
  return "$g"
}

# ***************************************************************************
# AvgGraph
# ***************************************************************************
proc AvgGraph {buf} {
  set sum 0
  foreach i "$buf" {
    set sum [expr $sum+$i]
  }
  set avg [expr $sum.0/[llength $buf]]
  return "[format %.2f $avg]"
}

proc qwe {} {
Send $com "display:format YT\r" ":" 2
Send $com "display:style accumdots\r" ":" 2
Send $com "display:pers 0\r" ":" 2
Send $com "display:pers 1.25\r" ":" 2

}

# ***************************************************************************
# ReadWave
# ***************************************************************************
proc ReadWave {com} {
  global gaSet buffer
  #set com $gaSet(comGpib)
  #RLSerial::Send $com "curve?\r"
  RLCom::Send $com "curve?\r"
  ## 250 is too small
  after 500
  ##RLSerial::Waitfor $com buffer
  RLCom::Waitfor $com buffer
  
  set ll [split $buffer ,]
  foreach amp {-3 -2 -1 0 1 2 3} {
    set indx [lsearch $ll $amp]
    if {$indx!="-1"} {
      #puts "amp:$amp indx:$indx" ; update
      return $indx
    }
  }
}
# ***************************************************************************
# CheckJitter
# ***************************************************************************
proc CheckJitter {scQty} {
  global gaSet buffer
  set com $gaSet(comGpib)
  set nSecDiv 25
  GpibSet "horizontal:secdiv [format %.E [expr {$nSecDiv * 1E-9}]]"
  GpibSet "ch1:volts 2"
  GpibSet "ch2:position -1"
  GpibSet "ch2:volts 2"
  GpibSet "data:source CH2"
  GpibSet "data:start 250"
  GpibSet "data:stop 750"
  after 2000
  set min [ReadWave $com]
  set max $min
  for {set sc 1} {$sc<=$scQty} {incr sc} {
    if {$gaSet(act)=="0"} {return -2}
    Status "Scan $sc of $scQty"
    set point [ReadWave $com]
    if {$point==""} {continue}
    #puts "sc: $sc point:$point"
    if {$point<$min} {
      set min $point
    }
    if {$point>$max} {
      set max $point
    }
    puts "sc: $sc point:$point min:$min max:$max"
  }
  set jit [expr {(($max-$min)*$nSecDiv*10.0)/500}]
  puts "jit:$jit" ; update
  return $jit
}

