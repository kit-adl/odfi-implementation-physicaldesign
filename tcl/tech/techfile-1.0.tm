package provide odfi::implementation::techfile 1.0.0

package require nx 2.0.0
package require odfi::common
package require odfi::closures 3.0.0
package require odfi::files 2.0.0
package require odfi::flist 1.0.0
package require odfi::flextree 1.0.0
package require odfi::nx::domainmixin 1.0.0

namespace eval odfi::implementation::techfile {
    
    

    ############################
    ## Main Techfile 
    ############################
    
    ## Create a technolofy object. The object is named ::tech.$name for code simplicity
    proc technology {name closure} {
     
        set tech [TechFile create ::tech.$name -name $name]
        $tech apply  $closure
        
        return $tech
        
    }
    
    nx::Class create TechFile -superclass odfi::flextree::FlexNode {

        :property -accessor public name
        
        :property -accessor public techLayers

        :property -accessor public viaDefinitions

        :public method init args {
            #set :techLayers [odfi::flist::MutableList new]
            #set :viaDefinitions [odfi::flist::MutableList new]
            next
        }

        ## Techlayers 
        #######################
        
        ## Create a techLayer
        :public method techLayer {name closure} {
            
            set techLayer [TechLayer new -name $name -shortname $name -index [[:shade [namespace current]::TechLayer children] size]]
            :add $techLayer
            $techLayer apply $closure
            
            return $techLayer
            
        }
        
        :public method addTechLayer {layer} {
            
            :add $techLayer
            
            #${:techLayers} += $layer
        }

        :public method getTechLayer name {
            
            ## Look in the the children
            return [[:shade [namespace current]::TechLayer children] find { 
                            
                #puts "Tech search testing [$it name get] <-> $name"
                if {[$it name get] == $name} {
                    return true
                } else {
                    return false
                }

            } -errorMessage "Could not find TechLayer $name" ]
            
           
        }

        ## VIADEFS 
        ########################

        ## Add a VIA definition to the list of VIA definitions
        :public method addVIADefinition viaDef {
            ${:viaDefinitions} += $viaDef
        }

        ## Search for a VIA definition 
        :public method getVIADef name {

            return [${:viaDefinitions} find { 
                
                if {[$it name get] == $name} {
                    return true
                } else {
                    return false
                }

            } -errorMessage "Could not find VIA $name" ]

        }

        :public method eachVIADef closure {
            ${:viaDefinitions} foreach $closure -level 2
        }

        ## Language
        ################
        
        ## Creates a Class holding teh TechnologyLanguage Mixin, and the link to current technology 
        :public method createLanguage args {
            
            ## Create
            set languageName ${:name}Language 
            nx::Class create $languageName  {
             
                upvar :name tn
                #:variable techFile "::tech.${tn}"
                
               
                :property -accessor public [list techFile "::tech.${tn}"]
    
                :public method inLayer {name closure} {
                            
                    puts "In layer of current: [[current object] info class]"
                    
                    set techLayer [${:techFile} getTechLayer $name]
                    
                    puts "Techlayer: [$techLayer info class]"
                    set added [:childrenDifference $closure]
                    
                    puts "Added CT: [$added size]"
                    $added foreach {
                        ##$it addParent $techLayer
                        $techLayer add $it
                        puts "Added stuff: [$it info class]"
                        [$it parents] foreach {
                          p => 
                            puts "-- Parent: [$p info class]"
                        }
                    }
                    
                }
            }
            return [namespace current]::$languageName
            
            
            
        }
        
    }

