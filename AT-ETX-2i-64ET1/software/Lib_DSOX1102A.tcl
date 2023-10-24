# ***************************************************************************
# GpibOpen
# ***************************************************************************
proc GpibOpen {} {
  return [ViOpen]
}
# ***************************************************************************
# ViOpen
# ***************************************************************************
proc ViOpen {} {
  global gaSet
  set ret -1
  package require tclvisa
  
  # foreach DSOX1102ASerNumber [list CN58064160 CN57344642 CN56404126 CN58064279 CN56404116  CN58174246 CN59014296] {}
  foreach field3 [list 6023 6023 6023 6023 6023 6023 6023 903 903 903 6023 903] \
      DSOX1102ASerNumber [list CN58064160 CN57344642 CN56404126 CN58064279 \
      CN56404116 CN58174246 CN59014296 CN60182123 CN60182353 CN61022152\
      CN59284320 CN61482385] {
    puts "field3:$field3 DSOX1102ASerNumber:$DSOX1102ASerNumber"
    set visaAddr "USB0::10893::[set field3]::[set DSOX1102ASerNumber]::INSTR"
    # puts "DSOX1102ASerNumber:$DSOX1102ASerNumber"
    # set visaAddr "USB0::10893::6023::[set DSOX1102ASerNumber]::INSTR"
    if [catch { set rm [visa::open-default-rm] } rc] {
      puts "Error opening default resource manager\n$rc"
    }
  
    if [catch { set gaSet(vi) [visa::open $rm $visaAddr] } rc] {
      puts "Error opening instrument `$visaAddr`\n$rc"
      set ret -1
    } else {
      set ret 0
      puts "OK"
      break
    }
  }
  puts ""; update  
  
  if {$ret=="-1"} {
    return -1
  } 
  
  set gaSet(rm) $rm
  ViSet "*cls"
  return 0
}

# ***************************************************************************
# GpibClose
# ***************************************************************************
proc GpibClose {} {
  return [ViClose]
}
# ***************************************************************************
# ViClose
# ***************************************************************************
proc ViClose {} {
  global gaSet
  close $gaSet(vi)
  close $gaSet(rm)
  unset  gaSet(vi)
  unset  gaSet(rm)
}


# ***************************************************************************
# ViSet
# ***************************************************************************
proc ViSet {cmd} {
  global gaSet
  puts $gaSet(vi) "$cmd" 
}

# ***************************************************************************
# ViGet
# ***************************************************************************
proc ViGet {cmd res} {
  global gaSet buffer
  upvar $res buff
  ViSet $cmd
  set buff [gets $gaSet(vi)]
}
# ***************************************************************************
# ExistTds520B
# ***************************************************************************
proc ExistTds520B {} {
  return [ExistDSOX1102A]
}
# ***************************************************************************
# ExistDSOX1102A
# ***************************************************************************
proc ExistDSOX1102A {} {
  global gaSet 
  catch {ViGet "*idn?" buffer} err
  if {[string match "*DSO-X 1102A*" $buffer]==0} {
    set gaSet(fail) "Wrong scope identification - $buffer (expected DSO-X 1102A)"
    #return -1
  }
  return 0
}
proc DefaultTds520b {} {
  return [DefaultDSOX1102A]
}
# ***************************************************************************
# DefaultDSOX1102A
# ***************************************************************************
proc DefaultDSOX1102A {} {
  global gaSet
  Status "Set the DSOX1102A to default"
  ViSet "*cls"
  ClearDSOX1102A
  fconfigure $gaSet(vi) -timeout 500
  ViSet ":aut"  
  return {}
}
# ***************************************************************************
# ClearDSOX1102A
# ***************************************************************************
proc ClearDSOX1102A {} {
  Status "Clear DSOX1102A"
  ViSet :disp:cle
  ViSet ":chan1:disp 0"
  ViSet ":chan2:disp 0"
}


# ***************************************************************************
# SetLockClkTds
# ***************************************************************************
proc SetLockClkTds {} {
  puts "Set Scope : Lock Clock test"
  
  #GpibSet "select:control ch1"
  ViSet ":chan1:disp 1"
  ViSet ":chan2:disp 1"
  
  ViSet ":trig:mode edge"
  ViSet ":trig:edge:source chan1"
  ViSet ":trig:edge:lev 15" ; # 1.5
  ViSet ":trig:edge:coup dc"
#   ViSet ":trig:edge:slope neg" ; #21/11/2018 13:49:28
  ViSet ":trig:edge:slope pos"
  ViSet ":trig:force"
#   GpibSet "data:source CH1"
  ViSet ":chan1:prob 10"
  ViSet ":chan2:prob 10"
  #ViSet ":chan2:range 200V"
  ViSet ":chan1:coup dc"
#   ViSet ":chan1:offs 25V"
  ViSet ":chan2:coup dc"
#   ViSet ":chan2:offs -25V"
  ViSet ":tim:scal 1E-7" ; #2.5E-7
  after 1000
ViSet ":acq:type norm"
}

