# ***************************************************************************
# EntryBootMenu
# ***************************************************************************
proc EntryBootMenu {} {
  global gaSet buffer
  puts "[MyTime] EntryBootMenu"; update
  set ret [Send $gaSet(comUut1) \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  set ret [Send $gaSet(comUut1) \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
#   set ret [Reset2BootMenu $uut]
#   if {$ret!=0} {return $ret}
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  Power all off
  RLTime::Delay 2
  Power all on
  RLTime::Delay 2
  Status "Entry to Boot Menu"
  set gaSet(fail) "Entry to Boot Menu fail"
  set ret [Send $gaSet(comUut1) \r "stop auto-boot.." 20]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comUut1) \r\r "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  return 0
}

# ***************************************************************************
# DownloadUsbPortApp
# ***************************************************************************
proc DownloadUsbPortApp  {} { 
  global gaSet buffer
  puts "[MyTime] DownloadUsbPortApp"; update
  set gaSet(fail) "Config IP in Boot Menu fail"
  set ret [Send $gaSet(comUut1) "c ip\r" "(ip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comUut1) "10.10.10.1$gaSet(pair)\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
    
  set gaSet(fail) "Config DM in Boot Menu fail"
  set ret [Send $gaSet(comUut1) "c dm\r" "(dm)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comUut1) "255.255.255.0\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config SIP in Boot Menu fail"
  set ret [Send $gaSet(comUut1) "c sip\r" "(sip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comUut1) "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config GW in Boot Menu fail"
  set ret [Send $gaSet(comUut1) "c g\r" "(g)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comUut1) "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config TFTP in Boot Menu fail"
  set ret [Send $gaSet(comUut1) "c p\r" "ftp\]"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comUut1) "ftp\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $gaSet(comUut1) "\r" "\[boot\]:"]
  if {$ret!=0} {return $ret} 
  
  set ret [Send $gaSet(comUut1) "set-active 1\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret} 
  set ret [Send $gaSet(comUut1) "delete sw-pack-3\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Start \'download 3,sw-pack_2i_USB_test.bin\' fail"
  set ret [Send $gaSet(comUut1) "download 3,sw-pack_2i_USB_test.bin\r" "transferring" 3]
  if [string match {*you sure(y/n)*} $buffer] {
    set ret [Send $gaSet(comUut1) "y\r" "transferring"]    
  }
  if {$ret!=0} {return $ret} 
  
  set startSec [clock seconds]
  while 1 {
    Status "Wait for application downloading"
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set dwnlSec [expr {$nowSec - $startSec}]
    #puts "dwnlSec:$dwnlSec"
    $gaSet(runTime) configure -text $dwnlSec
    if {$dwnlSec>600} {
      set ret -1 
      break
    }
    #set ret [RLSerial::Waitfor $gaSet(comUut1) buffer "\[boot\]:" 2]
    set ret [RLCom::Waitfor $gaSet(comUut1) buffer "\[boot\]:" 2]
    puts "<$dwnlSec><$buffer>" ; update
    if {$ret==0} {break}
    if [string match {*\[boot\]*} $buffer] {
      set ret 0
      break
    }
  }  
  if {$ret=="-1"} {
    set gaSet(fail) "Download \'3,sw-pack_2i_usb.bin\' fail"
    return -1 
  }
  
  set gaSet(fail) "\'set-active 3\' fail" 
  set ret [Send $gaSet(comUut1) "\r" "\[boot\]:" 1]
  set ret [Send $gaSet(comUut1) "\r" "\[boot\]:" 1]
  set ret [Send $gaSet(comUut1) "set-active 3\r" "\[boot\]:" 25]
  if {$ret!=0} {return $ret}  
  Status "Wait for Loading/un-compressing sw-pack-3"
  set ret [Send $gaSet(comUut1) "run 3\r" "sw-pack-3.." 50]
  if {$ret!=0} {return $ret} 
          
  return 0
}  
# ***************************************************************************
# CheckUsbPort
# ***************************************************************************
proc CheckUsbPort {} {
  puts "[MyTime] CheckUsbPort"; update
  global gaSet buffer accBuffer
  

  Status "USB port Test"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read USB port"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read USB port fail"
  set ret [Send $com "debug usb display-device-param\r" ETX-2I]
  if {$ret!=0} {return $ret}
  
  if {[string match {*USB device in*} $buffer]} {
    set ret 0
  } else {
    set ret -1
    set gaSet(fail) "USB port doesn't recognize an USB device"
  }        
  return $ret
}  
# ***************************************************************************
# DeleteUsbPortApp
# ***************************************************************************
proc DeleteUsbPortApp {} { 
  puts "[MyTime] DeleteUsbPortApp"; update
  global gaSet buffer
  set gaSet(fail) "Delete UsbPort App fail"
  set ret [Send $gaSet(comUut1) "set-active 1\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret} 
  set ret [Send $gaSet(comUut1) "delete sw-pack-3\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comUut1) "run\r" "sw-pack-1.." 55]
  if {$ret!=0} {return $ret} 
  return $ret
}  


# ***************************************************************************
# PS_IDTest
# ***************************************************************************
proc PS_IDTest {} {
  global gaSet buffer
  Status "PS_ID Test"
  Power all on
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comUut1)  
  set ret [Send $com "exit all\r" ETX-2I]
  if {$ret!=0} {return $ret}
#   set ret [Send $com "info\r" more 80]  
#   regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  set ret [Send $com "le\r" ETX-2I]  
  regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  
  if ![info exists sw] {
    set gaSet(fail) "Can't read the SW version"
    return -1
  }
  puts "sw:$sw"
    
#   set ret [Send $com "\3" ETX-2I 0.25]
#   if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" ETX-2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set fa1 [set fa2 xx]
  set res [regexp {FAN Status[\s\-]+1\s+(\w+)\s+2\s+(\w+)\s+Sensor} $buffer ma fa1 fa2]
  puts "FANs status fa1:<$fa1> fa2:<$fa2>"
  if {$res==0} {
    Wait "Wait for up" 5
    set ret [Send $com "show environment\r" chassis]
    if {$ret!=0} {return $ret}
    set res [regexp {FAN Status[\s\-]+1\s+(\w+)\s+2\s+(\w+)\s+Sensor} $buffer ma fa1 fa2]
    puts "FANs status fa1:<$fa1> fa2:<$fa2>"
    if {$res==0} {
      set gaSet(fail) "Read FANs status fail"
      return -1
    }    
  }
  if {$fa1!="OK"} {
    set gaSet(fail) "FAN 1 status is \'$fa1\'. Should be \'OK\'"
    return -1
  }
  if {$fa2!="OK"} {
    set gaSet(fail) "FAN 2 status is \'$fa2\'. Should be \'OK\'"
    return -1
  }
  if 1  {
  set psQty [regexp -all $ps $buffer]
  set psQtyShBe 2
  puts "PS_IDTest b:$b psQty:$psQty psQtyShBe:$psQtyShBe"
  if {$psQty!=$psQtyShBe} {
    set gaSet(fail) "Qty or type of PSs is wrong."
#     AddToLog $gaSet(fail)
    return -1
  }
  #regexp {\-+\s(.+)\s+FAN} $buffer - psStatus
  regexp {\-+\s(.+\s+FAN)} $buffer - psStatus
  regexp {1\s+(\w+)\s+([\s\w]+)\s+2} $psStatus - ps1Type ps1Status
  set ps1Type   [string trim $ps1Type]
  set ps1Status [string trim $ps1Status]
  puts "ps1Type:<$ps1Type> ps:<$ps> ps1Status:<$ps1Status>"
  
  if {$ps1Type!="$ps"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Type\'. Should be \'$ps\'"
    return -1
  }
  if {$ps1Status!="OK"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
    return -1
  }
  
  regexp {2\s+(\w+)\s+([\s\w]+)\s+} $psStatus - ps2Type ps2Status
  set ps2Type   [string trim $ps2Type]
  set ps2Status [string trim $ps2Status]
  puts "ps2Type:<$ps2Type> ps:<$ps> ps2Status:<$ps2Status>"
  if {$ps2Type!="$ps"} {
    set gaSet(fail) "Status of PS-2 is \'$ps2Type\'. Should be \'$ps\'"
    return -1
  }
  if {$ps2Status!="OK"} {
    set gaSet(fail) "Status of PS-2 is \'$ps2Status\'. Should be \'OK\'"
#     AddToLog $gaSet(fail)
    return -1
  }
  
    foreach ps {1 2} {
      Power $ps off
      #after 10000
      set ret [Wait "Wait for PS-$ps is OFF" 5 white]
      if {$ret!=0} {return $ret}
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="Failed"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Failed\""
  #       AddToLog $gaSet(fail)
        return -1
      }
#       RLSound::Play information
#       set txt "Verify on PS-$ps that RED led is ON"
#       set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#       update
#       if {$res!="OK"} {
#         set gaSet(fail) "LED Test failed"
#         return -1
#       } else {
#         set ret 0
#       }
#       
#       RLSound::Play information
#       set txt "Remove PS-$ps and verify that led is OFF"
#       set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
#       update
#       if {$res!="OK"} {
#         set gaSet(fail) "PS_ID Test failed"
#         return -1
#       } else {
#         set ret 0
#       }
#       
#       set val [ShowPS $ps]
#       puts "val:<$val>"
#       if {$val=="-1"} {return -1}
#       if {$val!="Not exist"} {
#         set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
#   #       AddToLog $gaSet(fail)
#         return -1
#       }
      
  #     RLSound::Play information
  #     set txt "Verify on PS $ps that led is OFF"
  #     set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  #     update
  #     if {$res!="OK"} {
  #       set gaSet(fail) "LED Test failed"
  #       return -1
  #     } else {
  #       set ret 0
  #     }
      
#       RLSound::Play information
#       set txt "Assemble PS-$ps"
#       set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
#       update
#       if {$res!="OK"} {
#         set gaSet(fail) "PS_ID Test failed"
#         return -1
#       } else {
#         set ret 0
#       }
      Power $ps on
      after 2000
    }
  
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
#   if {[string range $sw end-1 end]=="SR" && $r=="R"} {
#     set gaSet(fail) "The sw is \"$sw\" and the DUT is RTR"
#     return -1
#   }
#   if {[string range $sw end-1 end]!="SR" && $r=="0"} {
#     set gaSet(fail) "The sw is \"$sw\" and the DUT is not RTR"
#     return -1
#   }
  
  if {[string range $sw end-1 end]=="SR"} {
    puts "sw:$sw"
    set sw [string range $sw 0 end-2]  
    puts "sw:$sw"
  }
  
  # 21/11/2018 09:35:08 set gaSet(dbrSW) "6.5.1(0.2)"
  if {$sw!=$gaSet(dbrSW)} {
    set gaSet(fail) "SW is \"$sw\". Should be \"$gaSet(dbrSW)\""
    return -1
  }
  
  set ret [ReadCPLD]
  if {$ret!=0} {return $ret}
  
  if {![info exists gaSet(uutBootVers)] || $gaSet(uutBootVers)==""} {
    set ret [Send $com "exit all\r" 2I]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin reboot\r" "yes/no"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "y\r" "seconds" 20]
    if {$ret!=0} {return $ret}
    set ret [ReadBootVersion]
    if {$ret!=0} {return $ret}
  }
  
  set gaSet(dbrBVer) "1.11"
  puts "gaSet(uutBootVers):<$gaSet(uutBootVers)>"
  puts "gaSet(dbrBVer):<$gaSet(dbrBVer)>"
  update
  if {$gaSet(uutBootVers)!=$gaSet(dbrBVer)} {
    set gaSet(fail) "Boot Version is \"$gaSet(uutBootVers)\". Should be \"$gaSet(dbrBVer)\""
    return -1
  }
  set gaSet(uutBootVers) ""
  

  return $ret
}
# ***************************************************************************
# DyingGaspSetup
# ***************************************************************************
proc neDyingGaspSetup {} {
  global gaSet buffer gRelayState
  Status "DyingGaspTest"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(DGaspCF)
  set cfTxt "Dying Gasp"
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
#   set dutIp 10.10.10.1[set gaSet(pair)]  
#   for {set i 1} {$i<=20} {incr i} {   
#     set ret [Ping $dutIp]
#     puts "DyingGaspSetup ping after download i:$i ret:$ret"
#     if {$ret!=0} {return $ret}
#   }
  
  foreach {b r p d ps} [split $gaSet(dutFam) .] {}
  if {$b=="19V"} {
    set ret [DnfvPower off] 
    if {$ret!=0} {return $ret} 
  }  
#   if {$ps=="DC"} {
#     Power all off
#     set gRelayState red
#     IPRelay-LoopRed
#     SendEmail "ETX-2I" "Manual Test"
#     RLSound::Play information
#     set txt "Remove the DC PSs and insert AC PSs"
#     set res [DialogBox -type "OK Cancel" -icon /images/question -title "Change PS" -message $txt]
#     update
#     if {$res!="OK"} {
#       return -2
#     } else {
#       set ret 0
#     }
#     Power all on
#     set gRelayState green
#     IPRelay-Green
#   } elseif {$ps=="AC" || $ps=="AC HP"} {
#     Power all off
#     after 1000
#     Power all on
#   }
  Power all off
  after 1000
  Power all on
  
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }

#   set snmpId [RLScotty::SnmpOpen $dutIp]
#   RLScotty::SnmpConfig $snmpId -version SNMPv3 -user initial
  return $ret
}    
 
# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc DyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
  puts "[MyTime] DyingGaspPerf $psOffOn $psOff"
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 

   
  set wsDir C:\\Program\ Files\\Wireshark
  set npfL [exec $wsDir\\tshark.exe -D]
  ## 1. \Device\NPF_{3EEEE372-9D9D-4D45-A844-AEA458091064} (ATE net)
  ## 2. \Device\NPF_{6FBA68CE-DA95-496D-83EA-B43C271C7A28} (RAD net)
  set intf ""
  foreach npf [split $npfL "\n\r"] {
    set res [regexp {(\d)\..*ATE} $npf - intf] ; puts "<$res> <$npf> <$intf>"
    if {$res==1} {break}
  }
  if {$res==0} {
    set gaSet(fail) "Get ATE net's Network Interface fail"
    return -1
  }
  
  Status "Wait for Ping traps"
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  set dur 10
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &
  after 1000
  set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  after "[expr {$dur +1}]000" ; ## one sec more then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\r---<$monData>---\r"; update
  
  set res [regexp -all "Src: $dutIp, Dst: 10.10.10.10" $monData]
  puts "res:$res"
  if {$res<2} {
    set gaSet(fail) "2 Ping traps did not sent"
    return -1
  }
  #file delete -force $resFile
  
  catch {exec arp.exe -d $dutIp} resArp
  puts "[MyTime] resArp:$resArp"
  
  Power $psOffOn on
  Power $psOff off
  
  Status "Wait for Dying Gasp trap"
  set dur 10
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &  
     
  after 1000
  Power $psOffOn off
  after 1000
  Power $psOffOn on
  
  after "[expr {$dur +1}]000" ; ## one more sec then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\rMonData---<$monData>---\r"; update
  
  
  ## 4479696e672067617370
  ## D y i n g   g a s p
  #set framsL [regexp -all -inline "Src: $dutIp.+?\\n\\n\\n" $monData]
  #set framsL [split $monData %]
  set framsL [wsplit $monData lIsT]
  if {[llength $framsL]==0} {
    set gaSet(fail) "No frame from $dutIp was detected"
    return -1
  }
  puts "\rDying gasp == 4479696e672067617370\r"; update
  set res 0
  foreach fram $framsL {
    puts "\rFrameA---<$fram>---\r"; update
    if {[string match "*Src: $dutIp*" $fram] && [string match *4479696e672067617370* $fram]} {
      set res 1
      #file delete -force $resFile
      break
    }
  } 
  if {$res} {
    puts "\rFrameB---<$fram>---\r"; update
  }
#   set frameQty [expr {[regexp -all "Frame " $monData] - 1}]
#   for {set fFr 1; set nextFr 2} {$fFr <= $frameQty} {incr fFr} {
#     puts "fFr:$fFr  nextFr:$nextFr"
#     if [regexp "Frame $fFr:.*\\sFrame $nextFr" $monData m] {
#       if [regexp "Src: [set dutIp].*" $m mm] {
#         if [string match *4479696e672067617370* $mm] {
#           puts $mm
#           set res 1
#         }
#       }
#     }
#     puts ""
#     
#     incr nextFr
#     if {$nextFr>$frameQty} {set nextFr 99}
#   }
# 
#   

  if {$res==1} {
    set ret 0
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}

# ***************************************************************************
# DateTime_Test
# ***************************************************************************
proc DateTime_Test {} {
  global gaSet buffer
  Status "DateTime_Test"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system\r" >system]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show system-date\r" >system]
  if {$ret!=0} {return $ret}
  
  regexp {date\s+([\d-]+)\s+([\d:]+)\s} $buffer - dutDate dutTime
  
  set dutTimeSec [clock scan $dutTime]
  set pcSec [clock seconds]
  set delta [expr abs([expr {$pcSec - $dutTimeSec}])]
  if {$delta>300} {
    set gaSet(fail) "Difference between PC and the DUT is more then 5 minutes ($delta)"
    set ret -1
  } else {
    set ret 0
  }
  
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    if {$pcDate!=$dutDate} {
      set gaSet(fail) "Date of the DUT is \"$dutDate\". Should be \"$pcDate\""
      set ret -1
    } else {
      set ret 0
    }
  }
  return $ret
}

# ***************************************************************************
# DataTransmissionSetup
# ***************************************************************************
proc DataTransmissionSetup {} {
  global gaSet
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set cf $gaSet(EthLink_UUTCF) 
  set cfTxt "$b"
      
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
    
  return $ret
}

# ***************************************************************************
# ExtClkTest
# ***************************************************************************
proc ExtClkTest {mode} {
  puts "[MyTime] ExtClkTest $mode"
  global gaSet buffer
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  
#   set ret [Send $com "configure system clock station 1/1\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "shutdown\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   Send $com "exit all\r" stam 0.25 
  
  if {$mode=="Unlocked"} {
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "show status\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set syst [set clkSrc [set state ""]]
    regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
    if {$clkSrc!="0" && $state!="Freerun"} {
      set gaSet(fail) "$syst"
      return -1
    }
  }
 
 if {$mode=="Locked"} {
    set cf $gaSet(ExtClkCF) 
    set cfTxt "EXT CLK"
    set ret [DownloadConfFile $cf $cfTxt 0 $com]
    if {$ret!=0} {return $ret}
    
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    for {set i 1} {$i<=10} {incr i} {
      set ret [Send $com "show status\r" "domain(1)"]
      if {$ret!=0} {return $ret} 
      set syst [set clkSrc [set state ""]]
      regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
      if {$clkSrc=="1" && $state=="Locked"} {
        set ret 0
        break
      } else {      
        set ret -1
        after 1000
      }
    }
    if {$ret=="-1"} {
      set gaSet(fail) "$syst"
    } elseif {$ret=="0"} {
      set ret [Send $com "no source 1\r" "domain(1)"]
      if {$ret!=0} {return $ret}
    }
  }
  return $ret
}

# ***************************************************************************
# TstAlm 
# ***************************************************************************
proc TstAlm {state} {
  global gaSet buffer
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  if {$state=="off"} { 
    set ret [Send $com "mask-minimum-severity log major\r" ">reporting"]
  } elseif {$state=="on"} { 
    set ret [Send $com "no mask-minimum-severity log\r" ">reporting"]
  } 
  return $ret
}

# ***************************************************************************
# ReadMac
# ***************************************************************************
proc ReadMac {} {
  global gaSet buffer
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Read MAC fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure system\r" ">system"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "show device-information\r" ">system"]
  if {$ret!=0} {return $ret}
  
  set mac 00-00-00-00-00-00
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  set mac2 0x$mac1
  puts "mac1:$mac1" ; update
  if {($mac2<0x0020D2500000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF )} {
    RLSound::Play fail
    set gaSet(fail) "The MAC of UUT is $mac"
    set ret [DialogBox -type "Terminate Continue" -icon /images/error -title "MAC check"\
        -text $gaSet(fail) -aspect 2000]
    if {$ret=="Terminate"} {
      return -1
    }
  }
  set gaSet(${::pair}.mac1) $mac1
  
  return 0
}
# ***************************************************************************
# ReadPortMac
# ***************************************************************************
proc ReadPortMac {port} {
  global gaSet buffer
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Read MAC of port $port fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure port\r" "port"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show status\r" "($port)"]
  if {$ret!=0} {return $ret}
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  return $mac1
}

#***************************************************************************
#**  Login
#***************************************************************************
proc Login {unit} {
  global gaSet buffer gaLocal
  set ret 0
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into ETX-2i"
  puts "Login into ETX-2i-$unit"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2I user>} 5 1]
  set com $gaSet(com$unit)
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {([string match {*-2I*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $com n\r stam 1
   append gaSet(loginBuffer) "$buffer"
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $com \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $gaSet(comUut1) exit\r\r -2I
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $com \x1F\r\r -2I
  }
  if {[string match *-2I* $buffer]} {
    set ret 0
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    return 0
  } 
  if {[string match *user* $buffer]} {
    Send $com su\r stam 0.25
    set ret [Send $com 1234\r "ETX-2I"]
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
    #set ret [Wait "Wait for ETX up" 20 white]
    #if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 64} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into ETX-2I"
    puts "Login into ETX-2I i:$i"; update
    $gaSet(runTime) configure -text $i; update
    Send $com \r stam 5
    
    append gaSet(loginBuffer) "$buffer"
    puts "<$gaSet(loginBuffer)>\n" ; update
    foreach ber $gaSet(bootErrorsL) {
      if [string match "*$ber*" $gaSet(loginBuffer)] {
       set gaSet(fail) "\'$ber\' occured during ETX's up"  
        return -1
      } else {
        puts "[MyTime] \'$ber\' was not found"
      } 
    }
    
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*-2I*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $com run\r stam 1
      append gaSet(loginBuffer) "$buffer"
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $com \x1F\r\r -2I
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      return 0
    } 
  }
  if {$ret==0} {
    if {[string match *user* $buffer]} {
      Send $com su\r stam 1
      set ret [Send $com 1234\r "-2I"]
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to ETX-2I Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# FormatFlash
# ***************************************************************************
proc FormatFlash {} {
  global gaSet buffer
  set com $gaSet(comUut1)
  
  Power all on 
  
  return $ret
}
# ***************************************************************************
# FactDefault
# ***************************************************************************
proc FactDefault {mode} {
  global gaSet buffer 
  Status "FactDefault $mode"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comUut1)
  
  
  set gaSet(fail) "Set to Default fail"
  Send $com "exit all\r" stam 0.25 
  Status "Factory Default..."
  if {$mode=="std"} {
    set ret [Send $com "admin factory-default\r" "yes/no" ]
  } elseif {$mode=="stda"} {
    set ret [Send $com "admin factory-default-all\r" "yes/no" ]
  }
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r\r" "seconds" 60]
  if {$ret!=0} {return $ret}
  
  set ret [ReadBootVersion]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait DUT down" 20 white]
  return $ret
}
# ***************************************************************************
# LicensePerf
# ***************************************************************************
proc LicensePerf {licMode} {
  global gaSet buffer 
  Status "LicensePerf $licMode"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comUut1)
  
  set gaSet(fail) "Logon fail"
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "$licMode SFPP license"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }     
  
  set sw $gaSet(dbrSW) ; # 6.2.1(0.44)
  set majSW [string range $sw 0 [expr {[string first ( $sw] - 1}]]; # 6.2.1
  puts "sw:$sw majSW:$majSW"
  
  set gaSet(fail) "$licMode 4SFPP license fail"
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "admin license\r" 2I]
  if {$ret!=0} {return $ret}
  if {$majSW<6.4} {
    if {$licMode=="Open"} {
      set ret [Send $com "license-enable four-sfp-plus-ports\r" 2I] 
    } elseif {$licMode=="Close"} {
      set ret [Send $com "no license-enable four-sfp-plus-ports\r" 2I] 
    }  
  } else {
    if {$licMode=="Open"} {
      set ret [Send $com "license-enable sfp-plus-factory-10g-rate 4\r" 2I] 
    } elseif {$licMode=="Close"} {
      set ret [Send $com "exit all\r" 2I]
      if {$ret!=0} {return $ret}
      set ret [Send $com "configure port\r" 2I]
      if {$ret!=0} {return $ret}
      foreach etPo {0/1 0/2 0/3 0/4} {
        set ret [Send $com "eth $etPo\r" 2I]
        if {$ret!=0} {return $ret}
        set ret [Send $com "speed-duplex 1000-full-duplex\r" 2I]
        if {$ret!=0} {return $ret}
        set ret [Send $com "exit\r" 2I]
        if {$ret!=0} {return $ret}
      }
      set ret [Send $com "exit all\r" 2I]
      if {$ret!=0} {return $ret}
      set ret [Send $com "admin license\r" 2I]
      if {$ret!=0} {return $ret}
      set ret [Send $com "no license-enable sfp-plus-factory-10g-rate\r" 2I] 
    }
  }
  if {$ret!=0} {return $ret}
  if {[string match {*cli error*} $buffer]} {
    set gaSet(fail) "Configuration License fail. CLI error"
    return -1
  }
  set ret [Send $com "show summary\r" 2I]
  if {$ret!=0} {return $ret}
  
  ## if the order is without SFPP - no need open them after close
  ## if the order for 2 SFPP - we will open them  them after close
  if {$licMode=="Close" && $np=="2SFPP"} {
    if {$majSW<6.4} {
      set ret [Send $com "license-enable four-sfp-plus-ports\r" 2I] 
    } else {
      set ret [Send $com "license-enable sfp-plus-factory-10g-rate 2\r" 2I] 
    }
    if {$ret!=0} {return $ret}
    set ret [Send $com "show summary\r" 2I]
    if {$ret!=0} {return $ret}
  }  
  if {$licMode=="Close"} {  
    ## and factory reset to activate the license
    set ret [FactDefault stda]
    if {$ret!=0} {return $ret}
    set ret [Login Uut1]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin license\r" 2I]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show summary\r" 2I]
    if {$ret!=0} {return $ret}
    if {$majSW<6.4} {
      set res [regexp {SFP\+ Ethernet Ports\s+(\w+)\s+([\-\d\w]+)} $buffer m stat inUse]
    } else {
      set res [regexp {SFP\+ Factory 10G Rate (\w+)\s+([\-\d]+) [\-\d]+} $buffer m stat inUse]
    }
    if {$res=="0"} {
      set gaSet(fail) "Read SFP+ Factory 10G Rate fail"
      return -1
    }
    puts "stat:<$stat> inUse:<$inUse>"  
    if {$np=="2SFPP"} {
      if {$majSW<6.4} {
        if {$stat!="Enabled" || $inUse!="No"} {
          set gaSet(fail) "Open license for 2SFP+ fail"
          return -1 
        }
      } else {
        if {$stat!="Enabled" || $inUse!="2"} {
          set gaSet(fail) "Open license for 2SFP+ fail"
          return -1 
        }  
      }
    } elseif {$np=="npo" && ($stat!="Disabled" || $inUse!="-")} {
      set gaSet(fail) "Close license for no SFP+ fail"
      return -1 
    }
  }
  
  return $ret
}
# ***************************************************************************
# ReadBootVersion
# ***************************************************************************
proc ReadBootVersion {} {
  global gaSet buffer
  puts "ReadBootVersion"
  set com $gaSet(comUut1)
  set ::buff ""
  set gaSet(uutBootVers) ""
  set ret -1
  for {set sec 1} {$sec<20} {incr sec} {
    if {$gaSet(act)==0} {return -2}
    #RLSerial::Waitfor $com buffer xxx 1
    RLCom::Waitfor $com buffer xxx 1
    puts "sec:$sec buffer:<$buffer>" ; update
    append ::buff $buffer
    if {[string match {*to view available commands*} $::buff]==1 || \
        [string match {*available commands*} $::buff]==1 || \
        [string match {*to view available*} $::buff]==1} {      
      set ret 0
      break
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "Can't read the boot"
    return $ret
  }
  set res [regexp {Boot version:\s([\d\.\(\)]+)\s} $::buff - value]
  if {$res==0} {
    set gaSet(fail) "Can't read the Boot version"
    return -1
  } else {
    set gaSet(uutBootVers) $value
    puts "gaSet(uutBootVers):$gaSet(uutBootVers)"
    set ret 0
  }
  return $ret
}
# ***************************************************************************
# ShowPS
# ***************************************************************************
proc ShowPS {ps} {
  global gaSet buffer 
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read PS-$ps status"
  set gaSet(fail) "Read PS status fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r\r" chassis]
  if {$ret!=0} {return $ret}
  if {$ps==1} {
    regexp {1\s+[AD]C\s+([\w\s]+)\s2} $buffer - val
  } elseif {$ps==2} {
    regexp {2\s+[AD]C\s+([\w\s]+)\sFAN} $buffer - val
  }
  set val [string trim $val]
  puts "ShowPS val:<$val>"
  if {[lindex [split $val " "] 0] == "HP"} {
    set val [lrange [split $val " "] 1 end] 
  }
  return $val
}
# ***************************************************************************
# Loopback
# ***************************************************************************
proc Loopback {mode} {
  global gaSet buffer 
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Set Loopback to \'$mode\'"
  set gaSet(fail) "Loopback configuration fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure port ethernet 0/1\r" (0/1)]
  if {$ret!=0} {return $ret}
  if {$mode=="off"} {
    set ret [Send $com "no loopback\r" (0/1)]
  } elseif {$mode=="on"} {
    set ret [Send $com "loopback remote\r" (0/1)]
  }
  if {$ret!=0} {return $ret}
#   Send $com "exit\r" stam 0.25 
#   set ret [Send $com "ethernet 4/2\r" (4/2)]
#   if {$ret!=0} {return $ret}
#   if {$mode=="off"} {
#     set ret [Send $com "no loopback\r" (4/2)]
#   } elseif {$mode=="on"} {
#     set ret [Send $com "loopback remote\r" (4/2)]
#   }
#   if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# DateTime_Set
# ***************************************************************************
proc DateTime_Set {} {
  global gaSet buffer
  OpenComUut
  Status "Set DateTime"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
  }
  if {$ret==0} {
    set gaSet(fail) "Logon fail"
    set com $gaSet(comUut1)
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure system\r" >system]
  }
  if {$ret==0} {
    set gaSet(fail) "Set DateTime fail"
    set ret [Send $com "date-and-time\r" "date-time"]
  }
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    set ret [Send $com "date $pcDate\r" "date-time"]
  }
  if {$ret==0} {
    set pcTime [clock format [clock seconds] -format "%H:%M"]
    set ret [Send $com "time $pcTime\r" "date-time"]
  }
  CloseComUut
  RLSound::Play information
  if {$ret==0} {
    Status Done yellow
  } else {
    Status $gaSet(fail) red
  } 
}
# ***************************************************************************
# LoadDefConf
# ***************************************************************************
proc LoadDefConf {} {
  global gaSet buffer 
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Load Default Configuration fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(defConfCF) 
  set cfTxt "DefaultConfiguration"
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "file copy running-config user-default-config\r" "yes/no" ]
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "successfull" 30]
  
  return $ret
}
# ***************************************************************************
# DdrTest
# ***************************************************************************
proc DdrTest {attm} {
  global gaSet buffer ba
  Status "DDR Test (attempt $attm)"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG (attempt $attm)"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read MEA LOG fail on attempt $attm"
  set ret [Send $com "debug mea\r\r" FPGA 11]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "mea debug log show\r" FPGA>> 60]
  if {$ret!=0} {
    set ba $buffer
    set ret [Send $com "\r\r" FPGA>> 20]
    append ba $buffer
    set buffer $ba
    if {$ret!=0} {
      return $ret
    }
  }
  
  if {($gaSet(dbrSW) == "6.7.1(0.62)" || $gaSet(dbrSW) == "6.7.1(0.53)") && [string match {*ENTU_ERROR l2cp entry was not deleted, HW failure*} $buffer]} {   
    puts "for 6.7.1(0.53) and 6.7.1(0.62) this error is allowed"
  } elseif {[string match {*ENTU_ERROR*} $buffer]} { 
    puts "ENTU_ERROR"  
    set gaSet(fail) "\'ENTU_ERROR\' exists in the MEA log (attempt $attm)"
    return -1
  }
  if {[string match {*init DDR ..........................OK*} $buffer]==0} {
    set gaSet(fail) "\'init DDR ..OK\' doesn't exist in the MEA log (attempt $attm)"
    return -1
  }
  if {[string match {*DDR NOT OK*} $buffer]==1} {
    set gaSet(fail) "\'DDR NOT OK\' exists in the MEA log (attempt $attm)"
    return -1
  }
  
  set ret [Send $com "exit\r\r\r" ETX-2I 16]
  if {$ret!=0} {
    set ret [Send $com "exit\r\r\r" ETX-2I 16]
    if {$ret!=0} {return $ret}
  }
  return $ret
}  
# ***************************************************************************
# DryContactTest
# ***************************************************************************
proc DryContactTest {} {
  global gaSet buffer
  Status "Dry Contact Test"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  RLUsbPio::SetConfig $gaSet(idDrc) 11111000 ; # 3 first bits are OUT
  RLUsbPio::Set $gaSet(idDrc) xxxxx000 ; # 3 first bits are 0 
  
  set gaSet(fail) "Read MEA HW DRY fail"
  set ret [Send $com "debug mea\r" FPGA 11]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea hw dry\r" dry>>]
  if {$ret!=0} {return $ret}
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf7"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf7\'"
    return -1
  }
  
  set ret [Send $com "read 1\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x1\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 1\' fail"
    return -1
  }
  if {$val!="0xff"} {
    set gaSet(fail) "The value of 0x1 is \'$val\'. Should be \'0xff\'"
    return -1
  }
  
  RLUsbPio::Set $gaSet(idDrc) xxxxx111 ; # 3 first bits are 1
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf0"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf0\'"
    return -1
  }
     
  set ret [Send $com "exit\r\r" ETX-2I 16]
  if {$ret!=0} {return $ret}
  return $ret
}  

