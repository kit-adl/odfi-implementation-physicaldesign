package provide odfi::implementation::interfaces::scad 1.0.0

package require odfi::richstream 3.0.0
package require odfi::scenegraph::svg 2.0.0
package require odfi::nx::domainmixin 1.0.0

namespace eval odfi::implementation::interfaces::scad {
    
    
    odfi::nx::Class create SCADSVGReduce {
     
        odfi::scenegraph::svg::SVG mixins add SCADSVGReduce
        
        
        :public method reduceToSCAD args {
            
            return [:reduce {
                
           
                
                set outs [::new odfi::richstream::RichStream #auto]
                set defaultThickness 3
                
                puts "Object. [$it info class]"
                #puts [expr ("::odfi::scenegraph::svg::Rect"== "::odfi::scenegraph::svg::Rect" ) ]
                if {[odfi::common::isClass $it ::odfi::scenegraph::svg::Rect]} {
            
            
                            
                    ## If Some children are present, make a difference of them
                    if {[$it size] >0} {
            
                        ## The Color of the main rect goes after the difference has been applied
            
                        $outs puts "
                       
                        
                        translate(\[[$it getAbsoluteX], [$it getAbsoluteY], [$it getAbsoluteZ] \]) {
                        color(\"[$it color get]\") render(convexity=2) difference() {
            
                            // Rect 
                            //translate(\[[$it getX], [$it getY], [$it getZ] \])
                        "
                        if {[$it getDepth]>0} {
                            $outs puts "  linear_extrude(height = [$it getDepth], center = false, convexity = 10, twist = 0)"
                        }
                        $outs puts "    square(\[ [$it getWidth],  [$it getHeight] \]);"
            
                        ## Children
                        $outs puts "
                            // Children to make difference: $it -> [$it size] 
                        "
                            
                        #::puts "************ IN CHILD DIFF, it is $it ********"
                        $it each {
                            $outs puts "translate(\[[$it getAbsoluteX], [$it getAbsoluteY], [$it getAbsoluteZ] \])"
                            $outs puts "   square(\[ [$it getWidth],  [$it getHeight] \]);"
                        }
                            
                        #::puts "************ EOF CHILD DIFF, it is $it ********"
                        #$it each $writeSCADClosure
            
                        ## EOF difference
                        $outs puts "}"
            
                        ## Always output children
                        $outs puts "
                            // Now Output normal children $it -> [$it size] -> [string is list $args]
                        "    
                        
                             if {[string is list $args]==1} {
                                 $outs puts [join $args]
                             } else {
                                 $outs puts $args
                             }                        
                        #$outs puts "$args"
            
                        ## EOF Position
                        $outs puts "}"
            
                    } else {
            
                        ## X Position is absolute or relative depending if we are inside another rectangle or not
                        set differenceParent [odfi::common::isClass [$it parent] ::odfi::scenegraph::svg::Rect]
#                        set x [expr $differenceParent? [$it getX] : [$it getAbsoluteX] ]
#                        set y [expr $differenceParent? [$it getY] : [$it getAbsoluteY] ]
#                        set z [expr $differenceParent? [$it getZ] : [$it getAbsoluteZ] ]
                         set x [$it getAbsoluteX]
                         set y [$it getAbsoluteY]
                         set z [$it getAbsoluteZ]                   
            
                        $outs puts "
            
                        // Rect
                        translate(\[$x, $y, $z \])
                            color(\"[$it color get]\")
                                render(convexity=2)                                 
                        "
            
                        if {[$it getDepth]>0} {
                            $outs puts "  linear_extrude(height = [$it getDepth], center = false, convexity = 10, twist = 0)"
                        }
                        $outs puts " square(\[ [$it getWidth],  [$it getHeight] \]);"
            
                        ## Always output children
                        #$it each $writeSCADClosure
                         if {[string is list $args]==1} {
                             $outs puts [join $args]
                         } else {
                             $outs puts [join $args]
                         }                          
                        #$outs puts "$args"
            
                    } 
            
            
                    
                    
                
                } else {
            
                    ## Always output children
                    #$it each $writeSCADClosure
                    ::puts "*!!*!!*!! Group join length: [llength $args] -> [string index $args 0] -> [string is list $args]"
                    
                    if {[string is list $args]==1} {
                         $outs puts $args
                    } else {
                         $outs puts [join $args]
                    }
                    #$outs puts $args                  
                    
            
                }
                
                # $outs toString                
               return [$outs toString]
                
                
                
            }]
            
            
            
            
            
        }
        
        
    }
    
    
}