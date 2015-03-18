


package require odfi::implementation::layout
package require odfi::implementation::techfile

package require odfi::scenegraph::layouts 2.0.0


set location [file dirname [file normalize [info script]]]

## Load Techfile
##################
set techFile [source $location/../../data/techfile/dummy_tech.tcl]

puts "TF: [$techFile info class]"



## Create a Layout
odfi::implementation::layout::layout "top" in $techFile  {

    puts "Hello"

    puts "MX: [odfi::implementation::draw::DrawInterface info method exists b]"


    #:a
    #:b

    [:techFile] eachVIADef {
        puts "Found VIA DEf [$it name]"
    }

    ## Create 2 VIAS 
    #############################
    set m1_poly [:via "M1_POLY"]
    set m1_m2 [:via "M2_M1"]
    
    ## Create / Route Wires 

    

    ###########################
    ## SVG Output 
    ######################

    set viaSVG [$m1_poly -> svg]
    set m1_m2SVG [$m1_m2 -> svg]
  

    odfi::scenegraph::svg::createSvg layoutSvg -> {

        #puts "Layout svg member: [[$layoutSvg member 0] info class]"
        :add $viaSVG 
        :add $m1_m2SVG

        $m1_m2SVG setX 200 
        $m1_m2SVG setY 200

     
    }

    #exit 0

    #puts "Layout svg is: [$layoutSvg info class]"
    #puts "Layout svg member: [[$layoutSvg member 0] info class]"

    set svgString [$layoutSvg toString]
    #puts "[$layoutSvg toString]"
    odfi::files::writeToFile "simple_draw_via.svg" $svgString



    ###############################
    ## SVG -> CAD Conversion
    ###############################

}
