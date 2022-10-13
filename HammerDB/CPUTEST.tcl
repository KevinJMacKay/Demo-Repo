proc runcalc {} {
set n 0
for {set f 1} {$f <= 10000000} {incr f} {
set n [ expr {[::tcl::mathfunc::fmod $n 999999] + sqrt($f)} ] 
}
return $n
}
#puts "bytecode:[::tcl::unsupported::disassemble proc runcalc]"
set start [clock milliseconds]
set output [ runcalc ]
set end [ clock milliseconds]
set duration [expr {($end - $start)}]
puts "Res = [ format %.02f $output ]"
puts "Time elapsed : [ format %.03f [ expr $duration/1000.0 ] ]"