# ***************************************************************************
# ChkLockClkTds
# ***************************************************************************
proc ChkLockClkTds {} {
  global gaSet
  puts "Get Scope : Lock clock test"
  set gaSet(fail) ""
#   GpibSet "select:ch1 on"
#   GpibSet "select:control ch1"
  Status "Check freq at CH1"
  ViSet ":meas:freq chan1"
#   GpibSet "measurement:meas1:state on"
   after 100
  ViGet ":meas:freq?" freq1
  puts "freq1:<$freq1>" ; update
  if {[expr $freq1]>2060000 || [expr $freq1]<2030000} {
    set gaSet(fail) "Ch-1 is not 2.048MHz freqency (found [expr $freq1])"
    return -1
  }
  
  Status "Check freq at CH2"
#   GpibSet "select:ch2 on"
#   GpibSet "select:control ch2"
  ViSet ":meas:freq chan2"
#   GpibSet "measurement:meas2:state on"
   after 100
  ViGet ":meas:freq?" freq2
  puts "freq2:<$freq2>" ; update
  if {[expr $freq2]>2060000 || [expr $freq2]<2030000} {
    set gaSet(fail) "Ch-2 is not 2.048MHz freqency (found [expr $freq2])"
    return -1
  }
  
  ViSet ":tim:scal 5E-8"
  after 1000
  Status "Check edges"
  set checks 100
  set minch1 [set maxch1 [ViGet ":meas:tedge? +1, chan1" te]]
  set minch2 [set maxch2 [ViGet ":meas:tedge? +1, chan2" te]]
  ViSet ":meas:del chan1,chan2"
  set mindel [set maxdel 0]
  for {set i 1} {$i<=$checks} {incr i} {
    ## example p374
    foreach ch {1 2} {
      ViGet ":meas:tedge? +1, chan$ch" te
      if {$te<[set minch$ch] && $te!=""} {
        set minch[set ch] $te
        puts "ch:$ch minch[set ch]:[set minch[set ch]]"
      }
      if {$te>[set maxch$ch] && $te!=""} {
        set maxch[set ch] $te
        puts "ch:$ch maxch[set ch]:[set maxch[set ch]]"
      }
      after 50
    } 
#     ViGet ":meas:del?" te
#       if {$te < $mindel} {
#         set mindel $te
#       }
#       if {$te > $maxdel} {
#         set maxdel $te
#       }
  }
  
  foreach ch {1 2} {
#     puts "minch$ch: [set minch$ch]"
#     puts "maxch$ch: [set maxch$ch]"
    set delta [2nano [expr {[set maxch$ch] - [set minch$ch]}]]
    puts "ch-$ch delta:  $delta nSec"
    if {$delta>100} {
      set gaSet(fail) "The CH-$ch is not stable"
      return -1
    }
    if {$delta>30} {
      set gaSet(fail) "The Jitter at CH-$ch more then 30nSec ($delta nSec)"
      return -1
    }
  }
#     set nanomaxdel [2nano $maxdel]
#     puts "nanomaxdel:$nanomaxdel nSec" 
#     if {$nanomaxdel>100} {
#       set gaSet(fail) "The CH-2 is not stable"
#       return -1
#     }
#     if {$nanomaxdel>30} {
#       set gaSet(fail) "The Jitter at CH-2 more then 30nSec ($nanomaxdel nSec)"
#       return -1
#     }
  
  #puts "del:[2nano $del] nSec"
  update 
  
 return 0
}

# ***************************************************************************
# 2nano
# ***************************************************************************
proc 2nano {tim} {
  # puts "2nano $tim"
  foreach {b ex} [split [string toupper $tim] E] {}
  switch -exact -- $ex {
    -002 - -02 - -2 {set m 10000000}
    -003 - -03 - -3 {set m 1000000}
    -004 - -04 - -4 {set m 100000}
    -005 - -05 - -5 {set m 10000}
    -006 - -06 - -6 {set m 1000}
    -007 - -07 - -7 {set m 100}
    -008 - -08 - -8 {set m 10}
    -009 - -09 - -9 {set m 1}
    -010 - -10 {set m 0.1}
    -011 - -11 {set m 0.01}
    -012 - -12 {set m 0.001}
  }
  return [expr {$b*$m}]
}

# ***************************************************************************
# CheckJitter
# ***************************************************************************
proc CheckJitter {stam} {
  ## performed by ChkLockClkTds
  return 0
}