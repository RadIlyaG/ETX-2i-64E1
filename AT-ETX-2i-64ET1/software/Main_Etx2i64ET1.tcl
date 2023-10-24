# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName)\n"
  
  RetriveDutFam 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set lTestsAllTests [list]
  set lDownloadTests [list BootDownload SetDownload Pages SoftwareDownload]
  eval lappend lTestsAllTests $lDownloadTests
  
  lappend lTestNames SetToDefault
   
  lappend lTestNames ID 
  lappend lTestNames E1_Ethernet_conf E1_Ethernet_SFP E1_UTP Ethernet_UTP ; #Ethernet_Link_SFP
  lappend lTestNames SyncE_conf
  lappend lTestNames SyncE_Slave_run
  lappend lTestNames SyncE_Master_run
  lappend lTestNames DyingGasp_conf DyingGasp_run
  lappend lTestNames SetToDefault ; # 08:39 24/10/2023 DDR
  lappend lTestNames Leds
  lappend lTestNames Mac_BarCode
  
  eval lappend lTestsAllTests $lTestNames
  
  set glTests ""
  set gaSet(TestMode) AllTests
  set lTests [set lTests$gaSet(TestMode)]
  
#   if {$gaSet(defConfEn)=="1"} {
#     lappend lTests LoadDefaultConfiguration
#   }
  
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
}
# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* DUT start *********..[MyTime].."
  Status "DUT start"
  set gaSet(curTest) ""
  update
    
#   AddToLog "********* DUT start *********"
  AddToPairLog $gaSet(pair) "********* DUT start *********"
#   if {$gaSet(dutBox)!="DNFV"} {
#     AddToLog "$gaSet(1.barcode1)"
#   }     
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    
    MuxMngIO ioToGenMngToPc ioToIo
      
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
#     AddToLog "Test \'$testName\' started"
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]
    if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode" && $testName!="ID" && $testName!="Leds"} {
#     set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
#     puts $logFileID "**** Test $numberedTest fail and rechecked. Reason: $gaSet(fail); [MyTime]"
#     close $logFileID
#     puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#     $gaSet(startTime) configure -text "$startTime .."
      
#     set ret [$testName 2]
    }
    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
#     AddToLog "Test \'$testName\' $retTxt"
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }

  AddToPairLog $gaSet(pair) "WS: $::wastedSecs"

  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
  return $ret
}

# ***************************************************************************
# USBport
# ***************************************************************************
proc USBport {run} {
  global gaSet
  set ret 0
   ### 13/07/2016 15:06:43 6.0.1 reads the USB port without a special app
  
  set ret [CheckUsbPort]
  if {$ret!=0} {return $ret}
  
#   set ret [EntryBootMenu]
#   if {$ret!=0} {return $ret}
#   
#   set ret [DeleteUsbPortApp]
#   if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# PS_ID
# ***************************************************************************
proc ID {run} {
  global gaSet
  Power all on
  set ret [PS_IDTest]
  return $ret
}

# ***************************************************************************
# SFPPlic
# ***************************************************************************
proc SFPPlic {run} {
  global gaSet
  Power all on
  set ret [SFPPlicTest]
  return $ret
}

# ***************************************************************************
# DyingGasp_conf
# ***************************************************************************
proc DyingGasp_conf {run} {
  global gaSet  buffer gRelayState
  Power all on
  Status "DyingGasp_conf"
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set ret [FactDefault std]
  if {$ret!=0} {return $ret}
  
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
  
  Power all off
  after 2000
  Power all on
  
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  ##set ret [DyingGaspSetup]
  return $ret
}
# ***************************************************************************
# DyingGasp_run
# ***************************************************************************
proc DyingGasp_run {run} {
  global gaSet
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  MuxMngIO ioToPc ioToIo
  
  set ret [SpeedEthPort 0/1 100]
  if {$ret!=0} {return $ret}  
  
  set ret [ForceMode Uut1 rj45 "6"]
  if {$ret!=0} {return $ret}
  Wait "Wait for RJ45 mode" 5
  
  set portsL [list 0/6]
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut1 $port RJ45]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="RJ45"} {
      set gaSet(fail) "Uut1 The $ret in port $port is active instead of RJ45"
      return -1
    }
  }
  
  set ret [Wait "Wait Port 0/1 up" 140 white]
  if {$ret!=0} {return $ret}
  
  set ret [DyingGaspPerf 1 2]
  if {$ret!=0} {return $ret}
  
  Power all on
  set ret [Wait "Wait for ETX up" 20 white]
  if {$ret!=0} {return $ret}
  
