##***************************************************************************
##** OpenRL
##***************************************************************************
proc OpenRL {} {
  global gaSet
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  
  RLEH::Open
  
  puts "Open PIO [MyTime]"
  set ret [OpenPio]
  set ret1 [OpenComUut]
  #set ret3 [OpenComAux] DyingGasp
  if {[string match {*Mac_BarCode*} $gaSet(startFrom)] || [string match {*Leds*} $gaSet(startFrom)] ||\
      [string match {*Memory*} $gaSet(startFrom)]      || [string match {*License*} $gaSet(startFrom)] ||\
      [string match {*FactorySet*} $gaSet(startFrom)]  || [string match {*SaveUserFile*} $gaSet(startFrom)] ||\
      [string match {*SetToDefaultAll*} $gaSet(startFrom)] || [string match {*DyingGasp*} $gaSet(startFrom)] ||\
      [string match {*DDR*} $gaSet(startFrom)]} {
    set openGens 0  
  } else {
    set openGens 1
  } 
  if {$openGens==1} {  
    Status "Open ETH GENERATOR"
    set ret2 0
    set ret2 [OpenEtxGen]
    #InitEtxGen 1
    Status "Open E1 GENERATORs"
    set ret3 [OpenDxc4]    
  } else {
    set ret2 0
    set ret3 0
  }  
   
  
  set gaSet(curTest) $curTest
  puts "[MyTime] ret:$ret ret1:$ret1 ret2:$ret2 ret3:$ret3 " ; update
  if {$ret1!=0 || $ret2!=0 || $ret3!=0} {
    set gaSet(fail) "Open RL fail"
    return -1
  }
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  #set ret [RLSerial::Open $gaSet(comUut1) 9600 n 8 1]
  set ret [RLCom::Open $gaSet(comUut1) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comUut1) fail"
  }
  set ret [RLCom::Open $gaSet(comUut2) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comUut2) fail"
  }
#   set ret [RLSerial::Open $gaSet(comUut2) 9600 n 8 1]
#   if {$ret!=0} {
#     set gaSet(fail) "Open COM $gaSet(comUut2) fail"
#   }
  return $ret
}
proc ocu {} {OpenComUut}
proc ouc {} {OpenComUut}
proc ccu {} {CloseComUut}
proc cuc {} {CloseComUut}
# ***************************************************************************
# OpenComAux
# ***************************************************************************
proc OpenComAux {} {
  global gaSet
   
  #set ret [RLSerial::Open $gaSet(comAux1) 9600 n 8 1]
  set ret [RLCom::Open $gaSet(comAux2) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comAux1) fail"
  }
  #set ret [RLSerial::Open $gaSet(comAux2) 9600 n 8 1]
  set ret [RLCom::Open $gaSet(comAux2) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comAux2) fail"
  }
  
  return $ret
}
# ***************************************************************************
# CloseComAux
# ***************************************************************************
proc CloseComAux {} {
  global gaSet
  catch {RLCom::Close $gaSet(comAux1)}
  catch {RLCom::Close $gaSet(comAux2)}
  return {}
}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  catch {RLCom::Close $gaSet(comUut1)}
  catch {RLCom::Close $gaSet(comUut2)}
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  set gaSet(serial) ""
  ClosePio
  puts "CloseRL ClosePio" ; update
  CloseComUut
  puts "CloseRL CloseComUut" ; update 
  catch {RLDxc4::CloseAll}
  catch {RLEtxGen::CloseAll}
  catch {RLEH::Close}
}

# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  # parray ::RLUsbPio::description *Ser*
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
  if {[llength $boxL]!=7} {
    set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
    return -1
  }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet descript
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  foreach rb {1 2} {
    set gaSet(idPwr$rb) [RLUsbPio::Open $rb RBA $channel]
  }
#   set gaSet(idDrc) [RLUsbPio::Open 1 PORT $channel]
#   RLUsbPio::SetConfig $gaSet(idDrc) 11111111 ; # all 8 pins are IN
  
 set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
 set gaSet(idMuxE1)    [RLUsbMmux::Open 4 $channel]
 MuxMngIO ioToGenMngToPc ioToIo
  
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet
  set ret 0
  foreach rb "1 2" {
	  catch {RLUsbPio::Close $gaSet(idPwr$rb)}
  }
  catch {RLUsbPio::Close $gaSet(idDrc)}
  catch {RLUsbMmux::Close $gaSet(idMuxMngIO)}
  catch {RLUsbMmux::Close $gaSet(idMuxE1)}
  
  return $ret
}

