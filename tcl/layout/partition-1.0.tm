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