#   set ret [FactDefault std]
#   if {$ret!=0} {return $ret}
  
  MuxMngIO ioToGenMngToPc ioToIo
  
  return $ret
}



# ***************************************************************************
# DateTime
# ***************************************************************************
proc DateTime {run} {
  global gaSet
  Power all on
  set ret [DateTime_Test]
  return $ret
} 

# ***************************************************************************
# E1_Ethernet_conf
# ***************************************************************************
proc E1_Ethernet_conf {run} {
  global gaSet
  Power all on    
  set ret [DataTransmissionSetup]
  return $ret
} 

# ***************************************************************************
# SFP_ID
# ***************************************************************************
proc SFP_ID {run} {
  global gaSet glSFPs 
  
  set glSFPs [list]
  set id [open sfpList.txt r]
    while {[gets $id line]>=0} {
      lappend glSFPs $line
    }
  close $id
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
 
 set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set portsL [list 0/1 0/2 0/3 0/4 0/5 0/6]    
  
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut1 $port SFP]
    if {$ret!="0"} {return $ret}
  }
  return $ret
}  

# ***************************************************************************
# E1_Ethernet_SFP
# ***************************************************************************
proc E1_Ethernet_SFP {run} {
  global gaSet gRelayState
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  Power all on
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  #set ret [Wait "Wait for ETX up" 30]
  #if {$ret!=0} {return $ret}
  
  set ret [ForceMode Uut1 sfp "1 2 3 4 5 6"]
  if {$ret!=0} {return $ret}
  set ret [ForceMode Uut2 sfp "1"]
  if {$ret!=0} {return $ret}
  Wait "Wait for SFP mode" 5; #15
  
  set portsL [list 0/1 0/2 0/3 0/4 0/5 0/6]
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut1 $port SFP]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="SFP"} {
      set gaSet(fail) "Uut1 The $ret in port $port is active instead of SFP"
      return -1
    }
  }
  
  set portsL [list 0/1]
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut2 $port SFP]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="SFP"} {
      set gaSet(fail) "Uut2 The $ret in port $port is active instead of SFP"
      return -1
    }
  }
  
  set ret [DataTransmissionTestPerf 10 E1 2]  
  if {$ret!=0} {
    set ret [DataTransmissionTestPerf 10 E1 2]  
    if {$ret!=0} {return $ret} 
  } 
  
  set ret [DataTransmissionTestPerf 120 E1 2]  
  if {$ret!=0} {return $ret}
  
  return $ret 
}

# ***************************************************************************
# E1_UTP
# ***************************************************************************
proc E1_UTP {run} {
  global gaSet gRelayState
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
#   Power all off
#   RLSound::Play information
#   set res [DialogBox -text "remove sfp and insert utp" -type "Continue Abort"]
#   if {$res=="Abort"} {
#     return -2
#   }
  #set ret [ForceMode $b rj45 6]
  set ret [ForceMode Uut1 rj45 1]
  if {$ret!=0} {return $ret}
  set ret [ForceMode Uut2 rj45 1]
  if {$ret!=0} {return $ret}
  Wait "Wait for RJ45 mode" 5; #15
  
  set portsL [list 0/1] ; # 0/2 0/3 0/4 0/5 0/6
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut1 $port RJ45]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="RJ45"} {
      set gaSet(fail) "Uut1 The $ret in port $port is active instead of RJ45"
      return -1
    }
  }
  
  set portsL [list 0/1] ; # 0/2 0/3 0/4 0/5 0/6
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut2 $port RJ45]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="RJ45"} {
      set gaSet(fail) "Uut2 The $ret in port $port is active instead of RJ45"
      return -1
    }
  }

#   after 1000
#   Power all on
#   set ret [Login Uut1]
#   if {$ret!=0} {return $ret}
  
