package require odfi::implementation::layout
package require odfi::scenegraph::layouts 2.0.0
package require odfi::richstream 3.0.0

package require odfi::implementation::interfaces::scad

set location [file dirname [file normalize [info script]]]

## Parse Techfile
#set techFile [odfi::implementation::techfile::Techfile parse "../techfile/umc65ll.tf"]

#set protectedStack [list {elt ::nsf::__#5} {elt ::nsf::__#3} {it ::nsf::__#3} {i 0}]
#puts "Stack search: [lsearch -index 0 -exact -start end -decreasing $protectedStack it]"

#exit 0 

## Create AN SVG View for our PMOS View 
#################
odfi::scenegraph::svg::createSvg layoutSvg -> {

    ## Substrate
    :rect {
        :width 500
        :height 500
        :depth  5
    }

     
    #return 
    ## That is a Bulk area (P-Type)
    :rect {

        :color set lightyellow
        :depth 50

        ## Add two N parts 
        ::repeat 2 {
            :rect {
                :color set green
                :width  25
                :height 50
                :depth  [expr 25]
               
            }
        }
       ## ::repeat 2 

        #puts "Current Object [current object]"

        :layout "row" {
            
            spacing 20
        }
        :layout "reverseZ"

        #:width 200
        #:height 100
        
        
    }

    
    :group "go" {
        ## Add Gate oxyde
        :rect {
            :color set gray
            :width 20
            :height 50
            :depth 3

          

            #:setZ 100
        }

        ## Add Gate Poly
        :rect {
            :color set red
            :width 20
            :height 50
            :depth 10

            #:setZ 100
        }
        :layout "stack" {
            x 25
        }
    }
    

    :layout "stack" 

}

## Output SVG for the record 
#################################
#exit 0
## Map reduce
#set svgRes [$layoutSvg reduce]

#odfi::files::writeToFile "tech_draw_pmos.svg" [$layoutSvg toString]

#odfi::files::writeToFile $location/[file tail [info script]].svg [$layoutSvg reduce]


## Auto Convert to SCAD
#############
puts "****** CAD Reduce"
## Out
set res [$layoutSvg reduceToSCAD]
odfi::files::writeToFile $location/[file tail [info script]].scad $res
 



exit 0

set outs [::new odfi::richstream::RichStream #auto]
set defaultThickness 3
set writeSCADClosure {

    puts "Object. [$it info class]"
    #puts [expr ("::odfi::scenegraph::svg::Rect"== "::odfi::scenegraph::svg::Rect" ) ]
    if {[odfi::common::isClass $it ::odfi::scenegraph::svg::Rect]} {


                
        ## If Some children are present, make a difference of them
        if {[$it size] >0} {

            ## The Color of the main rect goes after the difference has been applied

            $outs puts "
            // Container
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
            $it each $writeSCADClosure
            #::puts "************ EOF CHILD DIFF, it is $it ********"
            #$it each $writeSCADClosure

            ## EOF difference
            $outs puts "}"

            ## Always output children
            $outs puts "
                // Now Output normal children $it -> [$it size] 
            "    
            $it each $writeSCADClosure

            ## EOF Position
            $outs puts "}"

        } else {

            ## X Position is absolute or relative depending if we are inside another rectangle or not
            set differenceParent [odfi::common::isClass [$it parent] ::odfi::scenegraph::svg::Rect]
            set x [expr $differenceParent? [$it getX] : [$it getAbsoluteX] ]
            set y [expr $differenceParent? [$it getY] : [$it getAbsoluteY] ]
            set z [expr $differenceParent? [$it getZ] : [$it getAbsoluteZ] ]
           

            $outs puts "

            // Rect 
            translate(\[$x, $y, $z \])
                color(\"[$it color get]\")
            "

            if {[$it getDepth]>0} {
                $outs puts "  linear_extrude(height = [$it getDepth], center = false, convexity = 10, twist = 0)"
            }
            $outs puts " square(\[ [$it getWidth],  [$it getHeight] \]);"

            ## Always output children
            $it each $writeSCADClosure

        } 


        
        
    
    } elseif {[odfi::common::isClass $it ::odfi::scenegraph::svg::Group]} {

        ## Always output children
        $it each $writeSCADClosure

    }
        
}

#puts $outChan "render(convexity = 2) {"
$layoutSvg each $writeSCADClosure 

#puts $outChan "}"

## Out
set res [$outs toString]
puts "Script: "
puts  $res
        
odfi::files::writeToFile $location/[file tail [info script]].scad $res
 
