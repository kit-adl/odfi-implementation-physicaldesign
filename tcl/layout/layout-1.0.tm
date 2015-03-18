## Provides TCL Scenegraph connection to 
package provide odfi::implementation::layout 1.0.0

package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::svg 2.0.0
package require odfi::implementation::techfile 1.0.0

namespace eval odfi::implementation::layout {

    #########################
    ## Drawing Trait
    #########################
    nx::Class create DrawInterface  {

      
    }


    ######################
    ## Layout
    ######################
    nx::Class create Layout -superclass odfi::scenegraph::Group -mixins DrawInterface {

        :property -accessor public techFile:required

    }

    proc layout {name keyword techFile closure} {
        
        ## Create 
        set l [Layout new -techFile $techFile]

        #puts "Created layout $l"

        ## Apply 
        $l apply $closure

        ## Return
        return $l
    }


    #######################
    ## Wire
    #######################



    #######################
    ## Via
    #########################
    nx::Class create VIA -superclass odfi::scenegraph::Node {

        ## Real VIA definition object
        :property -accessor public viaDef:required
        

        :public method "-> svg" args {

            ## Create Stream
            set out [odfi::common::newStringChannel]

            puts "SVG draw of a VIA of type ${:viaDef} "

            ## Create Group
            set viaSVG [odfi::scenegraph::svg::group {

                

                ## Bottom Layer  enclosure
                puts "Bottom layer: [${:viaDef} bottomLayer] -> enclosure: [${:viaDef} bottomLayerEnclosure]"
                :rect {
                    set hEnc [lindex [${:viaDef} bottomLayerEnclosure] 0]
                    set vEnc [lindex [${:viaDef} bottomLayerEnclosure] 1]
                    
                    :left [expr $hEnc *1000]
                    :width [expr (2*$hEnc+[${:viaDef} cutWidth])*1000]

                    :down [expr $vEnc *1000]
                    :height [expr (2*$hEnc+[${:viaDef} cutHeight])*1000]

                    :color blue

                    ## Index
                    :z-index [[${:viaDef} bottomLayer] index]
                }

                ## Draw Cut Layer 
                puts "Cut layer: [${:viaDef} cutLayer] -> enclosure: [${:viaDef} cutWidth]x[${:viaDef} cutHeight]"
                :rect {
                    :width   [expr [${:viaDef} cutWidth] *1000]
                    :height  [expr [${:viaDef} cutHeight] *1000]

                    ## Index
                    :z-index [[${:viaDef} cutLayer] index]

                    :color red
                    :opacity .5
                }

                ## Top Layer
                puts "Top layer: [${:viaDef} topLayer]"
                :rect {
                    set hEnc [lindex [${:viaDef} topLayerEnclosure] 0]
                    set vEnc [lindex [${:viaDef} topLayerEnclosure] 1]
                    
                    :left [expr $hEnc *1000]
                    :width [expr (2*$hEnc+[${:viaDef} cutWidth])*1000]

                    :down [expr $vEnc *1000]
                    :height [expr (2*$hEnc+[${:viaDef} cutHeight])*1000]

                    :color darkgreen
                    :opacity .75

                    ## Index
                    :z-index [[${:viaDef} topLayer] index]
                }

            }]

            ## Translate coordinates
            $viaSVG translateToOrigin

            ## Return
            return $viaSVG


        }

    }

    ## Register Interface into draw interface 
    nx::Class create VIADraw  {

        DrawInterface mixins add VIADraw

        ## @return the Create VIA object Name
        :public method via name {
            
            ## Search for VIA 
            set viaDef [${:techFile} getVIADef $name]
            puts "TF: ${:techFile}, via: $viaDef"

            ## Create VIA Object
            set via [VIA new -viaDef $viaDef]

            ## Add to group
            :add $via

            ## Return
            return $via

        }

        
    }


   

}