#   set ret [NoDomainClk]
#   if {$ret!=0} {return $ret}
  set ret [Wait "Wait for ETX up" 30]
  if {$ret!=0} {return $ret}
  
  set ret [DataTransmissionTestPerf 10 E1 NA]  
  if {$ret!=0} {
    set ret [DataTransmissionTestPerf 10 E1 NA]  
    if {$ret!=0} {return $ret} 
  } 
  
  set ret [DataTransmissionTestPerf 120 E1 NA]  
  if {$ret!=0} {return $ret}
  
  if {$ret!=0} {
#     set ret [DataTransmissionTestPerf 10]  
#     if {$ret!=0} {return $ret}
#     
#     set ret [DataTransmissionTestPerf 120]  
#     if {$ret!=0} {return $ret}
  } 
  return $ret
}

# ***************************************************************************
# Ethernet_UTP
# ***************************************************************************
proc Ethernet_UTP {run} {
  global gaSet gRelayState
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
#   Power all off
#   RLSound::Play information
#   set res [DialogBox -text "remove sfp and insert utp" -type "Continue Abort"]
#   if {$res=="Abort"} {
#     return -2
#   }
  set ret [ForceMode Uut1 rj45 "2 3 4 5 6"]
  if {$ret!=0} {return $ret}
  set ret [ForceMode Uut2 rj45 "2 3 4 5 6"]
  if {$ret!=0} {return $ret}
  Wait "Wait for RJ45 mode" 5; #15
  set portsL [list 0/2 0/3 0/4 0/5 0/6]
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut1 $port RJ45]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="RJ45"} {
      set gaSet(fail) "The $ret in port $port is active instead of RJ45"
      return -1
    }
  }    

#   after 1000
#   Power all on
#   set ret [Login Uut1]
#   if {$ret!=0} {return $ret}
  
  set ret [NoDomainClk]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait for ETX up" 30]
  if {$ret!=0} {return $ret}
  
  set ret [DataTransmissionTestPerf 10 NA 1]  
  if {$ret!=0} {
    set ret [DataTransmissionTestPerf 10 NA 1]  
    if {$ret!=0} {return $ret} 
  } 
  
  set ret [DataTransmissionTestPerf 120 NA 1]  
  if {$ret!=0} {return $ret}
  
  if {$ret!=0} {
#     set ret [DataTransmissionTestPerf 10]  
#     if {$ret!=0} {return $ret}
#     
#     set ret [DataTransmissionTestPerf 120]  
#     if {$ret!=0} {return $ret}
  } 
  return $ret
}

# ***************************************************************************
# E1
# ***************************************************************************
proc _E1 {run} {
  global gaSet gRelayState
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  Power all on
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait for ETX up" 50]
  if {$ret!=0} {return $ret}
  set ret [DataTransmissionTestPerf 10 E1]  
  if {$ret!=0} {
    set ret [DataTransmissionTestPerf 10 E1]  
    if {$ret!=0} {return $ret} 
  } 
  
  set ret [DataTransmissionTestPerf 120 E1]  
  if {$ret!=0} {return $ret}
  
  return $ret 
}  

