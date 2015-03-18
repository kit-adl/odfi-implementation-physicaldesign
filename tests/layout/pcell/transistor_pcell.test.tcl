
## This Test defines a Transistor node, which is a master cell
## Its subtree can be generated and regenerated to match provided requirements
package require odfi::implementation::techfile 1.0.0
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::partition
set location [file dirname [file normalize [info script]]]


## Define Transitor
#########################



odfi::nx::Class create NMOS -superclass odfi::scenegraph::Group {
    
    :mixins add odfi::scenegraph::svg::SVGBuilder 
    
    :property -accessor public {length 0.65}
    :property -accessor public {fingers 1}
    :property -accessor public {fingerWidth 10}
    
    :property -accessor public {contactWidth 10}
    
    :property -accessor public {contactSize 5}
    
    :public method mapNode select {
                
        odfi::log::info "In shade for partition SVG"
        
        if {$select=="::odfi::scenegraph::svg::SVGNode"} {
            
            ## Create an SVG Group
            odfi::log::info "Mapping to SVG"
            return [:group "[:parent] getName" {
                
                #:width  [[:parent] getR0Width]
                #:height [[:parent] getR0Height]
                #:x [[:parent] x]
                #:y [[:parent] y]
                #:detach

                ## Gates + Contacts
                :group "gates" {
                    
                    ## Add Contact + Gates
                    set numberofContacts [expr int(floor(${:fingerWidth}/${:contactSize}))]
                    ::repeat ${:fingers} {
                        
                        :group "contact" {
                            ::repeat $numberofContacts {
                                :rect {
                                    :width  ${:contactSize}
                                    :height ${:contactSize}
                                    
                                    
                                }    
                            }
                            :layout "column" {
                            }  
                        }
                        
                        :rect {
                            :height ${:fingerWidth}
                            :width ${:length}
                            :color set blue
                            
                        }
                    }
                    
                    ## Add Last contact
                    :group "contact" {
                                                
                        ::repeat $numberofContacts {
                            :rect {
                                :width  ${:contactSize}
                                :height ${:contactSize}     
                            }    
                        }
                        :layout "column" {
                        }
                        
                    }
                    
                    ## Make a row of all this
                    :layout "row" {
                      #spacing {${:contactWidth}}
                      #x {${:contactWidth}}
                    }
                }
                ## EOF Gates + contacts
                
                ## Add Area around all this
                :rect {
                    #:width  [[:parent] getR0Width]
                    #:height [[:parent] getR0Height]
                    
                    ## NUmber of fingers * length, plus the (fingers+1) * contactWidth
                    ## "fingers+1" because there is one drain/source per finger, shared by two fingers
                    #:width [expr ( ${:length} * ${:fingers} )+( ${:fingers} +1)* ${:contactWidth} ]
                    :height ${:fingerWidth}
                    
                    :width [[:parent] getWidth]
                    
                    :color set "black"
                    
                    ## Move to first node to avoid masking the others
                    :moveToFirstNode
                    
                }    
                ## EOF Main area
                
                
                
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
        :fingers set 5
    }
    
    :nmos "N2" {
            
        :length set 10
        :fingerWidth set 100 
        :fingers set 10
        #:detach
    }
    
    :layout "column" {
       spacing 2
    #    
    }
    
    :width 500
    :height 500
    
}

set partition [lindex [odfi::implementation::partition::Partition info instances] end]
$partition printAll


## Map-Reduce
###############
puts "*** Map"
set newSVG [$partition map ::odfi::scenegraph::svg::SVGNode]

$partition printAll

puts "*** SVG"
$newSVG object mixins add odfi::flextree::utils::StdoutPrinter
$newSVG printAll


puts "*** Red ***********************"
#set res [$partition shade ::odfi::scenegraph::svg::SVGNode reduce]
set res [$newSVG shade ::odfi::scenegraph::svg::SVGNode reduce]

puts "SVG result: [join $res]"


odfi::files::writeToFile $location/[file tail [info script]].svg $res
