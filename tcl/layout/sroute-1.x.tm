# ODFI Physical Design TCL Tools
# Copyright (C) 2016 Richard Leys  <leys.richard@gmail.com> , University of Karlsruhe  - Asic and Detector Lab Group
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
package provide odfi::implementation::layout::sroute 1.0.0
package require odfi::implementation::layout 1.0.0 


namespace eval odfi::implementation::layout::sroute {

    nx::Class create SRouter {

        :property -accessor public tech:required
    



        :public method routeAllHorizontally {-layer:required base} {

            ## Process:
            ##  - Look for connections
            ##  - Look for a shape 
            puts "lookinf for connections"

            ## First look for CellView container of base 
            set baseCellView [$base shade odfi::implementation::layout::Cellview child 0]
            if {$baseCellView==""} {
                error "Cannot Run Routing on base object is no Container Instance has been attached to it"
            }

            ## Get target layer 
            set routingLayer [${:tech} getTechLayer $layer]
            if {$routingLayer==""} {
                error "Layer $layer does not exist in Technology File"
           }

            puts "Router: [current object] on $layer"

            set createdShapes {}

            $base shade ::odfi::dev::hw::h2dl::Connection walkBreadthFirst -level 2 {

                puts "* Found Connection: $node, current object is [current object] "

                set from [$node parent]
                set to   [$node child 0]
                
                ## Shapes are contained in the CellView's IO 
                ## On of the parent of the IO can be an IO, which would be the master IO
                ## Try to get Shapes 
                #set fromShape [$from shade odfi::implementation::layout::Rect child 0]
                #set toShape   [$to shade odfi::implementation::layout::Rect child 0]
                set fromBaseIO [$from shade ::odfi::dev::hw::h2dl::Output parent]
                set toBaseIO   [$to shade ::odfi::dev::hw::h2dl::IO parent]

                #puts "From base IO parents: [[$from getParentsRaw] size] -> $fromBaseIO"
                #[$from getParentsRaw]  foreach {
                #    puts "--------> $it [$it info class]"
                #}
                if {$fromBaseIO!=""} {
                 #   [$fromBaseIO children]  foreach {
                 #       puts "--------> From baeIO child: [$it info class]"
                 #   }
                    set fromShape [$fromBaseIO shade odfi::implementation::layout::Rect child 0]
                } else {
                    set fromShape [$from shade odfi::implementation::layout::Rect child 0]
                }
                if {$toBaseIO!=""} {
                    set toShape [$toBaseIO shade odfi::implementation::layout::Rect child 0]
                } else {
                   set toShape   [$to shade odfi::implementation::layout::Rect child 0]

                }
               
                
                ## Cannot connect
                if {$fromShape==""} {
                    odfi::log::warning "Cannot connect [$from name get] to [$to name get] because no shape was set on  [$from name get]"
                } 
                if {$toShape==""} {
                    odfi::log::warning "Cannot connect [$from name get] to [$to name get] because no shape was set on  [$to name get]"
                }

                ## Connect 
                if {$fromShape!="" && $toShape!=""} {

                    puts "** Connecting [$from name get] to [$to name get] "

                    ## Coordinates must be reset in context of their most common parent.
                    ## The Shapes are contained in the CellView definition, this is the source of local coordinates
                    ## The Instance is in the actual main cell view, with the from/to Cellview as master
                    set fromCellView [$fromShape shade odfi::implementation::layout::Cellview parent]
                    set toCellView   [$toShape shade odfi::implementation::layout::Cellview parent]

                    ## The instance is contained in the parent of the IO, as an Instance of the master cell view, or it is the base cellview
                    set fromInstance [[$from parent]  shade odfi::implementation::layout::Instance child 0]
                    if {$fromInstance==""} {
                        set fromInstance [[$from parent]  shade odfi::implementation::layout::Cellview child 0]
                    } 

                    set toInstance [[$to parent]  shade odfi::implementation::layout::Instance child 0]
                    if {$toInstance==""} {
                        set toInstance [[$to parent]  shade odfi::implementation::layout::Cellview child 0]
                    } 
                    #set fromInstance  [expr [$from parent] == $baseCellView  ? $baseCellView : [[$from parent]  shade odfi::implementation::layout::Instance child 0]]
                    #set toInstance    [expr [$to parent]   == $baseCellView  ? $baseCellView : [[$to parent]  shade odfi::implementation::layout::Instance child 0]]
                    #set fromInstance [[$baseCellView  shade odfi::implementation::layout::Instance children] find {expr {[$it master get] == $fromCellView } } ]
                    #set toInstance   [[$baseCellView  shade odfi::implementation::layout::Instance children] find {expr {[$it master get] == $toCellView } } ]
                    #set toInstance   [$baseCellView shade odfi::implementation::layout::Instance children]

                    #puts "** From belongs to $fromInstance ([$fromInstance info class]) at [$fromInstance getX] "
                    #puts "** To   belongs to $toInstance ([$toInstance info class]) at [$toInstance getX] "
                    #puts "Connections Common Cellview parent: $fromInstance / $toInstance "

                    set fromX [expr [$fromInstance getX] + [$fromShape getX]]
                    set toX   [expr [$toInstance getX] + [$toShape getX]]
                    set fromY [expr [$fromInstance getY] + [$fromShape getY]  ]
                    set toY   [expr [$toInstance getY]   +[$toShape getY]  ]
                    set fromHeight [$fromShape getHeight]
                    set toHeight   [$toShape getHeight]
                    
                    ## Get Overlapping Y location
                    set overlap [:overlapTwoLines $fromY [expr $fromY + $fromHeight]  $toY [expr $toY + $toHeight]] 

                    if {[llength $overlap]==0} {
                        #puts "No shape overlap in Y, cannot route straight"
                        continue
                    }
                    set baseY   [expr $fromY > $toY ? $fromY : $toY]

                    #puts "Connection:  X $fromX --> X $toX"
                    ## Get Overlapping Y location 
                    #puts "overlapping : $overlap"
                    


                    #puts "From is in instance: $fromInstance // "

                    ## Route in Correct layer 
                    #puts "Route in layer: ${layer}"



                    ## Route from X and middle of overlap
                    ############

                    set connGroup [$node layout:connection [$node name get] {

                        :setX       [expr [$fromInstance getX] + [$fromShape getX]]
                        #:setY       [expr [lindex $overlap 0] + [lindex $overlap 2] /2]
                        :setY       [expr [lindex $overlap 0]]

                        puts "Current Obkect [[current object] info class]"
                        set connectionShape [:rect {
                            
                            :height     0.28
                            :width      [expr ($toX-$fromX) + [$toShape getWidth]]
                            :title  set "CONNECTION"

                            #puts "Added Rect [:width]x[:height] @[:getX],[:getY] [$toShape getX]-[$fromShape getX]"

                            
                            :umc180:to${layer}

                            
                        }]

                        
                        ## Add VIA if necessary
                        #############
                        set fromShapeLayer  [$fromShape umc180:getTechLayer]
                        set toShapeLayer    [$toShape umc180:getTechLayer]
                        puts "** From Layer $fromShapeLayer to $toShapeLayer over $routingLayer"
                        if {$fromShapeLayer!=$routingLayer} {

                            ## Add a via Shape
                            ## FIXME: Align based on underlying shape width/height
                            [${:tech} getVIADef M1_M2] place [current object] -onlyCut true {


                                :setX       [expr [$connectionShape getX]]
                                :setY       [expr [$connectionShape getY]] 

                                #$baseCellView addChild [current object]

                            }

                        }

                        if {$toShapeLayer!=$routingLayer} {

                            ## Add a via Shape
                            ## FIXME: Align based on underlying shape width/height
                            [${:tech} getVIADef M1_M2] place [current object] {


                                :setX       [expr [$connectionShape getX] + [$connectionShape getWidth] - [:getWidth]]
                                :setY       [expr [$connectionShape getY]] 

                                #$baseCellView addChild [current object]

                            }

                        }


                    }]
                    $baseCellView addChild $connGroup
                    lappend createdShapes $connGroup
                    

                }

                return true

            }

            ## Fix Coordinates: to be improved
            ##  - find all with same Coordinates
            ##  - 
            #####
            set connections [$baseCellView shade ::odfi::implementation::layout::Connection children]
            puts "**************** Found Connections [$connections size]"
            set grouped [$connections groupByAsList {$it getY}]
            puts "**************** $grouped "
            foreach {baseX elements} $grouped {

                $elements foreachWithIndex {
                    $it up [expr $i*0.28+($i*.28)]
                }

            }
            set i 0
            #foreach s $createdShapes {
            #    $s up [expr $i*0.28+($i*.28)]
            #    incr i
            #}

        }


        ## Returns: Empty list or (A B (B-A))
        :public method overlapTwoLines {A1 A2 B1 B2} {

            puts "Calculating overlap of $A1 $A2 $B1 $B2"
            # First reorber A and B to have the lowest Coordinates first 
            if {$A1 > $B1} {
                set temp A1
                set A1 $B1
                set B1 $temp

                set temp A2 
                set A2 $B2 
                set B2 $temp
            }

            ## If B1 in within A line, there is an overlap, otherwise not 
            ## Overlap is then B1 to smaller of A2 and B2
            if {$B1>=$A1 && $B1 < $A2} {

                set end [expr $B2<$A2 ? $B2 : $A2]
                return [list $B1 $end [expr $end-$B1]]


            } else {
                return {}
            }
        }
    }



    
}