# ***************************************************************************
# SaveUutInit
# ***************************************************************************
proc SaveUutInit {fil} {
  global gaSet
  puts "SaveUutInit $fil"
  set id [open $fil w]
  puts $id "set gaSet(sw)          \"$gaSet(sw)\""
  puts $id "set gaSet(dbrSW)       \"$gaSet(dbrSW)\""
  puts $id "set gaSet(swPack)      \"$gaSet(swPack)\""
  
  puts $id "set gaSet(dbrBVerSw)   \"$gaSet(dbrBVerSw)\""
  puts $id "set gaSet(dbrBVer)     \"$gaSet(dbrBVer)\""
  if ![info exists gaSet(cpld)] {
    set gaSet(cpld) ???
  }
  puts $id "set gaSet(cpld)        \"$gaSet(cpld)\""
  
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(DutFullName) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
  foreach indx {Boot SW  DGasp ExtClk EthLink_UUT EthLink_REF SyncEMaster Aux1 Aux2} {
    if ![info exists gaSet([set indx]CF)] {
      set gaSet([set indx]CF) ??
    }
    puts $id "set gaSet([set indx]CF) \"$gaSet([set indx]CF)\""
  }
  foreach indx {licDir} {
    if ![info exists gaSet($indx)] {
      puts "SaveUutInit fil:$SaveUutInit gaSet($indx) doesn't exist!"
      set gaSet($indx) ???
    }
    puts $id "set gaSet($indx) \"$gaSet($indx)\""
  }
  
  #puts $id "set gaSet(macIC)      \"$gaSet(macIC)\""
  close $id
}  
# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet  
  set id [open [info host]/init$gaSet(pair).tcl w]
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(entDUT) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
    
  puts $id "set gaSet(performShortTest) \"$gaSet(performShortTest)\""  
  
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  puts $id "set gaSet(eraseTitle) \"$gaSet(eraseTitle)\""
  
  if {![info exists gaSet(ddrMultyQty)]} {
    set gaSet(ddrMultyQty) 5
  }
  puts $id "set gaSet(ddrMultyQty) \"$gaSet(ddrMultyQty)\""
  
  if {![info exists gaSet(scopeModel)]} {
    set gaSet(scopeModel) Tds340
  }
  puts $id "set gaSet(scopeModel) \"$gaSet(scopeModel)\""
  
  close $id
   
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}

#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [Send$com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent expected {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #puts "sent:<$sent>"
  regsub -all {[ ]+} $sent " " sent
  #puts "sent:<[string trimleft $sent]>"
  ##set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  ##set cmd [list RLSerial::Send $com $sent buffer $expected [expr {1*$timeOut}]]
  #set cmd [list RLCom::Send     $com $sent buffer $expected $timeOut]
  set cmd [list RLCom::SendSlow $com $sent 10 buffer $expected $timeOut]
  if {$gaSet(act)==0} {return -2}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  #puts buffer:<$buffer> ; update
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  regsub -all -- {\[74G}        $b3 " " b3
  set buffer $b3
  #puts "sent:<$sent>"
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=$expected, buffer=$buffer"
    puts "send: ----------------------------------------\n"
    update
  }
  
  RLTime::Delayms 10
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  $gaSet(runTime) configure -text ""
  update
}


##***************************************************************************
##** Wait
##** 
##** 
##***************************************************************************
proc Wait {txt count {color white}} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	 $gaSet(runTime) configure -text $i
	 RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}


#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}


