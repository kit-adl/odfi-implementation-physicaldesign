package provide odfi::implementation::sdc     1.0.0
package require odfi::language::nx 1.0.0

odfi::language::nx::new ::odfi::implementation::sdc {

    +type IOConstraint {
        
        :all_outputs {
        }
        
        :all_inputs {
        
        }
    
    }

    :constraintMode name {
        +exportToPublic

        +method read_sdc fileOrContent {

            set ::odfi::implementation::sdc::import::currentMode [current object]
            namespace inscope ::odfi::implementation::sdc::import "
            source $fileOrContent
            "
        }
        
        
        ## Elements
        #############
        :clock name {
        
            +var waveform ""
            
            +method 50percentCycle freq {
            
            }
            
            :inputDelay : IOConstraint value {
            
            }
            
            :outputDelay : IOConstraint value {
            
            }
            
        }

    }


}

namespace eval ::odfi::implementation::sdc::import {

    variable currentMode ""

    proc getProcParam {iargs name outVar} {
        
        set index [lsearch -exact $iargs $name]
        if {$index>=0} {
            uplevel [list set $outVar [lindex $iargs [expr $index+1]]]
        }
    
    }

    ## Functions
    ##################

    proc get_port name {

    }

    proc all_inputs args {

    }

    proc all_outputs args {

    }

    proc create_clock args {
    
        ## get params
        getProcParam $args -name name
        getProcParam $args -period period
        
        ${::odfi::implementation::sdc::import::currentMode} clock $name {
            :50percentCycle $period {
            
            }
        }
    
    }

    proc set_clock_uncertainty args {

    }

    proc set_input_delay args {

    }
    
    proc set_output_delay args {
    
    }
    
    proc set_driving_cell args {
    
    }
    
    proc set_load args {
    
    }

    ## Utils
    proc remove_from_collection {base remove} {

        set res {}
        foreach i $base {
            if {[lsearch -exact $remove $i ]==-1} {
                lappend res $i
            } else {

            }
        }

        return $res
    }

}