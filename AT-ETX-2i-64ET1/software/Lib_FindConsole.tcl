# ***************************************************************************
# GuiFindConsole
# ***************************************************************************
proc GuiFindConsole {} {
  if [winfo exists .fc] {
    focus -force .fc
    return {} 
  }
  console show
  toplevel .fc -borderwidth 4 -relief raised
  wm overrideredirect .fc 0
  wm title .fc "Find in Console"
  wm geometry .fc +[expr {10+[winfo x .]}]+[expr {10+[winfo y .]}]

  checkbutton .fc.cs -text "Case Sensitive" -variable ::findConsoleCase
	checkbutton .fc.cr -text "Use Regexp" -variable ::findConsoleRegexp
	pack .fc.cs .fc.cr
  entry .fc.efind -width 70 -textvariable ::findConsoleEntry
  pack  .fc.efind -fill x -padx 8 -pady 8
  #button .fc.bfind -text "Find" -command {FindConsole [.fc.efind get]}
  button .fc.bfind -text "Find" -command "FindConsole \$::findConsoleEntry \
      -case \$::findConsoleCase -reg \$::findConsoleRegexp"
  pack   .fc.bfind  -fill x
  #button .fc.bgoto -text "Go To" -command {GotoConsole [selection get]}
  #pack   .fc.bgoto  -fill x
  button .fc.broll -text "Go To Round" -command {Roll}
  pack   .fc.broll  -fill x
  button .fc.bclear -text "Clear" -command {.fc.efind delete 0 end}
  pack   .fc.bclear  -fill x
  button .fc.bexit -text "Destroy" -command {destroy .fc}
  pack   .fc.bexit  -fill x
  
  bind  .fc.efind <Return> {FindConsole [.fc.efind get]}
  focus -force .fc.efind
  .fc.efind icursor 0
}
# ***************************************************************************
# Roll
# ***************************************************************************
proc Roll {} {
  GotoConsole [lindex $::lFindes $::indxFind] [lindex $::lFindes [expr {1+$::indxFind}]]
  if {$::indxFind<[llength $::lFindes]} {
    incr ::indxFind 2
  }
}

# ***************************************************************************
# FindConsole
# ***************************************************************************
proc FindConsole {str args} {   
  #puts "args:_${str}_ [string length $str]"
  #puts ss
  if {[string match {} $str] || [string match \{\} $str] } {return 0}
  #puts ff
  #return -1
  #puts dd
  console eval "set str \"$str\""  
  console eval "set args [list $args]" 
  console eval {
    
    set truth {^(1|yes|true|on)$}
    set opts  {}
    foreach {key val} $args {
    	switch -glob -- $key {
    	    -c* { if {[regexp -nocase $truth $val]} { set case 1 } }
    	    -r* { if {[regexp -nocase $truth $val]} { lappend opts -regexp } }
    	    default { return -code error "Unknown option $key" }
    	}
    }
    if {![info exists case]} { lappend opts -nocase }
    
    set w .console
    $w tag remove find 1.0 end
    $w tag remove curfind 1.0 end
    $w mark set findmark 1.0
    while {[string compare {} [set ix [eval $w search $opts -count numc -- \
        [list $str] findmark end]]]} {
	    $w tag add find $ix ${ix}+${numc}c
	    $w mark set findmark ${ix}+1c
    }
    $w tag configure find -background yellow ; #$::tkcon::COLOR(blink)
    catch {$w see find.first}
    puts "Matchs' qty. of \'$str\' is [expr {[llength [$w tag ranges find]]/2}]"
    #puts [$w tag ranges find]
    
    set lFindes [list]
    set oppList [list]
    foreach {s e} [$w tag ranges find] {
      lappend lFindes $s
    }
    set lFindes [$w tag ranges find]
    
    for {set i 0} {$i<[llength $lFindes]} {incr i} {
      lappend oppList [lindex $lFindes end-$i]
    }
    consoleinterp eval "
      #.fc.efind insert 0 [list $oppList]
      #.fc.efind icursor 0
      set ::lFindes [list $oppList]
      set ::indxFind 0
    "
  }
}


# ***************************************************************************
# GotoConsole
# ***************************************************************************
proc GotoConsole {args} {
  console eval "
    catch {
      .console tag remove curfind 1.0 end      
      .console see [lindex $args 0]
      .console tag add curfind [lindex $args 1] [lindex $args 0]
      .console tag configure curfind -background gray
      #.console get 1.0 2.0
    } 
  "
}
# ***************************************************************************
# ReadConsoleSel
# ***************************************************************************
proc ReadConsoleSel {} {
  console eval {
    set w .console
    set ss [eval $w get [$w tag ranges sel]]
    puts $ss
    return $ss
  } 
}

