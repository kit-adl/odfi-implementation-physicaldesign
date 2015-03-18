package require odfi::implementation::techfile 1.0.0
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::partition
set location [file dirname [file normalize [info script]]]


## Test parameters
set fieldsCount 20
set methodsCount 20



## TEst class
###################

nx::Class create Test {

    ::repeat $::fieldsCount {
        :property -accessor public [list a$i 10]
    }
   
    
    ::repeat $::methodsCount {
        :public method test$i args {
            next
        }
    }

}




######################
## Test
###########################

proc test_objects args {

    set objectCounts 1000
    set objects {}
    
    
    ::repeat $objectCounts {
        
        #lappend objects [odfi::flextree::FlexNode new]
        lappend objects [Test new]
    }
    
    foreach obj $objects {
        puts "obj a: [$obj a0 get]"
    }
    
    puts "Done wait  [llength $objects]"
    after 2
    
    puts "Free"
    foreach obj $objects {
        $obj destroy
    }
    unset objects
    after 1000
    
    puts "Done"    
}

proc test_lambda args {
    
    set runCount 250
    set objects {} 
    
    ::repeat $runCount {
    
        odfi::closures::applyLambda {
            lappend objects [::Test new]
        }        
    
    }
    
    puts "Done wait  [llength $objects]"    
    
    
    unset objects
    after 1000
    
    puts "Done"     
    


}


proc test_svg args {
    
    ## 3D info
    set  substrateDepth 20
    set  pDepth         7
    set  pPlusDepth     3
    set  nDepth         7
    set  nPlusDepth     3    
    
    ## Class def
    odfi::nx::Class create NMOS -superclass odfi::scenegraph::Group {
        
        :mixins add odfi::scenegraph::svg::SVGBuilder 
        
        :property -accessor public {length 0.65}
        :property -accessor public {fingers 1}
        :property -accessor public {fingerWidth 10}
        
        :property -accessor public {contactWidth 10}
        
        :property -accessor public {contactSize 5}
        
        
        
        :public method mapNode select {
            
                
                ## Create an SVG Group
                odfi::log::info "Mapping to SVG"
                
                
                set numberofContacts [expr int(floor( ${:fingerWidth} /(2*${:contactSize})))]              
                
                
                :group "[:parent] getName" {
                     
                     ## Repeat for the number of fingers
                     ######################
                     ::repeat ${:fingers} {
                         
                         :group "finger$i" {
                             
                             ### Substrate
                             :rect {
                                 
                                 # Drain and source
                                 ::repeat [expr $i == 0 ? 2 : 1] {
                                     
                                     
                                     :rect {
                                         :color set green                        
                                         :height ${:fingerWidth}
                                         :width  ${:contactWidth}
                                         :depth $nPlusDepth
                                         #:opacity set 0.5 
                                         
                                         ## Add Contacts
                                         :group "contacts" {
                                             ::puts "-------CCC "
                                             ::repeat $numberofContacts {
                                                 :rect {
                                                     :width  ${:contactSize}
                                                     :height ${:contactSize}
                                                     #:z 5   
                                                     :depth 2                                 
                                                     
                                                 }    
                                             }  
                                             ::puts "-------CCC "                                         
                                             set middlepos [expr (${:contactWidth}-${:contactSize})/2]
                                             :layout "column" [list  spacing ${:contactSize} x $middlepos]                        
                                         }                                                                                                                            
                                     }   
                                     
                                     
                                     
                                     
                                 }
                                 
                                 
                                 # Gate 
                                 set g [:rect {
                                      
                                      :height ${:fingerWidth}
                                      :width  ${:length}                        
                                      :color set blue
                                      #:opacity set 0.5  
                                      
                                      :name set "gate"   
                                      
                                      :depth 1                                  
                                      
                                  } ]                   
                                 
                                 
                                 
                                 
                                 # Layout -  Remove Gate from block 
                                 puts "in finger $i"        
                                 $g moveToChildPosition [expr $i == 0 ? 1 : 0]          
                                 :layout "row" {
                                     spacing 0
                                 }    
                                 
                                 :depth $substrateDepth           
                                 :layout "reverseZ"                                 
                                 
                                 :border set "red"                             
                                 
                                 :width [:getWidth]
                                 
                                 ## Move out Gate and contact from group because they go on top
                                 #####
                                 
                                 $g pushUp
                                 #$g detach
                                 
                                 ## Remove Contacts from block
                                 :each {
                                     
                                     $it each {
                                         
                                         $it setX [$it getAbsoluteX]
                                         
                                         $it pushUp
                                         $it pushUp
                                         #$it moveToChildPosition 0         
                                         
                                     }
                                 }
                                 
                                 
                                 
                             }
                             ## EOF Substrate Rect
                             
                             ## Regroup Gate with contacts 
                             set gate [:memberByName "gate"]
                             $gate setZ 0
                             puts "GATE POS: [$gate getX] (index: [:indexOf $gate])"
                             
                             
                             set gatesAndContact [:select [:indexOf $gate] end]
                             :regroup $gatesAndContact -groupClass "odfi::scenegraph::svg::Group"
                             puts "GATE POS: [$gate getX]"  
                             
                             
                             
                             #exit 0                         
                             
                             ## Make Stack with gates
                             :layout "stack" {
                                 spacing 0
                             }                            
                             
                             
                         }
                         ## EOF finger Group
                         
                     }
                     ## EOF fingers repeat
                     
                     
                     
                     ## Layout everyone as row
                     #[:member 0] setX 40
                     :layout "row" {
                         spacing 0
                     }
 
            }
              
            next
        }
        
        :public method getR0Width args {
            return [expr ${:fingers}*${:length}]
        }
        
        :public method getR0Height args {
            return [expr ${:fingerWidth}]
        }
        
    }
    ## EOF Class def
    
    
    ## Test
    ################
    set runCount 1
    set objects {} 
    
    
    ## Create
    ::repeat $runCount {
        
        odfi::closures::applyLambda {
            lappend objects [::NMOS new]
        }        
        
    }

    ## Map
    puts "Done create  [llength $objects]"    
    foreach obj $objects {
       $obj mapNode "-"
    }    
    
    
    puts "Done wait"    
    unset objects
    after 1000
    
    puts "Done"      
    
        

}