# ***************************************************************************
# ShowArpTable
# ***************************************************************************
proc ShowArpTable {} {
  global gaSet buffer 
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Show ARP Table fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure router 1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show arp-table\r" (1)]
  if {$ret!=0} {return $ret}
  
  set lin1 "1.1.1.1 00-00-00-00-00-01 Dynamic"
  set lin2 "2.2.2.1 00-00-00-00-00-02 Dynamic"
   
  foreach lin [list $lin1 $lin2] {
    if {[string match *$lin* $buffer]==0} {
      set gaSet(fail) "The \'$lin\' doesn't exist"
      return -1
    }
  }

  return 0
}

# ***************************************************************************
# SoftwareDownloadTest
# ***************************************************************************
proc SoftwareDownloadTest {} {
  global gaSet buffer 
  set com $gaSet(comUut1)
  
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  # Download:   
  Status "Wait for download / writing to flash .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 820]
  if {$ret!=0} {return $ret}
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 30] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
  return $ret
} 



# ***************************************************************************
# ReadEthPortStatus
# ***************************************************************************
proc ReadEthPortStatus {unit port mode} {
  global gaSet buffer bu glSFPs
#   Status "Read EthPort Status of $port"
  set ret [Login $unit]
  if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
  }
  Status "Read EthPort Status of $port at $unit"
  set gaSet(fail) "$unit Show status of port $port fail"
  set com $gaSet(com[set unit]) 
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show status\r" ($port)]
  set bu $buffer
  if {$ret!=0} {
    set ret [Send $com "\r" ($port)]
    if {$ret!=0} {return $ret}   
    append bu $buffer
  }
  
  puts "$unit ReadEthPortStatus bu:<$bu>"
  set res [regexp {([\w\d]+) Active} $bu - val]
  if {$res==0} {
    #set gaSet(fail) "The status of port $port is not \'SFP In\'"    
    return -1
  }
  set portStat $val
  puts "portStat:<$portStat>"
  
  if {$mode=="SFP"} {
    set res [regexp { Manufacturer Part Number :\s([\w\-\s]+)Typical } $bu - val]
    if {$res==0} {
      set res [regexp { Manufacturer Part Number :\s([\w\-\s]+)SFP Manufacture Date } $bu - val]
      if {$res==0} {
        set res [regexp { Manufacturer Part Number :\s([\w\-\s]+)Manufacturer CLEI Code } $bu - val]
        if {$res==0} {
          set gaSet(fail) "$unit Read Manufacturer Part Number of SFP in port $port fail"
          return -1
        }        
      }  
    }
    set val [string trim $val]
    puts "val:<$val> glSFPs:<$glSFPs>" ; update
    if {[lsearch $glSFPs $val]=="-1"} {
      set gaSet(fail) "$unit The Manufacturer Part Number of SFP in port $port is \'$val\'"
      return -1  
    } else {
      return $portStat
    }
  }
  
  return $portStat
}