# ***************************************************************************
# PerfSet
# ***************************************************************************
proc PerfSet {state} {
  global gaSet gaGui
  set gaSet(perfSet) $state
  puts "PerfSet state:$state"
  switch -exact -- $state {
    1 {$gaGui(noSet) configure -relief raised -image [Bitmap::get images/Set] -helptext "Run with the UUTs Setup"}
    0 {$gaGui(noSet) configure -relief sunken -image [Bitmap::get images/noSet] -helptext "Run without the UUTs Setup"}
    swap {
      if {[$gaGui(noSet) cget -relief]=="raised"} {
        PerfSet 0
      } elseif {[$gaGui(noSet) cget -relief]=="sunken"} {
        PerfSet 1
      }
    }  
  }
}
# ***************************************************************************
# MyWaitFor
# ***************************************************************************
proc MyWaitFor {com expected testEach timeout} {
  global buffer gaGui gaSet
  #Status "Waiting for \"$expected\""
  if {$gaSet(act)==0} {return -2}
  puts [MyTime] ; update
  set startTime [clock seconds]
  set runTime 0
  while 1 {
    #set ret [RLCom::Waitfor $com buffer $expected $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    set ret [Send $com \r stam $testEach]
    foreach expd $expected {
      puts "buffer:__[set buffer]__ expected:\"$expected\" expd:$expd ret:$ret runTime:$runTime" ; update
#       if {$expd=="PASSWORD"} {
#         ## in old versiond you need a few enters to get the uut respond
#         Send $com \r stam 0.25
#       }
      if [string match *$expd* $buffer] {
        set ret 0
        break
      }
    }
    #set ret [Send $com \r $expected $testEach]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    $gaSet(runTime) configure -text $runTime
    #puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
    if {$runTime>$timeout} {break }
    if {$gaSet(act)==0} {set ret -2 ; break}
    update
  }
  puts "[MyTime] ret:$ret runTime:$runTime"
  $gaSet(runTime) configure -text ""
  Status ""
  return $ret
}   
# ***************************************************************************
# Power
# ***************************************************************************
proc Power {ps state} {
  global gaSet gaGui 
  puts "[MyTime] Power $ps $state"
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
#   return 0
  set ret 0
  switch -exact -- $ps {
    1   {set pioL 1}
    2   {set pioL 2}
    all {set pioL "1 2"}
  } 
  switch -exact -- $state {
    on  {
	    foreach pio $pioL {      
        RLUsbPio::Set $gaSet(idPwr$pio) 1
      }
    } 
	  off {
	    foreach pio $pioL {
	      RLUsbPio::Set $gaSet(idPwr$pio) 0
      }
    }
  }
#   $gaGui(tbrun)  configure -state disabled 
#   $gaGui(tbstop) configure -state normal
  Status ""
  update
  #exec C:\\RLFiles\\Btl\\beep.exe &
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
  return $ret
}

# ***************************************************************************
# GuiPower
# ***************************************************************************
proc GuiPower {n state} { 
  global gaSet descript
  puts "\nGuiPower $n $state"
  RLEH::Open
  RLUsbPio::GetUsbChannels descript
  switch -exact -- $n {
    1.1 - 2.1 - 3.1 - 4.1 {set portL [list 1]}
    1.2 - 2.2 - 3.2 - 4.2 {set portL [list 2]}      
    1 - 2 - 3 - 4 - all  {set portL [list 1 2]}  
  }        
  set channel [RetriveUsbChannel]
  if {$channel!="-1"} {
    foreach rb $portL {
      set id [RLUsbPio::Open $rb RBA $channel]
      puts "rb:<$rb> id:<$id>"
      RLUsbPio::Set $id $state
      RLUsbPio::Close $id
    }   
  }
  RLEH::Close
} 

