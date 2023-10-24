# ***************************************************************************
# CRC
# ***************************************************************************
proc CRC {ldata} {

  #demo:
  #set ldata [list 11 02 11 10 00 00 00 00 00 01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
  #set ldata [list 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 20 D2 FB 5E C5 00 00 00 00 00 00 00 00 00 00 00]

  set lKey [list \
  00 07 0E 09 1C 1B 12 15 \
  38 3F 36 31 24 23 2A 2D \
  70 77 7E 79 6C 6B 62 65 \
	48 4F 46 41 54 53 5A 5D \
	E0 E7 EE E9 FC FB F2 F5 \
	D8 DF D6 D1 C4 C3 CA CD \
	90 97 9E 99 8C 8B 82 85 \
	A8 AF A6 A1 B4 B3 BA BD \
	C7 C0 C9 CE DB DC D5 D2 \
	FF F8 F1 F6 E3 E4 ED EA \
	B7 B0 B9 BE AB AC A5 A2 \
	8F 88 81 86 93 94 9D 9A \
	27 20 29 2E 3B 3C 35 32 \
	1F 18 11 16 03 04 0D 0A \
	57 50 59 5E 4B 4C 45 42 \
	6F 68 61 66 73 74 7D 7A \
	89 8E 87 80 95 92 9B 9C \
	B1 B6 BF B8 AD AA A3 A4 \
	F9 FE F7 F0 E5 E2 EB EC \
	C1 C6 CF C8 DD DA D3 D4 \
  69 6E 67 60 75 72 7B 7C \
	51 56 5F 58 4D 4A 43 44 \
	19 1E 17 10 05 02 0B 0C \
	21 26 2F 28 3D 3A 33 34 \
	4E 49 40 47 52 55 5C 5B \
	76 71 78 7F 6A 6D 64 63 \
	3E 39 30 37 22 25 2C 2B \
	06 01 08 0F 1A 1D 14 13 \
	AE A9 A0 A7 B2 B5 BC BB \
	96 91 98 9F 8A 8D 84 83 \
	DE D9 D0 D7 C2 C5 CC CB \
	E6 E1 E8 EF FA FD F4 F3 ]

  set crc 00
  set lvar "$ldata"
  foreach a "$lvar" {
    set crc [lindex $lKey [expr 0x$crc^0x$a]]    
  }
  return $crc
}


# ***************************************************************************
# GetPageFile
# ***************************************************************************
proc GetPageFile {barcode} {
  global gaGui gaSet gaGet res
  puts "GetPageFile $barcode"
  #------------
  # demo:  
  # set gaSet(barcode) DE100147191
  # set gaSet(FileVer) 1
  #Page 0 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  #Page 1 - 00 00 00 41 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  #Page 2 - 11 02 21 10 00 00 00 00 00 01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  #Page 3 - 00 02 44 45 31 30 30 31 34 37 31 39 31 00 03 00 20 D2 FB 5E B1 00 00 00 00 00 00 00 00 00 00 00
  
  #------------

  catch {unset gaGet}
  set gaSet(FileVer) 1   
  set gaSet(IdTyp) 2  

  ## exec c:\\RADapps/Get28e01Data.exe  2\;DC1001403648\;1
  ## c:\RADapps/Get28e01Data.exe  2;DC1001403648;1
  ##exec c:\\RADapps/Get28e01Data.exe  $gaSet(IdTyp)\;$barcode\;$gaSet(FileVer)
  
  ## 19/01/2020 09:47:54
  exec $::RadAppsPath/Get28e01Data.exe  $gaSet(IdTyp)\;$barcode\;$gaSet(FileVer)\; 
  set fileName "$barcode.txt" 
  Status "Wait for Pages 0-3 retrieval ..." ; update

	if {[file exists "$fileName"]==0} {
	  set gaSet(fail) "Page file retrieval fail." ; update
    puts stderr "Page file retrieval fail." 
    return -1
	}  
  
  set fileId [open "$fileName"]
  seek $fileId 0
  set res [read $fileId]    
  close $fileId
  
  ##file delete -force $fileName 
  

  #Page0
  set ret [regexp {Page 0 - ([\w ]+)} $res var gaGet(page0)]  
  if {$ret!=1} {
  	set gaSet(fail) "Page0 retrieval fail." ; update
    puts stderr "Page0 retrieval fail." 
    return -1
  }
  set gaGet(page0) [string trim $gaGet(page0)]
  #Page1
  set ret [regexp {Page 1 - ([\w ]+)} $res var gaGet(page1)]  
  if {$ret!=1} {
  	set gaSet(fail) "Page1 retrieval fail." ; update
    puts stderr "Page1 retrieval fail." 
    return -1
  }
  set gaGet(page1) [string trim $gaGet(page1)]  
  #Page2
  set ret [regexp {Page 2 - ([\w ]+)} $res var gaGet(page2)]  
  if {$ret!=1} {
  	set gaSet(fail) "Page2 retrieval fail." ; update
    puts stderr "Page2 retrieval fail." 
    return -1
  }
  set gaGet(page2) [string trim $gaGet(page2)]  
  #Page3
  set ret [regexp {Page 3 - ([\w ]+)} $res var gaGet(page3)]  
  if {$ret!=1} {
  	set gaSet(fail) "Page3 retrieval fail." ; update
    puts stderr "Page3 retrieval fail." 
    return -1
  }  
  set gaGet(page3) [string trim $gaGet(page3)]
  
###   #page1:
###   set gaGet(HwRev.p1.01_02) [lrange $gaGet(page1) 1 2]
###   set gaGet(CslRev.p1.03)   [lrange $gaGet(page1) 3 3]
###   set gaGet(PcbRev.p1.04_05) [lrange $gaGet(page1) 4 5]
###   
###   #page3
###   set gaGet(Constant.p3.00) [lrange $gaGet(page3) 0 0] ;# should be 00 (hex)
###   set gaGet(IdTyp.p3.01) [lrange $gaGet(page3) 1 1]
###   set gaGet(IdNum.p3.02_13) [lrange $gaGet(page3) 2 13]
###   set gaGet(MacQuantity.p3.14) [lrange $gaGet(page3) 14 14]
###   set gaGet(1stMac.p3.15_20) [lrange $gaGet(page3) 15 20]
  file delete -force $fileName
  puts $res
  parray gaGet  
    
  return 0
}

