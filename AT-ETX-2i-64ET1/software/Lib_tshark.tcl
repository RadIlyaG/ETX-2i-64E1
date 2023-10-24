wm  iconify .
#console show
set intf    [lindex $argv 0]
set dur     [lindex $argv 1]
set resFile [lindex $argv 2]
#puts "intf:$intf dur:$dur resFile:<$resFile>"; update
catch {exec C:\\Program\ Files\\Wireshark\\tshark.exe -i $intf -O snmp -a duration:$dur -x -S lIsT -A "c:\\temp\\tmp.cap" > [set resFile]} rr
# after 100
# set id [open $resFile a+]
# puts $id "Frame 99:\n\r"
# close $id
#puts "rr:<$rr>"; update
after 4000 exit
