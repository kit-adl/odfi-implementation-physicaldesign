
## This Test defines a Transistor node, which is a master cell
## Its subtree can be generated and regenerated to match provided requirements
package require odfi::implementation::techfile 1.0.0
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::partition
set location [file dirname [file normalize [info script]]]

package require odfi::implementation::interfaces::scad

## Define Transitor
#########################

## 3D info
set  substrateDepth 20
set  pDepth         7
set  pPlusDepth     3

set  nDepth         7
set  nPlusDepth     3

odfi::nx::Class create NMOS -superclass odfi::scenegraph::Group {
    
    :mixins add odfi::scenegraph::svg::SVGBuilder 
    
    :property -accessor public {length 0.65}
    :property -accessor public {fingers 1}
    :property -accessor public {fingerWidth 10}
    
    :property -accessor public {contactWidth 10}
    
    :property -accessor public {contactSize 5}
    
    
    
    :public method mapNode select {
                
        odfi::log::info "In shade for partition SVG [set :fingerWidth]"
        
        set param1 150
        
        if {$select=="::odfi::scenegraph::svg::SVGNode"} {
            
            ## Create an SVG Group
            odfi::log::info "Mapping to SVG"
            
            
            set numberofContacts [expr int(floor( ${:fingerWidth} /(2*${:contactSize})))]              
            
            
            return [:group "[:parent] getName" {
            
                ## Repeat for the number of fingers
                ######################
                ::repeatf ${:fingers} {
                    
                    :group "finger$i" {
                            
                         ### Substrate
                         :rect {
                         
                             # Drain and source
                             ::repeatf [expr $i == 0 ? 2 : 1] {
                                 
             
                                 :rect {
                                     :color set green                        
                                     :height ${:fingerWidth}
                                     :width  ${:contactWidth}
                                     :depth $nPlusDepth
                                     #:opacity set 0.5 
                                     
                                     ## Add Contacts
                                     :group "contacts" {
                                        ::puts "-------CCC "
                                         ::repeatf $numberofContacts {
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
                
                          
                
            }]           
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


odfi::nx::Class create TechLibLanguage {
    
    :public method nmos {name closure} {
        set n [NMOS new -name $name]
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
    [current object] object mixins add TechLibLanguage
    
    
    
    :nmos "N1" {
        
        :length set 10
        :fingerWidth set 100
        :fingers set 10                                                   
    }
    
    :nmos "N2" {
            
        :length set 10
        :fingerWidth set 100 
        :fingers set 10
        :detach
    }
    
    :layout "column" {
       spacing 2
    #    
    }
    
    :width 500
    :height 500
    
}

set partition [lindex [odfi::implementation::partition::Partition info instances] end]
#$partition printAll


puts "End of tree building"

## Map-Reduce
###############
puts "*** Map"
set newSVG [$partition map ::odfi::scenegraph::svg::SVGNode]
 
#puts "End of map: total children [$newSVG totalChildrenCount]" 


puts "----- memory exploration"
puts "${odfi::closures::protectedStack}"

#memory info


#exit 0
#$partition printAll

puts "*** SVG"
$newSVG object mixins add odfi::flextree::utils::StdoutPrinter
#$newSVG printAll


puts "*** Red ***********************"
#set res [$partition shade ::odfi::scenegraph::svg::SVGNode reduce]
set res [$newSVG shade ::odfi::scenegraph::svg::SVGNode reduce]


puts "SVG result: [join $res]"

exit

odfi::files::writeToFile $location/[file tail [info script]].svg $res


## Auto Convert to SCAD
#############
puts "****** CAD Reduce"
## Out
set res2 [$newSVG reduceToSCAD]
odfi::files::writeToFile $location/[file tail [info script]].scad $res2


## Test
puts "----- memory exploration"
puts "${odfi::closures::protectedStack}"

after 20
puts "----- memory exploration"
puts "${odfi::closures::protectedStack}"

after 5
puts "----- memory exploration"
puts "${odfi::closures::protectedStack}"
set test_var_nc 0
set test_var2_nc 20   
for {set i 0} {$i<200} {incr i} {
    
    set test_var [expr $test_var_nc * ($test_var2_nc**2)]                       
}    


