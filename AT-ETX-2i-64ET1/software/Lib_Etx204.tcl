proc OpenEtxGen {} {
  global gaSet gaEtx204Conf
  set gaSet(idGen1) [RLEtxGen::Open $gaSet(comGen1) -package RLCom] 
  #set gaSet(idGen2) [RLEtxGen::Open $gaSet(comGen2) -package RLCom]
  #if {[string is integer $gaSet(idGen1)] && [string is integer $gaSet(idGen2)] && $gaSet(idGen1)>0 && $gaSet(idGen2)>0} {}
  if {[string is integer $gaSet(idGen1)] && $gaSet(idGen1)>0} {   
    set ret 0
  } else {
    set ret -1
  }
  if {$ret==0} {
   ::RLEtxGen::GetConfig $gaSet(idGen1) gaEtx204Conf
   if {$gaEtx204Conf(id1,DA,Gen1)=="000000000005"} {
     InitEtxGen 1     
   }
#    ::RLEtxGen::GetConfig $gaSet(idGen2) gaEtx204Conf
#    if {$gaEtx204Conf(id2,DA,Gen1)=="000000000005"} {
#      InitEtxGen 2     
#    }
  }
  return $ret 
}

# ***************************************************************************
# ToolsEtxGen
# ***************************************************************************
proc ToolsEtxGen {} {
  global gaSet
  
  foreach gen {1} {
    Status "Opening EtxGen-$gen..."
    set gaSet(idGen$gen) [RLEtxGen::Open $gaSet(comGen$gen) -package RLCom]
    InitEtxGen $gen
  }
  Status Done
  catch {RLEtxGen::CloseAll}
  return 0
} 
# ***************************************************************************
# InitEtxGen
# ***************************************************************************
proc InitEtxGen {gen}  {
  global gaSet
  set id $gaSet(idGen$gen)
  Status "EtxGen-$gen Ports Configuration"
  set maxAdv 1000-f
  puts "PortsConfig -autoneg enbl -maxAdvertize $maxAdv"
  update
  RLEtxGen::PortsConfig $id -updGen all -autoneg enbl -maxAdvertize $maxAdv \
      -admStatus up ; #-save yes 
  
  Status "EtxGen-$gen Gen Configuration"
  set genM GE
  set minLen 64
  set maxLen 64
  set chanin 1
  set packRate 1250000
  set stre 1
  set packType MAC
  puts "GenConfig -genMode $genM -minLen $minLen -maxLen $maxLen -chain $chanin -packRate $packRate -stream $stre -packType $packType"
  update
  RLEtxGen::GenConfig $id -updGen all -factory yes -genMode $genM \
    -minLen $minLen -maxLen $maxLen -chain $chanin -packRate $packRate -stream $stre -packType $packType 
      
  
#   Status "EtxGen-$gen Packet Configuration"
  #foreach port {1 2 3 4} {}
#   foreach port {1 2} {
#     set sa 0000000000[set gen][set port]
#     set da 0000000000[expr {3-$gen}][set port]
#     puts "EtxGen-$gen Packet Configuration port-$port sa:$sa da:$da" 
#     RLEtxGen::PacketConfig $id MAC -updGen $port -SA $sa -DA $da
#     ## gen 1 port 1, sa=11 da=[3-1]1=21
#     ## gen 2 port 4, sa=24 da=[3-2]4=14
#   }
  return 0
}

# ***************************************************************************
# Etx204Start
# ***************************************************************************
proc Etx204Start {} {
  global gaSet buffer
  Status "Etx204 Start"
#   Etx204Stop
  after 500
#   foreach gen {1 2} {
#     set id $gaSet(idGen$gen)
#     puts "Etx204 Start .. [MyTime]" ; update
#     RLEtxGen::Start $id 
#   }  
#   after 500
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Clear $id
  }  
  after 500
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Start $id 
  }  
  after 500
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Clear $id
  }
  return 0
}  

# ***************************************************************************
# Etx204Check
# ***************************************************************************
proc Etx204Check {port} {
  global gaSet aRes
  #Etx204Stop
  set ret 0
  foreach gen {1} {
    puts "Etx204-$gen Port $port Check .. [MyTime]" ; update
    set id $gaSet(idGen$gen)    

    RLEtxGen::GetStatistics $id aRes
    if ![info exist aRes] {
      after 2000
      RLEtxGen::GetStatistics $id aRes
      if ![info exist aRes] {
        set gaSet(fail) "Read statistics of ETX204-$gen fail"
        return -1
      }
    }
    set res1 0
    set res2 0
    set res3 0
    set res4 0
  
    #foreach port {1 2 3 4} {}
    #foreach port {1} {}
      puts "Generator-$gen Port-$port stats:"
      mparray aRes *Gen$port
      foreach stat {ERR_CNT FRAME_ERR PRBS_ERR SEQ_ERR FRAME_NOT_RECOGN} {
        set res $aRes(id$id,[set stat],Gen$port)
        if {$res!=0} {
          set gaSet(fail) "The $stat in ETX204-$gen Port-$port is $res. Should be 0"
          set res$port -1
          break
        }
      }
      foreach stat {PRBS_OK RCV_BPS RCV_PPS} {
        set res $aRes(id$id,[set stat],Gen$port)
        if {$res==0} {
          set gaSet(fail) "The $stat in ETX204-$gen Port-$port is 0. Should be more"
          set res$port -1
          break
        }
      }
      puts "res$port : [set res$port]"
#       if {[set res$port]!=0} {
#         break
#       }
 
    #if {$res1!=0 || $res2!=0 || $res3!=0 || $res4!=0} {}
    if {[set res$port]!=0} {
      set ret -1
      break
    }
  }  
   
  return $ret
}

# ***************************************************************************
# Etx204Stop
# ***************************************************************************
proc Etx204Stop {} {
  global gaSet
  puts "Etx204 Stop .. [MyTime]" ; update
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Stop $id
  }
  return 0
}
# ***************************************************************************
# Etx204Refresh
# ***************************************************************************
proc Etx204Refresh {} {
  global gaSet buffer
  puts "Etx204 Refresh .. [MyTime]" ; update
  foreach gen {1} {
    set com $gaSet(comGen$gen)
    RLCom::Send $com ! buffer CLI 2    
    RLCom::Send $com 3\r buffer CLI 2
    RLCom::Send $com 9\r buffer CLI 2
    for {set i 1} {$i<=4} {incr i} {
      RLCom::Send $com q buffer help 2 
      RLCom::Send $com \r buffer help 2
    }
  }
  return 0
} 