proc test_svg_simple args {
    
    set parent [odfi::scenegraph::svg::SVG new]


    
    ## Test
    ################
    set rectCount 200
    set objects {} 
    
    
    ## Create
    ::repeat $rectCount {
        odfi::closures::applyLambda {
            $parent add [odfi::scenegraph::svg::Rect new]
        }              
    }
    
    ## Layout
    set lc 20
    
    odfi::closures::run {    
    ::repeat $lc  {
    #for {set i 0} {$i < $lc} {incr i} 
        
         #::repeat  [${parent} childCount] 
#         for {::set c 1} {$c < [${parent} childCount] } {::incr c} {
#               
#                #set previous [${parent} member [expr $c-1]]     
#                #set newx [expr [$previous getX]+[$previous getWidth]]  
#                       
#         }
    
#    set first [${parent} member 0] 
#    set firsty    [$first getY]            
#    odfi::closures::applyLambda {
#    
#        $parent eachFrom 1 {
#            
#            puts "Layout elt $i"
#            
#            ## X: Previous X + Previous Width + Spacing constraint
#            set previous [${parent} member [expr $i-1]]
#            set newx [expr [$previous getX]+[$previous getWidth]]
#            
#            
#            #puts "Rowed in an element $i with [${:constraints} getInt spacing] to previous"
#            #puts "Putting $elt at: $newx based on px: [$previous getX], pw: [$previous getWidth]"
#            
#            $elt setX $newx      
#            $elt setY $firsty         
#            
#        }        
#    
#    }  
    
       
    
    
        
        ::layout.dummy_row layout $parent        
    }
    }
    
    #::layout.dummy_row layout $parent
    #::layout.dummy_row layout $parent
    #::layout.dummy_row layout $parent
    #::layout.dummy_row layout $parent                
    
    #$parent layout "dummy_row" 
    #$parent layout "dummy_row"     
    
    
    puts "Done wait"    
    unset objects
    $parent destroy
    after 1000
    
    puts "Done"      

}


test_svg_simple






