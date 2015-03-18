
package require odfi::richstream 3.0.0

set res {}

proc render args {

    set outs [::new odfi::richstream::RichStream #auto]
    $outs puts "
    
        Hello 
            World2
    "
        
    return [$outs toString]


    return "
    
    Hello
        World
    
    "
    

}


lappend res [render]
lappend res [render]

set lbd {

    set outs [::new odfi::richstream::RichStream #auto]
    $outs puts [join $args]    
    puts "PAssed args: [join $args]"
    
    return [$outs toString]    
    
    return [join $args]
    
}
set res [odfi::closures::applyLambda $lbd [list args $res]]



puts "Res:"
puts $res