

set dir [file dirname [file normalize [info script]]]

package ifneeded odfi::implementation::techfile 1.0.0 [list source $dir/tech/techfile-1.0.tm]
package ifneeded odfi::implementation::lef 	1.0.0 [list source $dir/tech/lef-1.0.tm]

package ifneeded odfi::implementation::layout 	1.0.0 [list source $dir/layout/layout-1.0.tm]
package ifneeded odfi::implementation::partition   1.0.0 [list source $dir/layout/partition-1.0.tm]


## Interfaces
##################


package ifneeded odfi::implementation::interfaces::scad 1.0.0 [list source $dir/interfaces/scad-1.0.0.tm]