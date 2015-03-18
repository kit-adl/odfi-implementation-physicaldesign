
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::partition
package require odfi::files 2.0.0

set location [file dirname [file normalize [info script]]]

## Load some RAM Definitions
#################

set lef [source $location/../../data/lef/ExampleMacros.lef.tcl]

set block_50x50 [$lef getMacro "ExampleMacro_50x50"]


## Create a Partition
###############
odfi::implementation::partition::new "Example" {
    
    :width 500
    :height 500
    
    :add [$block_50x50 toHardMacro]
    
    :addGroup "A" {
        :add [$block_50x50 toHardMacro]
        
        :add [$block_50x50 toHardMacro]
        
        :layout "row" {
            spacing 20
            
        }
        
    }
    
    :layout "column" {
        spacing 20
        #align-width true
    }
   
    
}

set partition [lindex [odfi::implementation::partition::Partition info instances] end]
puts "Partition is $partition"
## Place some RAMS

## print
$partition object mixins add odfi::flextree::utils::StdoutPrinter

$partition printAll

#exit 0

## Create SVG View
##########
puts "-- SVG MAP"
## Proceed to shade Mapping
set svg [$partition map ::odfi::scenegraph::svg::SVGNode]

$partition printAll

#exit 0

#set svgTree [$partition shadeMap ::odfi::scenegraph::svg::SVGNode]
#puts "SVG tree: $svgTree"

## Output
#####################
puts "--- Output"
#$svg shade ::odfi::scenegraph::svg::SVGNode printAll

## Reduce
###############
set res [$svg shade ::odfi::scenegraph::svg::SVGNode reduce]

set outstream [odfi::common::newStringChannel]
#set res [$svgTree toString $outstream]

#$partition shade ::odfi::scenegraph::svg::SVGNode children

#flush $outstream
#set res [read $outstream]

puts "SVG result: [join $res]"


odfi::files::writeToFile $location/simple_rams.tcl.svg $res