# ***************************************************************************
# Ethernet_Link_UTP
# ***************************************************************************
proc _Ethernet_Link_UTP {run} {
  global gaSet gRelayState
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
#   Power all off
#   RLSound::Play information
#   set res [DialogBox -text "remove sfp and insert utp" -type "Continue Abort"]
#   if {$res=="Abort"} {
#     return -2
#   }
#   set ret [ForceMode $b rj45 6]
#   if {$ret!=0} {return $ret}
#   Wait "Wait for RJ45 mode" 5; #15
   set portsL [list 0/1 0/2 0/3 0/4 0/5 0/6]
   foreach port $portsL {
     set ret [ReadEthPortStatus $port RJ45]
     if {$ret=="-1" || $ret=="-2"} {return $ret}
     if {$ret!="RJ45"} {
       set gaSet(fail) "The $ret in port $port is active instead of RJ45"
       return -1
     }
   }

  
  
  after 1000
  Power all on
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  
  set ret [NoDomainClk]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait for ETX up" 30]
  if {$ret!=0} {return $ret}
  
  set ret [DataTransmissionTestPerf 10 1]  
  if {$ret!=0} {
    set ret [DataTransmissionTestPerf 10 1]  
    if {$ret!=0} {return $ret} 
  } 
  
  set ret [DataTransmissionTestPerf 120 1]  
  if {$ret!=0} {return $ret}
  
  if {$ret!=0} {
#     set ret [DataTransmissionTestPerf 10]  
#     if {$ret!=0} {return $ret}
#     
#     set ret [DataTransmissionTestPerf 120]  
#     if {$ret!=0} {return $ret}
  } 
  return $ret
}
# ***************************************************************************
# Ethernet_Link_SFP
# ***************************************************************************
proc _Ethernet_Link_SFP {run} {
  global gaSet gRelayState
  
  Power all off
  RLSound::Play information 
  set res [DialogBox -text "Remove utp cables, except io1, and insert SFP" -type "Continue Abort"]
  if {$res=="Abort"} {
    return -2
  }
 
  after 1000
  Power all on
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait for ETX up" 30]
  if {$ret!=0} {return $ret}
  set portsL [list 0/1]
  foreach port $portsL {
#     set ret [ReadEthPortStatus $port RJ45]
#     if {$ret=="-1" || $ret=="-2"} {return $ret}
#     if {$ret!="RJ45"} {
#       set gaSet(fail) "The $ret in port $port is active instead of RJ45"
#       return -1
#     }
  }
  set portsL [list 0/2 0/3 0/4 0/5 0/6]
  foreach port $portsL {
#     set ret [ReadEthPortStatus $port SFP]
#     if {$ret=="-1" || $ret=="-2"} {return $ret}
#     if {$ret!="SFP"} {
#       set gaSet(fail) "The $ret in port $port is active instead of SFP"
#       return -1
#     }
  }
  
  
  set ret [DataTransmissionTestPerf 10 2]  
  if {$ret!=0} {
    set ret [DataTransmissionTestPerf 10 2]  
    if {$ret!=0} {return $ret} 
  } 
  
  set ret [DataTransmissionTestPerf 120 2]  
  if {$ret!=0} {
#     set ret [DataTransmissionTestPerf 10]  
#     if {$ret!=0} {return $ret}
#     
#     set ret [DataTransmissionTestPerf 120]  
#     if {$ret!=0} {return $ret}
  } 
  return $ret
}
# ***************************************************************************
# DataTransmissionTestPerf
# ***************************************************************************
proc DataTransmissionTestPerf {checkTime e1Port ethPort} {
  global gaSet
  Power all on 
  
  puts "[MyTime] DataTransmissionTestPerf $checkTime $e1Port $ethPort" ; update
  
  set ret [Wait "Waiting for stabilization" 10 white]
  if {$ret!=0} {return $ret}
  
  if {$e1Port!="NA"} {
    Dxc4Start
  }
  if {$ethPort!="NA"} {
    Etx204Start
  }  
  
  set ret [Wait "Data is running" $checkTime white]
  if {$ret!=0} {return $ret}
  if {$e1Port!="NA"} {    
    set retE1 [Dxc4Check]
  } else {
    set retE1 0
  }
  if {$ethPort!="NA"} {
    set retEth [Etx204Check $ethPort]    
  } else {
    set retEth 0 
  }
  
  puts "[MyTime] 1. retEth=$retEth  retE1=$retE1"
  
  if {$retEth!=0 || $retE1!=0} {
    set ret -1
  } else {
    set ret 0
  }
 
  return $ret
}  
# ***************************************************************************
# ExtClkUnlocked 
# ***************************************************************************
# proc ExtClkUnlocked {run} {
#   global gaSet
#   Power all on
#   set ret [ExtClkTest Unlocked]
#   return $ret
# }
# ***************************************************************************
# ExtClkLocked
# ***************************************************************************
# proc ExtClkLocked {run} {
#   global gaSet
#   Power all on
#   set ret [ExtClkTest Locked]
#   return $ret
#}
# ***************************************************************************
# ExtClk
# ***************************************************************************
proc ExtClk {run} {
  global gaSet
  Power all on
  set ret [ExtClkTest Unlocked]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Locked]
  return $ret
}
# ***************************************************************************
# Leds_FAN_conf
# ***************************************************************************
proc Leds_FAN_conf {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
   set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
  set cf C:/AT-ETX-2i-10G/ConfFiles/mng_5.9.1.txt
  set cfTxt "MNG port"
  set ret [DownloadConfFile $cf $cfTxt 0 $com]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set cf $gaSet([set b]CF) 
  set cfTxt "$b"    
  set ret [DownloadConfFile $cf $cfTxt 0 $com]
  if {$ret!=0} {return $ret}
  
  set ret [RL10GbGen::Init $gaSet(id220)]  
  if {$ret!=0} {
    set gaSet(fail) "Init GENERATOR fail"
    return $ret
  } 
  
  switch -exact -- $b {
    19 {
      set 10GlineRate 50%
      set 1GlineRate  50%
    }
    Half19 {
      set 10GlineRate 90%
      set 1GlineRate  100%
    }
  }
  Status "Config GENERATOR"
  
  Etx220Config 1 $10GlineRate
  Etx220Config 5 $1GlineRate
  
  Etx220Start 1
  Etx220Start 5
  
  return $ret
}
# ***************************************************************************
# Leds
# ***************************************************************************
proc Leds_FAN {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}

  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2I" "Manual Test"
  
  catch {set pingId [exec ping.exe 10.10.10.1[set gaSet(pair)] -t &]}
  
  set txt "1. Check 0.95V\n"
  RLSound::Play information
  set txt1 "2. Verify that:\n\
  GREEN \'PWR\' led is ON\n\
  ORANGE \'TST/ALM\' led is ON\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON and Blinking respectively\n"
  
  set txt2_19 "On each PS GREEN \'PWR\' led is ON\n"
  set txt2_9 "" ; #"On PS GREEN \'PWR\' led is ON\n"
  
  set txt3 "GREEN \'LINK\' leds of 10GbE ports are ON and ORANGE \'ACT\' leds are Blinking\n\
  GREEN \'LINK/ACT\' leds of 1GbE ports are Blinking\n\
  EXT CLK's GREEN \'SD\' led is ON (if exists)\n\
  FAN rotates"
  
  append txt $txt1
  if {$b=="19"} {
    append txt ${txt2_19}
  } elseif {$b=="Half19"} {
    append txt ${txt2_9}
  } 
  append txt $txt3
  
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
  update
  
  catch {exec pskill.exe -t $pingId}
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  #set ret [Loopback off]
  #if {$ret!=0} {return $ret} 
  
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
#   set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 
  
  if {$b=="19"} {
    foreach ps {2 1} {
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
      RLSound::Play information
      set txt "Verify on PS-$ps that RED led is ON"
      set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        return -1
      } else {
        set ret 0
      }
      
      RLSound::Play information
      set txt "Remove PS-$ps and verify that led is OFF"
      set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "PS_ID Test failed"
        return -1
      } else {
        set ret 0
      }
      
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="Not exist"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
  #       AddToLog $gaSet(fail)
        return -1
      }
      
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
      
      RLSound::Play information
      set txt "Assemble PS-$ps"
      set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "PS_ID Test failed"
        return -1
      } else {
        set ret 0
      }
      Power $ps on
      after 2000
    }
  }
  