# ***************************************************************************
# AdminSave
# ***************************************************************************
proc AdminSave {} {
  global gaSet buffer
  set com $gaSet(comUut1)
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  Status "Admin Save"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "admin save\r" "successfull" 60]
  return $ret
}

# ***************************************************************************
# ShutDown
# ***************************************************************************
proc ShutDown {port state} {
  global gaSet buffer
  set com $gaSet(comUut1)
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "$state of port $port fail"
  Status "ShutDown $port \'$state\'"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r $state" "($port)"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# SpeedEthPort
# ***************************************************************************
proc SpeedEthPort {port speed} {
  global gaSet buffer
  set com $gaSet(comUut1)
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration speed of port $port fail"
  Status "SpeedEthPort $port $speed"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "speed-duplex 100-full-duplex rj45\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  return $ret
}  
# ***************************************************************************
# ReadCPLD
# ***************************************************************************
proc ReadCPLD {} {
  global gaSet buffer
  set com $gaSet(comUut1)
  Status "Read CPLD"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read CPLD"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  if ![info exists gaSet(cpld)] {
    set gaSet(cpld) 0x02; # ???
  } 
  set gaSet(fail) "Read CPLD fail"  
  set ret [Send $com "debug memory address c0100000 read char length 1\r" 2I]
  if {$ret!=0} {return $ret}
  set value ""
  set res [regexp {0xC0100000\s+(\d+)\s} $buffer - value]
  if {$res==0} {return -1}
  puts "\nReadCPLD value:<$value> gaSet(cpld):<$gaSet(cpld)>\n"; update
  if {$value!=$gaSet(cpld)} {
    set gaSet(fail) "CPLD is \'$value\'. Should be \'$gaSet(cpld)\'"  
    return -1
  }
  
  
  set ret [Send $com "debug memory address cc3e0000 read char length 1\r" 2I]
  if {$ret!=0} {return $ret}
  set value ""
  set res [regexp {0xCC3E0000\s+(\d+)\s} $buffer - value]
  if {$res==0} {return -1}
  puts "\nReadCPLD A0 value:<$value>\n"; update
  if {$value!="0x03"} {
    set gaSet(fail) "A0's CPLD is \'$value\'. Should be \'0x03\'"  
    return -1
  }
  
  set ret [Send $com "debug memory address cd3e0000 read char length 1\r" 2I]
  if {$ret!=0} {return $ret}
  set value ""
  set res [regexp {0xCD3E0000\s+(\d+)\s} $buffer - value]
  if {$res==0} {return -1}
  puts "\nReadCPLD A1 value:<$value>\n"; update
  if {$value!="0x03"} {
    set gaSet(fail) "A1's CPLD is \'$value\'. Should be \'0x03\'"  
    return -1
  }
  #set gaSet(cpld) ""
  return $ret
}
# ***************************************************************************
# Boot_Download
# ***************************************************************************
proc Boot_Download {} {
  global gaSet buffer
  set com $gaSet(comUut1)
  Status "Empty unit prompt"
  Send $com "\r\r" "=>" 2
  set ret [Send $com "\r\r" "=>" 2]
  if {$ret!=0} {
    # no:
    puts "Skip Boot Download" ; update
    set ret 0
  } else {
    # yes:   
    Status "Setup in progress ..."
    
    #dec to Hex
    set x [format %.2x $::pair]
    
    # Config Setup:
    Send $com "env set ethaddr 00:20:01:02:03:$x\r" "=>"
    Send $com "env set netmask 255.255.255.0\r" "=>"
    Send $com "env set gatewayip 10.10.10.10\r" "=>"
    Send $com "env set ipaddr 10.10.10.1[set ::pair]\r" "=>"
    Send $com "env set serverip 10.10.10.10\r" "=>"
    
    # Download Comment: download command is: run download_vxboot
    # the download file name should be always: vxboot.bin
    # else it will not work !
    if [file exists c:/download/temp/vxboot.bin] {
      file delete -force c:/download/temp/vxboot.bin
    }
    if {[file exists $gaSet(BootCF)]!=1} {
      set gaSet(fail) "The BOOT file ($gaSet(BootCF)) doesn't exist"
      return -1
    }
    file copy -force $gaSet(BootCF) c:/download/temp              
    #regsub -all {\.[\w]*} $gaSet(BootCF) "" boot_file
    
    
        
    # Download:   
    Send $com "run download_vxboot\r" stam 1
    set ret [Wait "Download Boot in progress ..." 10]
    if {$ret!=0} {return $ret}
    
    file delete -force c:/download/temp/vxboot.bin
    
    
    Send $com "\r\r" "=>" 1
    Send $com "\r\r" "=>" 3
    
    set ret [regexp {Error} $buffer]
    if {$ret==1} {
      set gaSet(fail) "Boot download fail" 
      return -1
    }  
    
    Status "Reset the unit ..."
    Send $com "reset\r" "stam" 1
    set ret [Wait "Wait for Reboot ..." 40]
    if {$ret!=0} {return $ret}
    
  }      
  return $ret
}
# ***************************************************************************
# SetDownload
# ***************************************************************************
proc neSetDownload {run} {
  set ret [SetSWDownload]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# Pages
# ***************************************************************************
proc nePages {run} {
  global gaSet buffer
  set ret [GetPageFile $gaSet($::pair.barcode1)]
  if {$ret!=0} {return $ret}
  
  set ret [WritePages]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SoftwareDownload
# ***************************************************************************
proc neSoftwareDownload {run} {
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [SoftwareDownloadTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# FormatFlashAfterBootDnl
# ***************************************************************************
proc FormatFlashAfterBootDnl {} {
  global gaSet buffer
  set com $gaSet(comUut1)
  Status "Format Flash after Boot Download"
  Send $com "\r\r" "Are you sure(y/n)?" 2
  set ret [Send $com "\r\r" "Are you sure(y/n)?" 2]
  if {$ret!=0} {
    puts "Skip Flash format" ; update
    set ret 0
  } else {
    Send $com "y\r" "\[boot\]:"
    puts "Format in progress ..." ; update
    set ret [MyWaitFor $com "boot]:" 5 900]
  }
  return $ret
}

# ***************************************************************************
# SetSWDownload
# ***************************************************************************
proc SetSWDownload {} {
  global gaSet buffer
  set com $gaSet(comUut1)
  Status "Set SW Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  if {[file exists $gaSet(SWCF)]!=1} {
    set gaSet(fail) "The SW file ($gaSet(SWCF)) doesn't exist"
    return -1
  }
     
  ## C:/download/SW/6.0.1_0.32/etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin -->> \
  ## etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 1000
  }
    
  file copy -force $gaSet(SWCF) c:/download/temp 
  
  #gaInfo(TftpIp.$::ID) = 10.10.8.1 (device IP)
  #gaInfo(PcIp) = "10.10.10.254" (gateway IP/server IP)
  #gaInfo(mask) = "255.255.248.0"  (device mask)  
  #gaSet(Apl) = C:/Apl/4.01.10sw-pack_203n.bin

  
  # Config Setup:
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    Send $com "10.10.10.1[set ::pair]\r" "device mask"
  } else {
    Send $com "10.10.10.1[set gaSet(pair)]\r" "device mask"
  }
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "\r" "(pw)" ;# vxworks

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
  }
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  }  
  
  return $ret  
}
# ***************************************************************************
# DeleteBootFiles
# ***************************************************************************
proc DeleteBootFiles {} {
  global  gaSet buffer
  set com $gaSet(comUut1)
  
  Status "Delete Boot Files"
  Send $com "dir\r" "\[boot\]:"
  set ret0 [regexp -all {No files were found} $buffer]
  set ret1 [regexp -all {sw-pack-1} $buffer]
  set ret2 [regexp -all {sw-pack-2} $buffer]
  set ret3 [regexp -all {sw-pack-3} $buffer]
  set ret4 [regexp -all {sw-pack-4} $buffer]
  set ret5 [regexp -all {factory-default-config} $buffer]
  set ret6 [regexp -all {user-default-config} $buffer]
  set ret7 [regexp {Active SW-pack is:\s*(\d+)} $buffer var ActSw]
  set ret8 [regexp -all {startup-config} $buffer]
  
  
  if {$ret7==1} {set ActSw [string trim $ActSw]}
  
  # No files were found:
  if {$ret0!=0} {
    puts "No files were found to delete" ; update
    return 0
  }
  
  foreach SwPack "1 2 3 4" {
    # Del sw-pack-X:
    if {[set ret$SwPack]!=0} {
      if {([info exist ActSw]== 1) && ($ActSw==$SwPack)} {
        # exist:  (Active SW-pack is: 1)
        Send $com "delete sw-pack-[set SwPack]\r" ".?"
        set res [Send $com "y\r" "deleted successfully" 20]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }      
      } else {
        # not exist: ("Active SW-pack isn't: X"   or  "No active SW-pac")
        set res [Send $com "delete sw-pack-[set SwPack]\r" "deleted successfully" 20]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }       
      }
      puts "sw-pack-[set SwPack] Delete" ; update
    } else {
      puts "sw-pack-[set SwPack] not found" ; update
    }
  }

  # factory-default-config:
  if {$ret5!=0} {
    set res [Send $com "delete factory-default-config\r" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "fac-def-config delete fail"
      return -1      
    } 
    puts "factory-default-config Delete" ; update      
  } else {
    puts "factory-default-config not found" ; update
  }
  
  # user-default-config:
  if {$ret6!=0} {
    set res [Send $com "delete user-default-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-def-config delete fail"
      return -1      
    } 
    puts "user-default-config Delete" ; update      
  } else {
    puts "user-default-config not found" ; update
  }
  
  # startup-config:
  if {$ret8!=0} {
    set res [Send $com "delete startup-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-str-config delete fail"
      return -1      
    } 
    puts "startup-config Delete" ; update      
  } else {
    puts "startup-config not found" ; update
  }  
    
  return 0
}
# ***************************************************************************
# FanEepromBurnTest
# ***************************************************************************
proc FanEepromBurnTest {} {
  global gaSet buffer 
  Status "Fan EEPROM Burn"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Fan EEPROM Burn"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }     
    
  set gaSet(fail) "Fan EEPROM Burn fail"
  set ret [Send $com "debug mea\r\r\r" FPGA]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "mea util fan\r" fan]
  if {$ret!=0} {return $ret} 
  foreach {reg val} {0x00 0x11 0x05 0x2D 0x20 0x00 0x21 0x00 0x22 0x00 0x23 0x00\
                     0x24 0x00 0x25 0x00 0x26 0x00 0x27 0x00 0x28 0x00 0x29 0x00\
                     0x2A 0x00 0x2B 0x00 0x2C 0x00 0x2D 0x00 0x2E 0x00 0x2F 0x00\
                     0x30 0x33 0x31 0x4C 0x32 0x66 0x33 0x80 0x34 0x99 0x35 0xB2\
                     0x36 0xCC 0x36 0xE5 0x37 0xFF 0x02 0x01 0x5B 0x1F} {
    set ret [Send $com "Write $reg $val\r" fan]
    if {$ret!=0} {return $ret}                      
  }
  return $ret
}  
  