# ***************************************************************************
# Write
# ***************************************************************************
proc WritePages {} {
  global gaGui gaGet buffer buff  gaSet
  set com $gaSet(comUut1)
  
	if {[Send $com "\r" "\[boot" 1] != 0} {
	  set gaSet(fail) "Failed to get Boot Menu" ; update
    return -1
	}
        
  Send $com "p\r" "\[boot" 1
  set ret [regexp {device IP[ \(\w \)]+:[ ]+[\w]+.[\w]+.([\w]+).([\w]+)} $buffer var var1 var2]	
  if {$ret!=1} {
    set gaSet(fail) "Failed to get Device IP" ; update
    return -1	  
  }
	  
  # Dec:
  set var1 [string trim $var1]
  set var2 [string trim $var2]
  #dec to Hex
  set var1 [format %.2x $var1]
  set var2 [format %.2x $var2]
  set password "y$var1$var2"
  puts "password:$password"
		  
	Send $com "\20\r" "\[boot" 1 ;# Shift ctrl-p
  for {set page 0} {$page <=3} {incr page 1} {
		#set crcInf [exec ds01crc.exe $gaGet(page$page)]
		#set crc [lindex $crcInf 1]
		set device 00 ; #constant
		set crc [CRC $gaGet(page$page)]
		set offSet 00   
    Status "Writing page $page"   	
		
		#Write:
    if {[Send $com "c2 $device,0$page,$offSet,$gaGet(page$page),$crc\r" "data ?" 3] != 0} {
		  set gaSet(fail) "Writing Error - page $page"
      return -1
    }			      
    Send $com "$password\r" "\[boot" 2
    
    # Read:
    #d2 <device#>,<page#>,<#byte>,<offset>
    #Send $com "d2 $device,0$page,32,$offSet\r" "\[boot" 2
    set ret [regexp {([\w\.]{47})\s+([\w\.]{47})} $buffer var var1 var2]
    if {$ret!=1} {
      set gaSet(fail) "Page$page check fail." ; update
      return -1	  
    }
    set var1 [string trim [regsub -all -- {\.} $var1 " "]]
    set var2 [string trim [regsub -all -- {\.} $var2 " "]]
    set res "$var1 $var2"
    if {[string match *$gaGet(page$page)* $res]==0} {
      set gaSet(fail) "Page$page result fail." ; update
      puts "res:$res"
      puts "pag:$gaGet(page$page)"
      #puts stderr "Page$page result fail." 
      return -1    
    }            	
	}
	
	return 0
}

# ***************************************************************************
# AsciiToHex_Convert_Split
# ***************************************************************************
proc AsciiToHex_Convert_Split {Ascii} {
  for {set i 0} {$i<=[expr [string length $Ascii]-1]} {incr i} {
    set arg [string range $Ascii $i $i]   
    lappend Hex [format %.2X [scan $arg %c]]
  }
  return $Hex
}

# ***************************************************************************
# DecToHex_Convert_Split
# ***************************************************************************
proc DecToHex_Convert_Split {Dec} {
  set Hex [format "%.2X" $Dec]
  return $Hex
}

# ***************************************************************************
# Split_Mac
# ***************************************************************************
proc Split_Mac {Mac} {
  foreach from "0 2 4 6 8 10" to "1 3 5 7 9 11" {
    lappend Split_Mac [string range $Mac $from $to]
  }
  return $Split_Mac
}