#***************************************************************************
#** Wait
#***************************************************************************
proc _Wait {ip_time ip_msg {ip_cmd ""}} {
  global gaSet 
  Status $ip_msg 

  for {set i $ip_time} {$i >= 0} {incr i -1} {       	 
	 if {$ip_cmd!=""} {
      set ret [eval $ip_cmd]
		if {$ret==0} {
		  set ret $i
		  break
		}
	 } elseif {$ip_cmd==""} {	   
	   set ret 0
	 }

	 #user's stop case
	 if {$gaSet(act)==0} {		 
      return -2
	 }
	 
	 RLTime::Delay 1	 
    $gaSet(runTime) configure -text " $i "
	 update	 
  }
  $gaSet(runTime) configure -text ""
  update   
  return $ret  
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
  #set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
  set logFileID [open $gaSet(logFile.$gaSet(pair)) a+] 
    puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# AddToPairLog
# ***************************************************************************
proc AddToPairLog {pair line}  {
  global gaSet
  set logFileID [open $gaSet(log.$pair) a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}
# ***************************************************************************
# ShowLog 
# ***************************************************************************
proc ShowLog {} {
	global gaSet
	#exec notepad tmpFiles/logFile-$gaSet(pair).txt &
#   if {[info exists gaSet(logFile.$gaSet(pair))] && [file exists $gaSet(logFile.$gaSet(pair))]} {
#     exec notepad $gaSet(logFile.$gaSet(pair)) &
#   }
  if {[info exists gaSet(log.$gaSet(pair))] && [file exists $gaSet(log.$gaSet(pair))]} {
    exec notepad $gaSet(log.$gaSet(pair)) &
  }
}

# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}
# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {} {
  global gaSet gaGui
  Status "Please wait for retriving DBR's parameters"
  set barcode [set gaSet(entDUT) [string toupper $gaSet(entDUT)]] ; update
  
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  wm title . "$gaSet(pair) : "
  after 500
  
#   set javaLoc1 C:\\Program\ Files\\Java\\jre6\\bin\\
#   set javaLoc2 C:\\Program\ Files\ (x86)\\Java\\jre6\\bin\\
#   if {[file exist $javaLoc1]} {
#     set javaLoc $javaLoc1
#   } elseif {[file exist $javaLoc2]} {
#     set javaLoc $javaLoc2
#   } else {
#     set gaSet(fail) "Java application is missing"
#     return -1
#   }
  catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b
  set fileName MarkNam_$barcode.txt
  after 1000
  if ![file exists MarkNam_$barcode.txt] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  
  #set txt "$barcode $res"
  set txt "[string trim $res]"
  #set gaSet(entDUT) $txt
  set gaSet(entDUT) ""
  puts "GetDbrName <$txt>"
  
  set initName [regsub -all / $res .]
  puts "GetDbrName res:<$res>"
  puts "GetDbrName initName:<$initName>"
  set gaSet(DutFullName) $res
  set gaSet(DutInitName) $initName.tcl
  
  file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  if {[file exists uutInits/$gaSet(DutInitName)]} {
    source uutInits/$gaSet(DutInitName)  
    #UpdateAppsHelpText  
  } else {
    ## if the init file doesn't exist, fill the parameters by ? signs
    foreach v {sw} {
      puts "GetDbrName gaSet($v) does not exist"
      set gaSet($v) ??
    }
    foreach en {licEn} {
      set gaSet($v) 0
    } 
  } 
  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  pack forget $gaGui(frFailStatus)
  #Status ""
  update
  BuildTests
  
  set ret [GetDbrSW $barcode]
  puts "GetDbrName ret of GetDbrSW:$ret" ; update
  if {$ret!=0} {
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  }  
  puts ""
  
  focus -force $gaGui(tbrun)
  if {$ret==0} {
    Status "Ready"
  }
  return $ret
}

# ***************************************************************************
# DelMarkNam
# ***************************************************************************
proc DelMarkNam {} {
  if {[catch {glob MarkNam*} MNlist]==0} {
    foreach f $MNlist {
      file delete -force $f
    }  
  }
}

# ***************************************************************************
# GetInitFile
# ***************************************************************************
proc GetInitFile {} {
  global gaSet gaGui
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl]
  if {$fil!=""} {
    source $fil
    set gaSet(entDUT) "" ; #$gaSet(DutFullName)
    wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    #UpdateAppsHelpText
    pack forget $gaGui(frFailStatus)
    Status ""
    BuildTests
  }
}
# ***************************************************************************
# UpdateAppsHelpText
# ***************************************************************************
proc UpdateAppsHelpText {} {
  global gaSet gaGui
  #$gaGui(labPlEnPerf) configure -helptext $gaSet(pl)
  #$gaGui(labUafEn) configure -helptext $gaSet(uaf)
  #$gaGui(labUdfEn) configure -helptext $gaSet(udf)
}

