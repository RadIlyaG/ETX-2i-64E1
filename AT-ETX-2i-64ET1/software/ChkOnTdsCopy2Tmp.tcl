# package require RLAutoUpdate

console show 
#set tdsPath //prod-svm1/tds/AT-Testers/JER_AT/ilya/Tools/AT-Etx203-BattMac
#set s1 //prod-svm1/tds/Temp/ilya/shared/BdikatAutoUpdate
set s1 //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-64ET1/AT-ETX-2i-64ET1
set d1 [file dirname [pwd]]
set s2 //prod-svm1/tds/Temp/ilya/shared/01_AboutHistory
set d2 c://tmpDir/1/2
set noCopyL [list  [pwd]/at-2ib10g-1-w10 ] ; #[pwd]/f3  [pwd]/txt3.txt ;## must be supplied, even empty!!!
set noCopyGlobL [list init*]
set emailL [list ilya_g@rad.com]  ;## must be supplied, even empty!!!    shraga_l@rad.com   rony_e@rad.com

set eachMinutes 1
pack [label .l1 -text "set eachMinutes $::eachMinutes"]
# ***************************************************************************
# CheckOnTdsCopy2Tmp
# ***************************************************************************
proc CheckOnTdsCopy2Tmp {s1 d1 s2 d2 noCopyL noCopyGlobL emailL}  {
  set ret [RLAutoUpdate::CheckUpdates [list $s1 $d1 $s2 $d2] $noCopyL $noCopyGlobL $emailL]
  if {$ret!=0} {exit}
  puts "[clock format [clock seconds] -format %Y.%m.%d-%H.%M.%S] ret:$ret" ; update
  
  after [expr {1000 * 60 * $::eachMinutes}] [list CheckOnTdsCopy2Tmp $s1 $d1 $s2 $d2 $noCopyL $noCopyGlobL $emailL]
}
# CheckOnTdsCopy2Tmp $s1 $d1 $s2 $d2 $noCopyL $noCopyGlobL $emailL 