#   RLSound::Play information
#   set txt "Verify EXT CLK's GREEN SD led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  
  if {$p=="P"} {
    RLSound::Play information
    set txt "Remove the EXT CLK cable and verify the SD led is OFF"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "LED Test failed"
      return -1
    } else {
      set ret 0
    }
  }
 
#   set ret [TstAlm off]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is OFF"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  RLSound::Play information
  set txt "Disconnect all cables and optic fibers and verify GREEN leds are OFF"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
#   set ret [TstAlm on]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  
  return $ret
}
# ***************************************************************************
# Leds
# ***************************************************************************
proc Leds {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set ret [ForceMode Uut2 sfp "1"]
  if {$ret!=0} {return $ret}
  
  set ret [ReadMac]
  if {$ret!=0} {return $ret}
  
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2I" "Manual Test"
  
  
  RLSound::Play information
  set txt "Verify that:\n\
  GREEN \'PWR\' led is ON\n\
  RED \'TST/ALM\' led is ON\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON and Blinking respectively\n\
  GREEN \'LINK/ACT\' leds of 1GbE ports are ON or Blinking\n\
  On each PS GREEN \'PWR\' led is ON\n\
  FANs rotate"
  
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
  update    
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
  if 1 {  
    foreach ps {2 1} {
      Power $ps off
      RLSound::Play information
      set txt "Verify on PS-$ps that RED led is ON"
      set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        return -1
      } else {
        set ret 0
      }
      
      RLSound::Play information
      set txt "Remove PS-$ps and verify that led is OFF"
      set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "PS_ID Test failed"
        return -1
      } else {
        set ret 0
      }
      
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="Not exist"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
  #       AddToLog $gaSet(fail)
        return -1
      }
      
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
      
      RLSound::Play information
      set txt "Assemble PS-$ps"
      set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "PS_ID Test failed"
        return -1
      } else {
        set ret 0
      }
      Power $ps on
      after 2000
    }
 
  }