# ***************************************************************************
# SpeedEthPort
# ***************************************************************************
proc neSpeedEthPort {port speed} {
  global gaSet buffer
  set com $gaSet(comUut1)
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configureation speed of port $port fail"
  Status "SpeedEthPort $port $speed"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "speed-duplex 100-full-duplex rj45\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  return $ret
}  
# ***************************************************************************
# Login205
# ***************************************************************************
proc Login205 {aux} {
  global gaSet buffer gaLocal
  set ret 0
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into AUX-$aux"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2I user>} 5 1]
  set com $gaSet(com$aux)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {([string match {*205A*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $com n\r stam 1
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $com \r stam 0.25
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $com exit\r\r 205A
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $com \x1F\r\r 205A
  }
  if {[string match *205A* $buffer]} {
    set ret 0
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    return 0
  } 
  if {[string match *user* $buffer]} {
    Send $com su\r stam 0.25
    set ret [Send $com 1234\r "205A"]
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
    set ret [Wait "Wait for Aux-$aux up" 20 white]
    if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 60} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into AUX-$aux"
    puts "Login into AUX-$aux i:$i"; update
    $gaSet(runTime) configure -text $i
    Send $com \r stam 5
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*205A*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $com run\r stam 1
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $com \x1F\r\r 205A
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      return 0
    } 
  }
  if {$ret==0} {
    if {[string match *user* $buffer]} {
      Send $com su\r stam 1
      set ret [Send $com 1234\r "205A"]
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to AUX-$aux Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# SyncELockClkTest
# ***************************************************************************
proc SyncELockClkTest {} {
  puts "[MyTime] SyncELockClkTest"
  global gaSet buffer
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Reading Clock's status"
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system clock\r" ">clock"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "domain 1\r" "domain(1)"]
  if {$ret!=0} {return $ret} 
  for {set i 1} {$i<=5} {incr i} {
    puts "\rattempt $i"
    set ret [Send $com "show status\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set syst [set sysQlty [set sysClkSrc [set sysState ""]]]
    regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s+Quality[\s:]+(\w+)\s} $buffer syst sysClkSrc sysState sysQlty
    #25/11/2018 10:24:30set stat [set statClkSrc [set statState ""]]
    #25/11/2018 10:23:46regexp {Station Out Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s+} $buffer stat statClkSrc statState 
    puts "sysClkSrc:<$sysClkSrc> sysState:<$sysState> sysQlty:<$sysQlty>"
    #25/11/2018 10:23:57puts "statClkSrc:<$statClkSrc> statState:<$statState>"
    update
    set fail ""
    #25/11/2018 10:25:04if {$sysClkSrc=="2" && $sysState=="Locked" && $sysQlty=="PRC" && $statClkSrc=="2" && $statState=="Locked"} {}
    if {$sysClkSrc=="1" && $sysState=="Locked" && $sysQlty=="PRC"} {
      set ret 0
      break
    } else {  
      if {$sysClkSrc!="1"} {
        append fail "System Clock Source: $sysClkSrc and not 1" , " "
      }  
      if {$sysState!="Locked"} {
        append fail "System Clock State: $sysState and not Locked" , " "
      }
      if {$sysQlty!="PRC"} {
        append fail "System Clock Quality: $sysQlty and not PRC" , " "
      }
      set ret -1
      set fail [string trimright $fail]
      set fail [string trimright $fail ,]
      after 1000
    }
  }
  if {$ret=="-1"} {
    set gaSet(fail) "$fail"
  } elseif {$ret=="0"} {
    #set ret [Send $com "no source 1\r" "domain(1)"]
    #if {$ret!=0} {return $ret}
  }
  
  return $ret
} 
# ***************************************************************************
# ForceMode
# ***************************************************************************
proc ForceMode {unit mode ports} {
  global gaSet  buffer
  Status "ForceMode $unit $mode \'$ports\'"
  set ret [Login $unit]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(com[set unit])
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    puts "beforePass [MyTime]"; update
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    puts "afterPass [MyTime]"; update
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      

  set gaSet(fail) "Activation debug test fail"
  set ret [Send $com "debug test\r" test]
  if {$ret!=0} {return $ret}

  foreach port $ports {
    set gaSet(fail) "Force port $port to mode \'$mode\' fail"
    set ret [Send $com "forced-combo-mode $port $mode\r" "test"]
    if {$ret!=0} {return $ret}
    if {[string match {*cli error*} $buffer]==1} {
      return -1
    }

    if {$gaSet(act)=="0"} {return "-2"}
  }
  return $ret
}
# ***************************************************************************
# FansTemperatureTest
# ***************************************************************************
proc FansTemperatureTest {} {
  global gaSet buffer
  Status "FansTemperatureTest"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read thermostat"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "debug thermostat\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point upper 60\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point lower 55\r" thermostat]
  if {$ret!=0} {return $ret}
  
   
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set fanState1 "off off off off"
  
  set ret [Send $com "show status\r" thermostat]
    if {$ret!=0} {return $ret}
  set res [regexp {Current:\s+([\d\.]+)\s} $buffer - fanState1]
  if {$res==0} {
    set gaSet(fail) "Read Temperature fail"
    return -1
  }
  puts "fanState1:$fanState1"
  
  set ret [Send $com "set-point lower 20\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point upper 30\r" thermostat]
  if {$ret!=0} {return $ret}
  
      
  set gaSet(fail) "Read from thermostat fail"
  for {set i 1} {$i<=40} {incr i} {
    #puts "i:$i wait for fanState2" ; update
    set ret [Send $com "show status\r" thermostat]
    if {$ret!=0} {return $ret}
    set res [regexp {Current:\s+([\d\.]+)\s} $buffer - fanState2]
    if {$res==0} {
      set gaSet(fail) "Read Temperature fail"
      return -1
    }
    puts "i:$i fanState1:$fanState1 fanState2:$fanState2" ; update
    if {$fanState1!=$fanState2} {
      set ret 0
      break
    }
    after 2000
  }
  
  if {$ret!=0} {
    set gaSet(fail) "\"Current\" doesn't change: $fanState2"
    return -1
  }
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "set-point upper 40\r" thermostat 1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point lower 32\r" thermostat 1]
  if {$ret!=0} {return $ret}
  return $ret
}

# ***************************************************************************
# NoDomainClk
# ***************************************************************************
proc NoDomainClk {} {
  global gaSet buffer
  Status "No Domain Clk"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "No Domain Clk fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "con sys clock do 1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no source 1\r" (1)]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# SetDomainClk
# ***************************************************************************
proc SetDomainClk {} {
  global gaSet buffer
  Status "Set Domain Clk"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Set Domain Clk fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "con sys clock do 1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "source 1 rx-port ethernet 0/1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "quality-level prc\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "wait	0\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "clear\r" (1)]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# MaskMin
# ***************************************************************************
proc MaskMin {mode} {
  global gaSet buffer 
  Status "MaskMin $mode"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comUut1)
  
  set gaSet(fail) "Set Mask-Minimum to $mode fail"
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure reporting\r" report] 
  if {$ret!=0} {return $ret}
  if {$mode=="set"} {
    set ret [Send $com "mask-minimum-severity log major\r" report] 
  } elseif {$mode=="unset"} {
    set ret [Send $com "no mask-minimum-severity log\r" report] 
  }  
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# SetU74_appDownload
# ***************************************************************************
proc SetU74_appDownload {} {
  global gaSet buffer 
  if {$gaSet(abd) == "B"} {return 0}
  set com $gaSet(comUut1)
  Status "Set U74_app Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  set ret [PrepareDwnlJatPll]
  if {$ret=="-1"} {return $ret}
  set tail $ret
  
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    set ip 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set ip 10.10.10.111
    } else {
      set ip 10.10.10.1[set gaSet(pair)]
    }  
  }
  Send $com "$ip\r" "device mask"
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "\r" "(pw)" ;# vxworks

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
  }
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  }

  Status "Wait for download / writing to flash .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 820]
  if {$ret!=0} {return $ret}
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 30] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 2000
    if [file exists c:/download/temp/$tail] {
      if [catch {file delete -force c:/download/temp/$tail}] {
         set gaSet(fail) "The SW file ($SWCF) can't be deleted"
         return -1
      }
    
    }
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
  return $ret     
}

