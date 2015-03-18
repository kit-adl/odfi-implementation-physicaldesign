
## This Test defines a Transistor node, which is a master cell
## Its subtree can be generated and regenerated to match provided requirements
package require odfi::implementation::techfile 1.0.0
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::partition
set location [file dirname [file normalize [info script]]]


## Define WireBus Node
#########################



odfi::nx::Class create WireBus -superclass odfi::scenegraph::Group {
    
    :mixins add odfi::scenegraph::svg::SVGBuilder 
    
    :property -accessor public {bits 1}
    
    :property -accessor public {from 0}
    
    :property -accessor public {to 0}
    
    :property -accessor public {spacing 5}
    
    :property -accessor public {wireWidth 5}
    
    
    :public method mapNode select {
                
        odfi::log::info "In shade for partition SVG"
        
        if {$select=="::odfi::scenegraph::svg::SVGNode"} {
            
            ## Create an SVG Group
            odfi::log::info "Mapping to SVG"
            return [:group "wirebus" {
                
                ## Create wires using rect, and layout as column
                ::repeat ${:bits} {
                    :rect {
                        :width abs(${:from}-${:to})
                        :height ${:wireWidth}
                    }
                }
                
            }]
        }
        next
    }
    
    :public method getR0Width args {
        return [expr ${:bits}*${:wireWidth} + (${:bits}-1)*${:spacing} ]
    }
    
    :public method getR0Height args {
        return [expr abs(${:from}-${:to})]
    }
    
}


odfi::nx::Class create WireBusLanguage {
    
    :public method wireBus {bits closure} {
        set n [WireBus new -bits $bits]
        :add $n
        $n apply $closure
        
    }
}


## Draw
###################
odfi::implementation::partition::new "Example" {
    
    
    
    ## Use SVG
    [current object] object mixins add odfi::scenegraph::svg::SVGBuilder 
    [current object] object mixins add odfi::flextree::utils::StdoutPrinter
    [current object] object mixins add WireBusLanguage
    
    :wireBus 10 {
        
        :from set 0
        :to   set 200
    }
    
    
    
    :width 500
    :height 500
    
}

set partition [lindex [odfi::implementation::partition::Partition info instances] end]
#$partition printAll


## Map-Reduce
###############
puts "*** Map"
set svg [$partition mapReduce ::odfi::scenegraph::svg::SVGNode]

puts "SVG result: [join $res]"


odfi::files::writeToFile $location/[file tail [info script]].svg $res
