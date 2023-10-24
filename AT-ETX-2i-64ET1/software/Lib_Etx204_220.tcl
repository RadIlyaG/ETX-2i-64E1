proc Etx220Config {port lineRate} {
  global gaSet      
  #puts "Etx220Start port $port tp $lineRate.. [MyTime]" ; update
  puts "RL10GbGen::Config $gaSet(id220) $port $port -sizeType Fixed -size 128 -dataPatternType Random -lineRate $lineRate .. [MyTime]"
  update
  RL10GbGen::Config $gaSet(id220) $port $port -sizeType Fixed -size 128 -dataPatternType Random -lineRate $lineRate 
}
# ***************************************************************************
# Etx220Start
# ***************************************************************************
proc Etx220Start {port} {
  global gaSet
  puts "Etx220Start port $port.. [MyTime]" ; update

  RL10GbGen::Start $gaSet(id220) $port $port
}
# ***************************************************************************
# Etx220Stop
# ***************************************************************************
proc Etx220Stop {port} {
  global gaSet
  puts "Etx220Stop port $port.. [MyTime]" ; update
  RL10GbGen::Stop $gaSet(id220) $port $port
  return 0
}
# ***************************************************************************
# Etx220Check
# ***************************************************************************
proc Etx220Check {port} {
  global gaSet gMessage aRes
  puts "Etx220Check $port .. [MyTime] "; update
  RL10GbGen::Read $gaSet(id220) $port $port aRes
  set ret [RL10GbGen::Check $gaSet(id220) $port $port aRes]
  #puts Checksret_$port:$ret  ; update
  parray aRes *.$port.*
  #puts ""
  update
  if {$ret!=0} {
    set gaSet(fail) "Generator's port $port test fail"
#     RLSound::Play information
#     tk_messageBox -type ok -title "Port's $port statistics" -message $gMessage
  }
  return $ret
}


