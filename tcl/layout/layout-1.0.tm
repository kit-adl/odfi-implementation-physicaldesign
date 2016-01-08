## Provides TCL Scenegraph connection to 
package provide odfi::implementation::layout 1.0.0

package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::svg 2.1.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::techfile 1.0.0
package require odfi::language 1.0.0


package require odfi::dev::hw::h2dl 2.0.0

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

    ############################
    ## Cells
    ############################
    nx::Class create CellViewDefinition {

    }

    nx::Class create LayoutCellView -superclass odfi::scenegraph::Group {

        :method init args {
            next
        }

    }

    #######################
    ## Shaping and Stuff Language 
    #######################
    odfi::language::Language2 define LAYOUT {

        :shape  {

        }

        :circle : ::odfi::scenegraph::svg::Circle {
            +exportTo   ::odfi::dev::hw::h2dl::IO layout
        }

        :group : ::odfi::scenegraph::Group name {
            +exportTo   ::odfi::dev::hw::h2dl::IO           layout
            +exportTo   ::odfi::dev::hw::h2dl::Connection   layout
            +exportTo   ::odfi::dev::hw::h2dl::Module       layout
            +exportTo   ::odfi::dev::hw::h2dl::Signal       layout
            +exportTo   Group
            +expose name

            ## If added an H2DL Instance, try to find a layout instance to add to group
            +builder {

                :onChildAdded {
                    set child [:child end]
                    if {[$child isClass odfi::dev::hw::h2dl::Instance] && ![$child isClass odfi::implementation::layout::Instance]} {
                        
                        set instance [$child shade odfi::implementation::layout::Instance child end]
                        #puts "ADDDDDEDDD INSTANCE -> $instance "
                        if {$instance!=""} {
                            #:addChild $instance
                            #puts "by by $child from [current object] "
                            :removeChild $child
                            :addChild $instance
                        }
                    }
                }

            }

            :rect : ::odfi::scenegraph::svg::Rect {
                
                +exportTo   ::odfi::dev::hw::h2dl::IO layout
                +exportTo   ::odfi::dev::hw::h2dl::Connection layout
                +exportTo   ::odfi::dev::hw::h2dl::Module layout
                +exportTo   ::odfi::dev::hw::h2dl::Elaboration layout
                +exportTo   Group
            }

            :path : ::odfi::scenegraph::svg::Path {

                +exportTo   ::odfi::dev::hw::h2dl::IO layout
            }

            :instance : ::odfi::scenegraph::Node master {
                +exportTo     ::odfi::dev::hw::h2dl::Module layout

                +method getR0Width args {
                    return [[:master get] getR0Width]
                }

                +method getR0Height args {
                    return [[:master get] getR0Height]
                }
                
            }
        }

        :connection : Group name {
            +exportTo   ::odfi::dev::hw::h2dl::Connection layout
        }

        :cellview : ::odfi::scenegraph::Group library cell view {
            +exportTo     ::odfi::dev::hw::h2dl::Module layout
            +exportTo     ::odfi::dev::hw::h2dl::Elaboration layout
            :+superclass  ::odfi::dev::hw::h2dl::Master
            
            +method getMasterName args {
                return "${:library}_${:cell}_${:view}"
            }
            +method createInstance args {
                return [Instance new -master [current object]]
            }
            
        }

        
    }
    LAYOUT produceNX


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

                    :fill blue

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

                    :fill red
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

                    :fill darkgreen
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

    ###################################
    ## SVG Extension
    ####################################
    nx::Class create SVGBuilder {

        #

        :public method toFile f {

            ## Call SVG 
            odfi::files::writeToFile $f [[:toSVG] reduce]


        }
        :public method toSVG args {

            puts "Start Mapping to svg [:info class]"

            ::set local [current object]
            
            ## Create SVG 
            ::set out [odfi::scenegraph::svg::svg {

            }]


            ::set res  [$local  map -root $out {

               if {[$node isClass odfi::implementation::layout::Cellview]} {

                    #puts "Doing Cell view"
                    return [$parent symbol [$node getMasterName] {
                        
                        
                        :rect {

                            ## Format name 
                            #puts "Layout rect node has parent: [[$node parent] info class]"
                            #set nodeFullName [[$node parent] formatHierarchyString .].[[$node parent] name get]
                            set nodeFullName [$node shade odfi::dev::hw::h2dl::Module formatHierarchyString {return [$it name get]} .]

                            :width      [$node width]
                            :height     [$node height]
                            :setX       [$node getX]
                            :setY       [$node getY]
                            :fill      set  lightgray
                            :title      set  [$node name get]
                            :stroke     set   black
                            :stroke-width set .1
                        }
                    }]

               } elseif {[$node isClass odfi::implementation::layout::Rect]} {

                    #puts "SVG MAP REct"
                    return [$parent rect {

                        ## Format name 
                        #puts "Layout rect node has parent: [[$node parent] info class]"
                        set nodeFullName [$node shade odfi::dev::hw::h2dl::Module formatHierarchyString {return [$it name get]} .]

                        :id     set $nodeFullName
                        :width      [$node width]
                        :height     [$node height]
                        :fill  set [$node fill get]
                        :setX       [$node getX]
                        :setY       [$node getY]
                        :title  set "[$node title get] "
                        :opacity set  .5
                        :stroke  set  [$node stroke get]
                        :stroke-width  set  [$node stroke-width get]

                    }]
                } elseif {[$node isClass odfi::implementation::layout::Path]} {

                    #puts "SVG MAP path"
                    return [$parent path {

                        foreach p [$node points get]  {
                            lappend :points [list [lindex $p 0] -[lindex $p 1]]
                        }
                        :stroke  set [$node stroke get]
                        :setX [$node getX]
                        :setY [$node getY]
                        :title set [$node title get]

                    }]
                 } elseif {[$node isClass odfi::implementation::layout::Circle]} {

                    return [$parent circle {

                        set nodeFullName [[$node parent] formatHierarchyString .].[[$node parent] name get]
                        :id     set $nodeFullName
                        :radius set  [$node radius get]
                        :fill  set [$node fill get]
                        :setX [$node getX]
                        :setY [$node getY]
                        :title set [$node title get]

                    }]
                } elseif {[$node isClass odfi::implementation::layout::Instance]} {

                    #puts "instance to rect [$node name get] [$node getWidth] add to [$parent info class]"

                    ## Make Sure master has been produced 
                    ##########
                    

                    ::set master [$node master get]
                    ::set masterSVG [$master shade odfi::scenegraph::svg::Svg child 0]

                    #puts "Master is $master ([$master getMasterName]) and its Symbol content $masterSVG"
                    if {$masterSVG==""} {

                        #odfi::closures::protect parent
                        #odfi::closures::protect node
                        #puts "Must Produce MAster"
                        ::set masterSVG [$master svg:toSVG]
                        #puts "-- Returned: [$masterSVG info class]"

                        ## Add the symbol definitions to main out 
                        ::set firstSymbol [$masterSVG  shade odfi::scenegraph::svg::Symbol child 0]
                        [$masterSVG shade odfi::scenegraph::svg::Symbol children] foreach {
                            #$it detach
                            $out addChild $it
                        }

                        ## Take the first symbol as master svg   
                        
                        $master addChild $masterSVG
                        #::set masterSVG $firstSymbol

                        #puts "-- Returned as master: [$firstSymbol info class] $firstSymbol"

                        #puts "After producing master, parent is [$parent info class]"
                        #odfi::closures::restore parent
                        #odfi::closures::restore node

                    } else {
                        #puts "Master is there $masterSVG -> [$master info class] // [$masterSVG info class]"

                        ## If there is a master symbol, make sure it is in our output 
                        #$out addChild $masterSVG
                         ::set firstSymbol [$masterSVG  shade odfi::scenegraph::svg::Symbol child 0]
                        [$masterSVG shade odfi::scenegraph::svg::Symbol children] foreach {
                            #$it detach
                            $out addChild $it
                        }

                    }

                   


                    return [$parent use $firstSymbol {

                        
                        #:width      [$node width]
                        #:height     [$node height]
                        :setX        [$node getX]
                        :setY        [$node getY]
                        
                     
                    }]
                } elseif {[$node isClass odfi::implementation::layout::Group]} {

                    #puts "instance to rect [$node name get] [$node getWidth] add to [$parent info class]"
                    #puts "mapping group to group into [$parent info class]"
                    return [$parent group {

                        
                        :title set  [$node name get]  
                        :setX       [$node getX]
                        :setY       [$node getY]

                        #:width      [$node getWidth]
                        #:height     [$node getHeight]
                        #:fill   set black
                        
                     
                    }]
                }
            }]


            #puts "End: [$out size]"
            return $out
             
        }

    }
    Instance domain-mixins add odfi::implementation::layout::SVGBuilder -prefix svg
    Cellview domain-mixins add odfi::implementation::layout::SVGBuilder -prefix svg
    Group domain-mixins add odfi::implementation::layout::SVGBuilder -prefix svg



}