# ***************************************************************************
# RetriveDutFam
# RetriveDutFam [regsub -all / ETX-DNFV-M/I7/128S/8R .].tcl
# ***************************************************************************
proc RetriveDutFam {{dutInitName ""}} {
  global gaSet 
  set gaSet(dutFam) NA 
  set gaSet(dutBox) NA 
  if {$dutInitName==""} {
    set dutInitName $gaSet(DutInitName)
  }
  puts "RetriveDutFam $dutInitName"
  set gaSet(dutFam) 19.0.0.0.0.0.0
  
  set npo 6SFP_6UTP
  set upo upo
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
    set gaSet(dutFam) $b.$r.$p.$d.$ps.$npo.$upo  
  }
  
  if {[string match *.SYE* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.$r.$p.$d.$ps.$np.SYE  
    }
  }
  
  if {[string match *.RTR.* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.R.$p.$d.$ps.$np.$up  
    }
  }
  if {[string match *.PTP.* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.$r.P.$d.$ps.$np.$up  
    }
  }
  if {[string match *.DRC.* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.$r.$p.D.$ps.$np.$up  
    }
  }
  
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set PS noPS
  if {[string match *.WR.* $dutInitName]==1} {
    set PS WR
  } elseif {[string match *.AC* $dutInitName]==1} {
    set PS AC
  } elseif {[string match *DC* $dutInitName]==1} {
    set PS DC
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
    set gaSet(dutFam) $b.$r.$p.$d.$PS.$np.$up  
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set gaSet(dutBox) $b
  
  puts "dutInitName:$dutInitName dutBox:$gaSet(dutBox) DutFam:$gaSet(dutFam)" ; update
}                               
# ***************************************************************************
# DownloadConfFile
# ***************************************************************************
proc DownloadConfFile {cf cfTxt save com} {
  global gaSet  buffer
  puts "[MyTime] DownloadConfFile $cf \"$cfTxt\" $save $com"
  #set com $gaSet(comDut)
  if ![file exists $cf] {
    set gaSet(fail) "The $cfTxt configuration file ($cf) doesn't exist"
    return -1
  }
  Status "Download Configuration File $cf" ; update
  set s1 [clock seconds]
  set id [open $cf r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {close $id ; return -2}
    set line [string trim $line]
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      
      puts "line:<$line>"
#       if {[string match {*address*} $line] && [llength $line]==2} {
#         if {[string match *DefaultConf* $cfTxt] || [string match *RTR* $cfTxt]} {
#           ## don't change address in DefaultConf
#         } else {
#           ##  address 10.10.10.12/24
#           set dutIp 10.10.10.1[set gaSet(pair)]
#           set address [set dutIp]/[lindex [split [lindex $line 1] /] 1]
#           set line "address $address"
#         }
#       }
      if {[string match *EccXT* $cfTxt] || [string match *vvDefaultConf* $cfTxt] || [string match *aAux* $cfTxt]} {
        ## perform the configuration fast (without expected)
        set ret 0
        set buffer bbb
        #RLSerial::Send $com "$line\r" 
        RLCom::Send $com "$line\r"
      } else {
        if {[string match *Aux* $cfTxt]} {
          set waitFor 205A
        } else {
          set waitFor 2I
        }
        #set ret [Send $com $line\r $waitFor 10] ; # 60
        set ret 0 ; Send $com $line\r stamStam 0.25
      }  
      if {$ret!=0} {
        set gaSet(fail) "Config of DUT failed"
        break
      }
      if {[string match {*cli error*} [string tolower $buffer]]==1} {
        if {[string match {*range overlaps with previous defined*} [string tolower $buffer]]==1} {
          ## skip the error
        } else {
          set gaSet(fail) "CLI Error"
          set ret -1
          break
        }
      }  
      if {[string match {*boot*} [string tolower $buffer]]==1} {
        if {[string match {*range overlaps with previous defined*} [string tolower $buffer]]==1} {
          ## skip the error
        } else {
          set gaSet(fail) "DUT performed reset"
          set ret -1
          break
        }
      }          
    }
  }
  close $id  
  if {$ret==0} {
    if {$com==$gaSet(comAux1) || $com==$gaSet(comAux2)} {
      set ret [Send $com "exit all\r" "205A"]
    } else {
      set ret [Send $com "exit all\r" "2I"]
    }
    if {$save==1} {
      set ret [Send $com "admin save\r" "successfull" 80]
    }
     
    set s2 [clock seconds]
    puts "[expr {$s2-$s1}] sec c:$c" ; update
  }
  Status ""
  puts "[MyTime] Finish DownloadConfFile" ; update
  return $ret 
}
# ***************************************************************************
# Ping
# ***************************************************************************
proc Ping {dutIp} {
  global gaSet
  set i 0
  while {$i<=4} {
    if {$gaSet(act)==0} {return -2}
    incr i
    #------
    catch {exec arp.exe -d}  ;#clear pc arp table
    catch {exec ping.exe $dutIp -n 2} buffer
    if {[info exist buffer]!=1} {
	    set buffer "?"  
    }  
    set ret [regexp {Packets: Sent = 2, Received = 2, Lost = 0 \(0% loss\)} $buffer var]
    puts "ping i:$i ret:$ret buffer:<$buffer>"  ; update
    if {$ret==1} {break}    
    #------
    after 500
  }
  
  if {$ret!=1} {
    puts $buffer ; update
	  set gaSet(fail) "Ping fail"
 	  return -1  
  }
  return 0
}
# ***************************************************************************
# GetMac
# ***************************************************************************
proc GetMac {fi} {
  puts "[MyTime] GetMac $fi" ; update
  set macFile c:/tmp/mac[set fi].txt
  exec $::RadAppsPath/MACServer.exe 0 1 $macFile 1
  set ret [catch {open $macFile r} id]
  if {$ret!=0} {
    set gaSet(fail) "Open Mac File fail"
    return -1
  }
  set buffer [read $id]
  close $id
  file delete $macFile)
  set ret [regexp -all {ERROR} $buffer]
  if {$ret!=0} {
    set gaSet(fail) "MACServer ERROR"
    exec beep.exe
    return -1
  }
  return [lindex $buffer 0]
}
# ***************************************************************************
# SplitString2Paires
# ***************************************************************************
proc SplitString2Paires {str} {
  foreach {f s} [split $str ""] {
    lappend l [set f][set s]
  }
  return $l
}

