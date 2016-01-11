

set dir [file dirname [file normalize [info script]]]


package ifneeded odfi::eda::flow                   1.0.0 [list source $dir/flow-1.x/flow-1.x.tm]
package ifneeded odfi::implementation::techfile    1.0.0 [list source $dir/tech/techfile-1.0.tm]
package ifneeded odfi::implementation::lef 	       1.0.0 [list source $dir/tech/lef-1.0.tm]

package ifneeded odfi::implementation::layout 	   1.0.0 [list source $dir/layout/layout-1.0.tm]
package ifneeded odfi::implementation::partition   1.0.0 [list source $dir/layout/partition-1.0.tm]

package ifneeded odfi::implementation::layout::sroute   1.0.0 [list source $dir/layout/sroute-1.x.tm]

## Interfaces
##################


package ifneeded odfi::implementation::interfaces::scad 1.0.0 [list source $dir/interfaces/scad-1.0.0.tm]

## ITCL for Cadence
## Detect Cadence Interface by name of main executable.
## If in RTL Compiler or Encounter, provide ITCL through local module library
###############
set iname [file tail [info nameofexecutable]]
if {$iname=="rc" || $iname=="encounter"} {

    ## RTL Compiler has a different TCL load function name
    set loadFunc [expr {$iname} == {"rc"} ? {"tcl_load"} : {"load"} ]

    ## Provide Package
    package ifneeded Itcl 3.4 "
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
        catch {$loadFunc \"$dir/cadence/libitcl3.4.so\" Itcl}
    }
    puts \"** Warning ** If an error about the source command came out during package loading, please ignore\" 
"
}
unset iname

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