#   set ret [TstAlm off]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is OFF"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  RLSound::Play information
  set txt "Press OK and verify 2*64 RED LOC and REM leds are ON"    
  #set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  set res [DialogBox -type "OK Stop" -icon /images/information -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "User stop"
    return -2
  } else {
    set ret 0
  }
  
  Power all off
  after 1000
  Power all on
  
  RLSound::Play information
  set txt "Did all the leds were ON?"    
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
#   set ret [TstAlm on]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  
  return $ret
}
# ***************************************************************************
# SetToDefault
# ***************************************************************************
proc SetToDefault {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# OpenLicense
# ***************************************************************************
proc OpenLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [LicensePerf Open]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefault_CloseLicense
# ***************************************************************************
proc SetToDefault_CloseLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda Close]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# CloseLicense
# ***************************************************************************
proc CloseLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [LicensePerf Close]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  global gaSet  
  set pair $::pair 
  puts "Mac_BarCode \"$pair\" "
  mparray gaSet *mac* ; update
  mparray gaSet *barcode* ; update
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [ReadMac]
      if {$ret!=0} {return $ret}
    }  
  } 
  foreach unit {1} {
    if {![info exists gaSet($pair.barcode$unit)] || $gaSet($pair.barcode$unit)=="skipped"}  {
      set ret [ReadBarcode]
      if {$ret!=0} {return $ret}
    }  
  }
  #set ret [ReadBarcode [PairsToTest]]
#   set ret [ReadBarcode]
#   if {$ret!=0} {return $ret}
  set ret [RegBC]
      
  return $ret
}

# ***************************************************************************
# LoadDefaultConfiguration
# ***************************************************************************
proc LoadDefaultConfiguration {run} {
  global gaSet  
  Power all on
  set ret [LoadDefConf]
  return $ret
}
 

