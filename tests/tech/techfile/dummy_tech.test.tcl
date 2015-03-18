

package require odfi::implementation::techfile
package require odfi::files 2.0.0
package require nx::serializer

set location [file dirname [file normalize [info script]]]

## Parse
set res [odfi::implementation::techfile::Techfile parse "$location/../../data/techfile/dummy_tech.tf"]

## Serialize
odfi::files::writeToFile $location/dummy_tech_ser.tcl [$res serialize]