# ***************************************************************************
# GetDbrSW
# ***************************************************************************
proc GetDbrSW {barcode} {
  global gaSet gaGui
  set gaSet(dbrSW) ""
#   set javaLoc1 C:\\Program\ Files\\Java\\jre6\\bin\\
#   set javaLoc2 C:\\Program\ Files\ (x86)\\Java\\jre6\\bin\\
#   if {[file exist $javaLoc1]} {
#     set javaLoc $javaLoc1
#   } elseif {[file exist $javaLoc2]} {
#     set javaLoc $javaLoc2
#   } else {
#     set gaSet(fail) "Java application is missing"
#     return -1
#   }
  
  catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/SWVersions4IDnumber.jar $barcode} b
  puts "GetDbrSW b:<$b>" ; update
  after 1000
  if ![info exists gaSet(swPack)] {
    set gaSet(swPack) ""
  }
  set swIndx [lsearch $b $gaSet(swPack)]  
  if {$swIndx<0} {
    set gaSet(fail) "There is no SW ID for $gaSet(swPack) ID:$barcode. Verify the Barcode."
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set dbrSW [string trim [lindex $b [expr {1+$swIndx}]]]
  puts dbrSW:<$dbrSW>
  set gaSet(dbrSW) $dbrSW
  
  set dbrBVerSwIndx [lsearch $b $gaSet(dbrBVerSw)]  
  if {$dbrBVerSwIndx<0} {
    set gaSet(fail) "There is no Boot SW ID for $gaSet(dbrBVerSw) ID:$barcode. Verify the Barcode."
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set dbrBVer [string trim [lindex $b [expr {1+$dbrBVerSwIndx}]]]
  puts dbrBVer:<$dbrBVer>
  set gaSet(dbrBVer) $dbrBVer
  
  pack forget $gaGui(frFailStatus)
  
  set swTxt [glob SW*_$barcode.txt]
  catch {file delete -force $swTxt}
  
  Status ""
  update
  BuildTests
  focus -force $gaGui(tbrun)
  return 0
}
# ***************************************************************************
# GuiMuxMngIO
## GuiMuxMngIO ioToGenMngToPc ioToIo
# ***************************************************************************
proc GuiMuxMngIO {mngMode syncEmode} {
  global gaSet descript
  set channel [RetriveUsbChannel]   
  RLEH::Open
  set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
  set gaSet(idMuxE1)    [RLUsbMmux::Open 4 $channel]
  MuxMngIO $mngMode $syncEmode
  RLUsbMmux::Close $gaSet(idMuxMngIO) 
  RLUsbMmux::Close $gaSet(idMuxE1) 
  RLEH::Close
}
# ***************************************************************************
# MuxMngIO
##     MuxMngIO ioToGenMngToPc ioToIo
# ***************************************************************************
proc MuxMngIO {mngMode syncEmode} {
  global gaSet
  puts "MuxMngIO $mngMode $syncEmode"
  RLUsbMmux::AllNC $gaSet(idMuxMngIO)
  RLUsbMmux::AllNC $gaSet(idMuxE1)
  after 1000
  switch -exact -- $mngMode {
    ioToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,2,9,14
    }
    ioToGenMngToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,1,8,14
    }
    ioToGen {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,1
    }
    mngToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 8,14
    }
    ioToCnt {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,3
    }
    nc {
      ## do nothing, already disconected
    }
  }
  switch -exact -- $syncEmode {
    ioToIo {
      RLUsbMmux::ChsCon $gaSet(idMuxE1) 1,7,8,14
    }
    slave {
      RLUsbMmux::ChsCon $gaSet(idMuxE1) 1,6,15,21,8,13
    }
    master {
      RLUsbMmux::ChsCon $gaSet(idMuxE1) 1,7,8,14,16,21
    }
    nc {
      ## do nothing, already disconected
    }
  }
}


