

set dir [file dirname [file normalize [info script]]]


## Flow API
package ifneeded odfi::eda::flow                   1.0.0 [list source $dir/flow-1.x/flow-1.x.tm]


## Technlogy APIs
package ifneeded odfi::implementation::techfile    1.0.0 [list source $dir/tech/techfile-1.0.tm]
package ifneeded odfi::implementation::lef 	       1.0.0 [list source $dir/tech/lef-1.0.tm]

package ifneeded odfi::implementation::libfile     1.0.0 [list source $dir/libfile/libfile-1.x.tm]

package ifneeded odfi::implementation::sdc     1.0.0 [list source $dir/sdc/sdc-1.x.tm]

## Layout and partition Stuff v1 (based on SceneGraph Language)
#####################################
package ifneeded odfi::implementation::layout 	   1.0.0 [list source $dir/layout/layout-1.0.tm]
package ifneeded odfi::implementation::partition   1.0.0 [list source $dir/layout/partition-1.0.tm]

package ifneeded odfi::implementation::layout::sroute   1.0.0 [list source $dir/layout/sroute-1.x.tm]

## OLD: Design API 
##############

package ifneeded odfi::implementation::edid::design               1.0.0 [list source [file join $dir design-1.x design-1.0.0.tm]]
package ifneeded odfi::implementation::edid::design::wviewer      1.0.0 [list source [file join $dir design-1.x design-wviewer-1.0.0.tm]]

## OLD: Prototyping interface 
###############
package ifneeded odfi::implementation::edid::prototyping 1.0.0          [list source [file join $dir prototyping-1.x prototyping.tm]]
package ifneeded odfi::implementation::edid::prototyping::ram 1.0.0     [list source [file join $dir prototyping-1.x ram-1.0.0.tm]]

## Interfaces
##################


package ifneeded odfi::implementation::interfaces::scad 1.0.0 [list source $dir/interfaces/scad-1.0.0.tm]



## This package is a wwrapper for ITCL, in case ITCL would be needed in a vendor tool not supported by this script
package ifneeded vendor::Itcl 3.4 "
    #puts \"Loading ::env(ITCL_LIBRARY) $dir/cadence/\" 
    proc replacement_puts args {}

    # Simple solution borrowed from Stackflow  http://stackoverflow.com/questions/11307898/tcl-stop-all-output-going-to-stdout-channel
    proc silentEval {script} {
        rename puts original_puts
        interp alias {} puts {} replacement_puts
        catch \[list uplevel 1 \$script\] msg opts
        rename puts {}
        rename original_puts puts
        return -options \$opts \$msg
    }
    set ::env(ITCL_LIBRARY) $dir/cadence/ 
    silentEval {
        catch {tcl_load \"$dir/cadence/libitcl3.4.so\" Itcl}
    }
    package provide cadence::Itcl 3.4 
    package require Itcl 3.4
"
