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
package provide odfi::implementation::lef 1.0.0
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::svg 2.0.0
package require odfi::flextree 1.0.0
package require odfi::common

namespace eval odfi::implementation::lef {

    odfi::common::resetNamespaceClasses [namespace current]

    ## Represents a LEF file, and is used to get Macro definitions informations etc...
    nx::Class create Lef {

        ## Path to LEF file
        :property -accessor public {lefPath ""}



        ## Finds the text section matching the given macro name, and return it
        :public method getMacro name {

            ## Read
            ###########
            set f [open ${:lefPath} "r"]
            set content [read $f]
            close $f

            ## Extract
            ##############
            set matches [regexp -inline "MACRO ${name}(.*)END ${name}" $content]
            if {[llength $matches]==0} {
                error "Cannot find macro $name in ${:lefPath}"
            }

            ## Create macro
            ###########
            set macro [Macro new -name $name -textDefinition [lindex $matches 0]]

            return $macro
            ##return [namespace current]::[[namespace parent]::Macro #auto $name [lindex $matches 0]]

        }

        :public object method fromFile f {

            ## Create LEF
            set lef [Lef new -lefPath $f]
            #lef file set $f

            return $lef

        }

    }

    nx::Class create Macro {

        ## Name of the macro
        :property -accessor public name

        ## The default orientation of the Macro, used for orientation setting on created HardMacro
        :property -accessor public {defaultOrientation R0}


        ## The MACRO section of the lef, used to search for informations using regexp
        :property -accessor public textDefinition

        #################################
        ### Extracted informations
        #################################

        :variable -accessor public  {width "-1"}
        :variable -accessor public  {height "-1"}

        :public method init args {

            ## Extract infos
            ########################
            set :width  [lindex  [regexp -inline -line {^\s*SIZE ([0-9\.]+) BY ([0-9\.]+) ;$} ${:textDefinition}] 1]
            set :height [lindex  [regexp -inline -line {^\s*SIZE ([0-9\.]+) BY ([0-9\.]+) ;$} ${:textDefinition}] 2]
        }



        ## Creates a edid::prototyping::fp::HardMacro instance for this macro
        :public method toHardMacro args {

            set hardMacro [HardMacro new -macro [current object]]

            ## Configure defaults
            #$hardMacro orientation set ${:defaultOrientation}

            return $hardMacro

        }

        :public method  showInfo args {

            puts "RAM [getName] , width: [getWidth] ,height: [getHeight]"

        }


        ## \brief Returns the Rectangles defined in the obstruction section for the given layer
        :public method getObs layername {

            #set e "^\s*OBS.*\s*LAYER $layername ;\$(?:^\s*RECT (.*) ;\$)"

            set e "^\s*LAYER $layername ;\$(?:^\s*RECT (.*) ;\$)+"

            set res [regexp -line -inline $e ${:textDefinition}]

            puts "Get obs res: $res"


        }

        ## \brief Returns the Width
        :public method getWidth args {
            return ${:width}
        }

        ## \brief Returns the Height
        :public method getHeight args {

            return ${:height}
        }

    }

    #################
    ## HardMacro
    #####################
    nx::Class create HardMacro -superclass odfi::scenegraph::Node {

        :property -accessor public macro:required

        :method init args {

            ## Get defaults from cMacro
            set orientation [${:macro} defaultOrientation get]
            
            next

        }

        ## Return name of the macro
        :public method getName args {
            return [${:macro} name get]
        }

        ## \brief Returns the macro R0 Width
        :public method getR0Width args {
            return [${:macro} getWidth]
        }

        ## \brief Returns the macro R0 Height
        :public method getR0Height args {
            return [${:macro} getHeight]
        }

    }

} 


namespace eval odfi::implementation::lef::svg {
    
    nx::Class create HardBlockSVG -mixins odfi::scenegraph::svg::SVGBuilder {
         
            [namespace parent]::HardMacro mixins add HardBlockSVG
            
            
            :public method mapNode select {
                
                odfi::log::info "In shade for Hardblock SVG"
                
                if {$select=="::odfi::scenegraph::svg::SVGNode"} {
                    
                    ## Create an SVG Rectangle
                    odfi::log::info "Mapping to SVG"
                    return [:rect  {
                        #:width  [:parent width get]
                        #:height [:parent height get]
                        
                        #odfi::log::info "Parent node is [[:parent] info class] [[:parent] getName] "
                        
                        :width  [[:parent] getR0Width]
                        :height [[:parent] getR0Height]
                    }]
                }
                next
            }
         
            #[namespace parent]::Partition::shadeMapFor ::odfi::scenegraph::SVG {
            #    
            #}
            
            
            #odfi::flextree::shadeMapFor ::odfi::scenegraph::SVG {
            #    
            #}
            
        }

}