# ***************************************************************************
# InitAux
# ***************************************************************************
proc InitAux {aux} {
  global gaSet
  set com $gaSet(com$aux)
  
  RLEH::Open
  #set ret [RLSerial::Open $com 9600 n 8 1]
  set ret [RLCom::Open $com 9600 8 NONE 1]
  set ret [Login205 $aux]
  if {$ret!=0} {
    set ret [Login205 $aux]
    
  }
  set gaSet(fail) "Logon fail"
  
  if {$ret==0} {
    Send $com "exit all\r" stam 0.25 
    set cf $gaSet([set aux]CF) 
    set cfTxt "$aux"
    set ret [DownloadConfFile $cf $cfTxt 1 $com]    
  }  
  #catch {RLSerial::Close $com}
  catch {RLCom::Close $com}
  RLEH::Close
  if {$ret==0} {
    Status "$aux is configured"  yellow
  } else {
    Status "Configuration of $aux failed" red
  }
  return $ret
} 
# ***************************************************************************
# wsplit
# ***************************************************************************
proc wsplit {str sep} {
  split [string map [list $sep \0] $str] \0
}
# ***************************************************************************
# LoadBootErrorsFile
# ***************************************************************************
proc LoadBootErrorsFile {} {
  global gaSet
  set gaSet(bootErrorsL) [list] 
  if ![file exists bootErrors.txt]  {
    return {}
  }
  
  set id [open  bootErrors.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet(bootErrorsL) $line
      }
    }

  close $id
  
#   foreach ber $bootErrorsL {
#     if [string length $ber] {
#      lappend gaSet(bootErrorsL) $ber
#    }
#   }
  return {}
}
# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  if [file exist $path1] {
    set path $path1
  } elseif [file exist $path2] {
    set path $path2  
  } else {
    puts "no teraterm installed"
    return {}
  }
  if {[string match *Uut* $comName] || [string match *Aux* $comName]} {
    set baud 9600
  } else {
    set baud 115200
  }
  regexp {com(\w+)} $comName ma val
  set val Tester-$gaSet(pair).[string toupper $val]  
  exec $path /c=[set $comName] /baud=$baud /W="$val" &
  return {}
}  

