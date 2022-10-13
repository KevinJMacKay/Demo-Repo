#!/bin/tclsh
 set filename [lindex $argv 0]
 set fp [open "$filename" r]
 set file_data [ read $fp ]
 set data [split $file_data "\n"]
 foreach line $data {
 if {[ string match *PERCENTILES* $line ]} {
 set timeval "[ lindex [ split $line ] 3 ]"
 append xaxis "$timeval\t"
         }
     }
 puts "TIME INTERVALS"
 puts "\t$xaxis"
 foreach storedproc {neword payment delivery slev ostat} {
 puts [ string toupper $storedproc ]
 foreach line $data {
 if {[ string match *PROCNAME* $line ]} { break }
 if {[ string match *$storedproc* $line ]} {
 regexp {MIN-[0-9.]+} $line min
 regsub {MIN-} $min "" min
 append minlist "$min\t"
 regexp {P50%-[0-9.]+} $line p50
 regsub {P50%-} $p50 "" p50
 append p50list "$p50\t"
 regexp {P95%-[0-9.]+} $line p95
 regsub {P95%-} $p95 "" p95
 append p95list "$p95\t"
 regexp {P99%-[0-9.]+} $line p99
 regsub {P99%-} $p99 "" p99
 append p99list "$p99\t"
 regexp {MAX-[0-9.]+} $line max
 regsub {MAX-} $max "" max
 append maxlist "$max\t"
     }
       }
 puts -nonewline "MIN\t"
 puts $minlist
 unset -nocomplain minlist
 puts -nonewline "P50\t"
 puts $p50list 
 unset -nocomplain p50list
 puts -nonewline "P95\t"
 puts $p95list 
 unset -nocomplain p95list
 puts -nonewline "P99\t"
 puts $p99list
 unset -nocomplain p99list
 puts -nonewline "MAX\t"
 puts $maxlist
 unset -nocomplain maxlist
     }
 close $fp