    nx::Object create Techfile {

        :public object method parse file {

            ## File or stream
            set stream $file
            if {[file isfile $file]} {
             set stream [open $file]   
            }
            puts "Parsing $file -> $stream in [namespace current]"
            
            set reader [odfi::files::LineReader new $stream]
            
            ## Prepare Resulting Techfile instance
            set techFile [TechFile new]

            ## Parse TechLayers
            ###################
            $reader section "techLayers(" ") ;techLayers" {

                #puts "Found Techlayers section"

                ## Skip First three lines 
                ###########
                $sectionReader skipLines 3

                ## Each Line is a layer 
                #################
                $sectionReader eachLine {
                    

                    ## Extract 
                    regexp {\(\s+([\w]+)\s+([0-9]+)\s+([\w]+)\s+\)} $line -> name index shortname

                    ## Create and add 
                    set layer [TechLayer new -name $name -index $index -shortname $shortname]
                    $techFile addTechLayer $layer

                    #puts "Techlayer: $name -> $index"
                }
            }


            ## Parse VIAS
            ####################
            $reader section "standardViaDefs(" ") ;standardViaDefs" {
                
                #puts "Found Vias"
                ## Ignore 5 first lines of definitions
                $sectionReader skipLines 5

                ## Get all input 
                set fullInput [$sectionReader read]

                ## use regexp to parse VIA def format
                set defReg {
                    ([\w_]+)\s+ ([\w]+)\s+ ([\w]+)\s+
                    \(([0-9.]+|(?:"[\w_]+"))\s+ ([0-9.]+)\s+ ([0-9.]+)\s* ([0-9.]+)?\s*\)\s*
                    \(([0-9.]+)\s+ ([0-9.]+)\s+ \(([0-9.]+\s+[0-9.]+)\s*\)\s*\)\s*
                    \(([0-9.]+\s+[0-9.]+)\s*\)\s* \(([0-9.]+\s+[0-9.]+)\s*\)\s* \(([0-9.]+\s+[0-9.]+)\s*\)\s* \(([0-9.]+\s+[0-9.]+)\s*\)\s* \(([0-9.]+\s+[0-9.]+)\s*\)\s*  }

                #regexp "(?xm)$defReg" $fullInput -> \
                    name layer1 layer2 cutLayer cutWidth cutHeight resistancePerCut \
                    cutRows cutCol cutSpace \
                    layer1Enc layer2Enc layer1Offset  layer2Offset  origOffset

                set allMatches [regexp -all -inline "(?xm)$defReg" $fullInput]
                foreach {fullMatch name layer1Name layer2Name cutLayerName cutWidth cutHeight resistancePerCut \
                    cutRows cutCol cutSpace \
                    layer1Enc layer2Enc layer1Offset  layer2Offset  origOffset} $allMatches {
                    
                    #puts "Matched via def: $name from $layer1Name to $layer2Name"

                    ## Search for Layers 
                    ############
                    set layer1 [$techFile getTechLayer $layer1Name]
                    set layer2 [$techFile getTechLayer $layer2Name]
                    set cutLayer [$techFile getTechLayer [string map {"\"" ""} $cutLayerName]]

                    ## Create VIA Object and add 
                    #########################
                    set via [VIADef create $name -name $name \
                                            -bottomLayer $layer1 \
                                            -topLayer $layer2 \
                                            -cutLayer $cutLayer \
                                            -cutLayerSize [list $cutWidth $cutHeight] \
                                            -bottomLayerEnclosure  $layer1Enc \
                                            -topLayerEnclosure $layer2Enc]
                    $techFile addVIADefinition $via
                }

                
            }

            return $techFile

        }

    }


    ###########################
    ## Techlayer 
    ###########################
    nx::Class create TechLayer -superclass odfi::flextree::FlexNode {

        :property -accessor public name:required
        :property -accessor public index:required
        :property -accessor public shortname:required

    }

    #############################
    ## VIA 
    ####################
    nx::Class create VIADef {

        ## Name
        :property -accessor public name:required

        ## Layers
        :property -accessor public bottomLayer:required
        :property -accessor public topLayer:required
        :property -accessor public cutLayer:required

        ## Cut Layer VIA Size {width height}
        :property -accessor public cutLayerSize:required

        ## Enclosures {left/right top/down}
        :property -accessor public bottomLayerEnclosure:required 
        :property -accessor public topLayerEnclosure:required

        ## Access Methods 
        ###############
        :public method cutWidth {} {
            return [lindex [:cutLayerSize] 0]
        }

        :public method cutHeight {} {
            return [lindex [:cutLayerSize] 1]
        }

    }

    
    
    ## Language Stuff
    #######################
    nx::Class create TechnologyLanguage {
        
        
        
    }
    
}


namespace eval odfi::implementation::techfile::svg {
    
    ## Add trait to techlayer with SVG Modifier
    ##############
    odfi::nx::Class create TechLayerSVGModifier {
        
        [namespace parent]::TechLayer mixins add [namespace current]::TechLayerSVGModifier
        
        
    }
    
    
}