# ***************************************************************************
# InitRef
# ***************************************************************************
proc InitRef {} {
  global gaSet
  set gSet(act) 1
  #set ret [RLSerial::Open $gaSet(comUut2) 9600 n 8 1]
  set ret [RLCom::Open $gaSet(comUut2) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comUut2) fail"
    return -1
  }
  set ret [Login Uut2]
  if {$ret==0} {  
    set gaSet(fail) "Logon fail"
    set com $gaSet(comUut2)
       
    Send $com "exit all\r" stam 0.25 
    Status "Factory Default..."
    set ret [Send $com "admin factory-default\r" "yes/no" ]
    if {$ret==0} {
      set ret [Send $com "y\r" "seconds" 20]
    }
    set ret [Wait "Wait DUT down" 20 white]
    if {$ret==0} {
      set ret [Login Uut2]
    }  
   
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
    
    set cf $gaSet(EthLink_REFCF) 
    set cfTxt "$b"
    if {$ret==0} {    
      set ret [DownloadConfFile $cf $cfTxt 1 $com]
    }
  }
  
  #catch {RLSerial::Close $gaSet(comUut2)}  
  catch {RLCom::Close $gaSet(comUut2)}  
  return $ret
}
# ***************************************************************************
# UpdateInitsToTesters
# ***************************************************************************
proc UpdateInitsToTesters {} {
  global gaSet
  set sdl [list]
  set unUpdatedHostsL [list]
  set hostsL [list A-2I64E1-1-HP10 soldlogsrv1-10]
  set initsPath AT-ETX-2i-64ET1/software/uutInits
  set usDefPath AT-ETX-2i-64ET1/ConfFiles/DEFAULT
  
  set s1 c:/$initsPath
  set s2 c:/$usDefPath
  foreach host $hostsL {
    if {$host!=[info host]} {
      set dest //$host/c$/$initsPath
      if [file exists $dest] {
        lappend sdl $s1 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
      
      set dest //$host/c$/$usDefPath
      if [file exists $dest] {
        lappend sdl $s2 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
    }
  }
  
  set msg ""
  set unUpdatedHostsL [lsort -unique $unUpdatedHostsL]
  if {$unUpdatedHostsL!=""} {
    append msg "The following PCs are not reachable:\n"
    foreach h $unUpdatedHostsL {
      append msg "$h\n"
    }  
    append msg \n
  }
  if {$sdl!=""} {
    if {$gaSet(radNet)} {
      set emailL {ilya_g@rad.com}
    } else {
      set emailL [list]
    }
    set ret [RLAutoUpdate::AutoUpdate $sdl]
    set updFileL    [lsort -unique $RLAutoUpdate::updFileL]
    set newestFileL [lsort -unique $RLAutoUpdate::newestFileL]
    if {$ret==0} {
      if {$updFileL==""} {
        ## no files to update
        append msg "All files are equal, no update is needed"
      } else {
        append msg "Update is done"
        if {[llength $emailL]>0} {
          RLAutoUpdate::SendMail $emailL $updFileL  "file://R:\\IlyaG\\2i64ET1"
          if ![file exists R:/IlyaG/2i64ET1] {
            file mkdir R:/IlyaG/2i64ET1
          }
          foreach fi $updFileL {
            catch {file copy -force $s1/$fi R:/IlyaG/2i64ET1 } res
            puts $res
            catch {file copy -force $s2/$fi R:/IlyaG/2i64ET1 } res
            puts $res
          }
        }
      }
      tk_messageBox -message $msg -type ok -icon info -title "Tester update" ; #DialogBox icon /images/info
    }
  } else {
    tk_messageBox -message $msg -type ok -icon info -title "Tester update"
  } 
}
# ***************************************************************************
# PrepareDwnlJatPll
# ***************************************************************************
proc PrepareDwnlJatPll {} {
  global gaSet
   
  set SWCF c:/download/JTAG_Burn_64E1/sw-pack_2i_rev_[set gaSet(abd)].bin
  puts "SetJatPllDownload SWCF:$SWCF"; update
  
  if {[file exists $SWCF]!=1} {
    set gaSet(fail) "The SW file $SWCF doesn't exist"
    return -1
  }
     
  # set tail [file tail $SWCF]
  set tail $gaSet(pair)_[file tail $SWCF]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 2000
    if [file exists c:/download/temp/$tail] {
      if [catch {file delete -force c:/download/temp/$tail} cres] {
        set gaSet(fail) "The SW file ($SWCF) can't be deleted"
        puts "[MyTime] PrepareDwnlJatPll. The file c:/download/temp/$tail ($gaSet(SWCF)) can't be deleted. cres:<$cres>"
        return -1
      }
    
    }
  }
    
  if [catch {file copy -force $SWCF c:/download/temp/$tail } res] {
    set tail $res
  }
  
  return $tail
}