# ***************************************************************************
# Load_U74_app_Perf
# ***************************************************************************
proc Load_U74_app_Perf {} {
  global gaSet gaGui buffer 
  if {$gaSet(abd) == "B"} {return 0}
  set com $gaSet(comUut1)
  Status "Loading U74_app"
  
  set ret [Login  Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
    
  set gaSet(fail) "Logon fail"
  Send $com "exit all\r" stam 0.25 
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  Send $com "logon\r" stam 0.25 
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" "-2I" 1]
    if {$ret!=0} {return $ret}
  }     
 
  set gaSet(fail) "Load_U74_app_Perf Test fail"
  set ret [Send $com "debug mea\r\r\r" FPGA]
  if {$ret!=0} {
    set ret [Send $com "debug mea\r\r\r" FPGA]
    if {$ret!=0} {return $ret}
  } 
    
  #if {$gaSet(enJat)==1} {}
  set gaSet(fail) "Load U47_app fail"
  set ret [Send $com "mea util jat\r" "jat"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show\r" "jat"]
  if {$ret!=0} {return $ret}
  set res [regexp {banks[\.\s]+(\d)\s} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read JAT show fail"
    return -1
  }
  puts "Load_U47_app_Perf ma:{$ma} value:{$value}"
  
  if {$value==0} {
    set gaSet(fail) "No empty JAT user banks"
    return -1
  }
  set ret [Send $com "load\r" "y/n"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "Programming succeeded" 20]
  if {$ret!=0} {return $ret}
  set ret [Send $com "top\r" "FPGA"]
  if {$ret!=0} {return $ret}
    
  return $ret  
}

