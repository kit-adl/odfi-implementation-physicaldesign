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
package provide odfi::implementation::partition 1.0.0
package require odfi::implementation::layout 1.0.0

package require odfi::nx::domainmixin 1.0.0

namespace eval odfi::implementation::partition {
    
    cproc new {name closure} {
        
        ## Create 
        set p [Partition new -name $name]
        $p apply $closure
        
        ## Return
        return $p
        
    }
    
    
    ## Partition Node 
    ##########################
    odfi::nx::Class create Partition -superclass odfi::scenegraph::Group {
     
        
        
        
    }
    
    
    
}


## SVG part 
namespace eval odfi::implementation::partition::svg {
    
    
    nx::Class create PartitionSVG -mixins odfi::scenegraph::svg::SVGBuilder {
     
        [namespace parent]::Partition mixins add PartitionSVG
        
        
        :public method mapNode select {
            
            odfi::log::info "In shade for partition SVG"
            
            if {$select=="::odfi::scenegraph::svg::SVGNode"} {
                
                ## Create an SVG Group
                odfi::log::info "Mapping to SVG"
                return [:svg "partition" {
                    :width  [[:parent] getWidth]
                    :height [[:parent] getHeight]
                    
                    #:detach
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
