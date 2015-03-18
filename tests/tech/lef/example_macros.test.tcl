
package require odfi::implementation::lef
package require odfi::tests

set location [file dirname [file normalize [info script]]]

## Create
set lef [odfi::implementation::lef::Lef::fromFile "$location/../../data/lef/ExampleMacro_333x105.lef"]

## Test
puts "Create LEF: $lef"

## Check Macro
##################
set macro [$lef getMacro "ExampleMacro_333x105"]


odfi::tests::expect "Width" 333.42 [$macro getWidth] 

odfi::tests::expect "Height" 105.28  [$macro getHeight] 

