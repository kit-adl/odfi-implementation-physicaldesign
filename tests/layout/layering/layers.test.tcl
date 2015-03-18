
package require odfi::implementation::techfile 1.0.0
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::partition
set location [file dirname [file normalize [info script]]]

## This Test shows a language addition to create a subtree with some rectangle shaped, which belong to different layers
####


## Define Layers in a technology
#########################################
odfi::implementation::techfile::technology "dummy_tech" {
    
    :techLayer "PO" {
            
    }
    
    :techLayer "M1" {
        
    }
    :techLayer "M2" {
            
    }
    :techLayer "M3" {
            
    }
}


tech.dummy_tech object mixins add odfi::flextree::utils::StdoutPrinter
tech.dummy_tech printAll


## Create  A Partition and add some shapes
#################
puts "*** Creating partition to draw"
odfi::implementation::partition::new "Example" {
    
    :width 500
    :height 500
    
    ## Use SVG
    [current object] object mixins add odfi::scenegraph::svg::SVGBuilder 
    [current object] object mixins add odfi::flextree::utils::StdoutPrinter
    
    ## Use techfile language
    puts "Going to add Techfile"
    [current object] object mixins add [::tech.dummy_tech createLanguage]
    
    #[current object] init
    
    #[current object] allThis

    :inLayer "PO" {
        :rect {
            :width 100
            :height 20
            
            :x 0
            :y 0
        }
        
        :rect {
           :width 100
           :height 20
            
            :x 50
            :y 10
        }
        
    }
    
    #inLayer [::tech.dummy_tech getTechLayer "PO" ] {
        
        :rect {
            :width 100
            :height 20
            
            :x 60
            :y 20
        }
        
    #}
    
    
    
}

set partition [lindex [odfi::implementation::partition::Partition info instances] end]
$partition printAll


#tech.dummy_tech printAll 1



## Map-Reduce
###############
puts "*** Map"
set newSVG [$partition map ::odfi::scenegraph::svg::SVGNode]

$partition printAll

puts "*** SVG"
$newSVG object mixins add odfi::flextree::utils::StdoutPrinter
$newSVG printAll



#set res [$partition shade ::odfi::scenegraph::svg::SVGNode reduce]
set res [$newSVG shade ::odfi::scenegraph::svg::SVGNode reduce]

puts "SVG result: [join $res]"


odfi::files::writeToFile $location/[file tail [info script]].svg $res