# ***************************************************************************
# MacSwID
# ***************************************************************************
proc MacSwID {run} {
   set ret [MacSwIDTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DDR
# ***************************************************************************
proc DDR {run} {
  global gaSet
  Power all on
  set ret [DdrTest 1]
  return $ret
}
# ***************************************************************************
# DDR_single
# ***************************************************************************
proc DDR_single {run} {
  global gaSet
  Power all on
  set ret [DdrTest 1]
  return $ret
}
# ***************************************************************************
# DDR_multi
# ***************************************************************************
proc DDR_multi {run} {
  global gaSet
  Power all on
  for {set i 1} {$i<=$gaSet(ddrMultyQty)} {incr i} {
    set ret [DdrTest $i]
    if {$ret!=0} {break}
    Power all off
    after 2000
    Power all on
  }  
  return $ret
}
# ***************************************************************************
# BootDownload
# ***************************************************************************
proc BootDownload {run} {
  set ret [Boot_Download]
  if {$ret!=0} {return $ret}
  
  set ret [FormatFlashAfterBootDnl]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# SetDownload
# ***************************************************************************
proc SetDownload {run} {
  set ret [SetSWDownload]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# Pages
# ***************************************************************************
proc Pages {run} {
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
proc SoftwareDownload {run} {
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [SoftwareDownloadTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# FanEepromBurn
# ***************************************************************************
proc FanEepromBurn {run} {
  set ret [FanEepromBurnTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}  
# ***************************************************************************
# SyncE_conf
# ***************************************************************************
proc SyncE_conf {run} {
  global gaSet
  Power all on    
  MuxMngIO nc slave
  set ret [Login Uut1]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comUut1)
  Send $com "exit all\r" stam 0.25 
 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set ret [ForceMode Uut1 rj45 "1 6"]
  if {$ret!=0} {return $ret}
  set ret [ForceMode Uut2 rj45 1]
  if {$ret!=0} {return $ret}
  Wait "Wait for RJ45 mode" 5; #15
  
  set portsL [list 0/1] ; # 0/2 0/3 0/4 0/5 0/6
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut1 $port RJ45]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="RJ45"} {
      set gaSet(fail) "Uut1 The $ret in port $port is active instead of RJ45"
      return -1
    }
  }
  
  set portsL [list 0/1] ; # 0/2 0/3 0/4 0/5 0/6
  foreach port $portsL {
    set ret [ReadEthPortStatus Uut2 $port RJ45]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret!="RJ45"} {
      set gaSet(fail) "Uut2 The $ret in port $port is active instead of RJ45"
      return -1
    }
  }
  set ret 0
  
#   set cf $gaSet([set b]SyncECF) 
#   set cfTxt "$b"
#       
#   set ret [DownloadConfFile $cf $cfTxt 1 $com]
#   if {$ret!=0} {return $ret}
#   
#   MuxMngIO ioToCnt ioToIo
    
  return $ret
} 

# ***************************************************************************
# SyncE_run       
# ***************************************************************************
proc SyncE_Slave_run {run} {
  global gaSet
  Power all on  
  MuxMngIO nc slave
  after 2000  
  set ret [SyncE_run man]
  puts "ret SyncE_run slave: <$ret>"
  return $ret
}
# ***************************************************************************
# SyncE_Master_run
# ***************************************************************************
proc SyncE_Master_run {run} {
  global gaSet
  Power all on  
  MuxMngIO ioToCnt master
  after 2000  
  set ret [SyncE_run auto]
  puts "ret SyncE_run master: <$ret>"
  return $ret
}


# ***************************************************************************
# SyncE_run
# ***************************************************************************
proc SyncE_run {mode} {
  global gaSet
  Status "SyncE_run $mode"
  Power all on  
#   MuxMngIO nc slave
#   after 2000
  
  set ret [SetDomainClk]
  if {$ret!=0} {return $ret}
  
  set ret [SyncELockClkTest] 
  if {$ret!=0} {return $ret}
  
  set ret [GpibOpen]
  if {$ret!=0} {
    set gaSet(fail) "No communication with Scope"
    return $ret
  }
  
  set ret [ExistTds520B]
  if {$ret!=0} {return $ret}
  
  DefaultTds520b
  ##ClearTds520b
  after 2000
  SetLockClkTds
    
  if {$mode=="auto"} {
    after 3000
    set ret [ChkLockClkTds]
    if {$ret!=0} {
      GpibClose
      return $ret
    }
  }  
  
  set ret [SyncELockClkTest]
  if {$ret!=0} {
    GpibClose
    return $ret
  }
  
  if {$mode=="auto"} {   
    set ret [CheckJitter 100]
    GpibClose
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    if {$ret>30} {
      set gaSet(fail) "Jitter: $ret nSec, should not exceed 30 nSec"
      set ret -1
    } else {
      set ret 0
    }
  } elseif {$mode=="man"} {
    RLSound::Play information
    set txt "Verify no jitter (wander) between CH-1 and CH-2 of scope (Still image)"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "Sync-E Slave Clock Test" -message $txt]
    if {$res=="OK"} {
      set ret 0
    } else {
      set gaSet(fail) "Sync-E Slave Clock Test fail"
      return -1 
    }
  }
  
  if {$ret==0} {
    set ret [DataTransmissionTestPerf 10 E1 NA]  
    if {$ret!=0} {
      set ret [DataTransmissionTestPerf 10 E1 NA]  
    if {$ret!=0} {return $ret} 
    } 
    
    set ret [DataTransmissionTestPerf 120 E1 NA]  
    if {$ret!=0} {return $ret}
  }
     
  return $ret
} 

# ***************************************************************************
# FansTemperature
# ***************************************************************************
proc FansTemperature {run} {
  global gaSet
  Power all on
  set ret [FansTemperatureTest]
  return $ret
}

# ***************************************************************************
# TstAlmLed
# ***************************************************************************
proc TstAlmLed {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}

  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2I" "Manual Test"
  
  set ret [MaskMin set] 
  if {$ret!=0} {return $ret}
  RLSound::Play information
  set txt "Verify that TST/ALM led is off"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "TST/ALM Led Test" -message $txt]
  if {$res!="OK"} {
    set gaSet(fail) "TST/ALM led Test failed"
    return -1
  } else {
    set ret 0
  }
  
  set ret [MaskMin unset] 
  if {$ret!=0} {return $ret}
  RLSound::Play information
  set txt "Verify that TST/ALM led lights (red)"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "TST/ALM Led Test" -message $txt]
  if {$res!="OK"} {
    set gaSet(fail) "TST/ALM led Test failed"
    return -1
  } else {
    set ret 0
  }
  return $ret
}  