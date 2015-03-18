

package require odfi::scenegraph
package require odfi::files 1.0.0
source tech.tm



## Load LEF File 
set lef [::new Lef #auto "lib.lef"]

## Search macro
set macro [$lef getMacro "ExampleMacro"]

## Create instances
set instances {}
::repeat 4 {
    lappend instances [$macro toHardMacro]
}

## Creat top container
odfi::scenegraph::newGroup top {

    ## Create two groups
    ## Each has two macros 
    addGroup "A" {

        add [lindex $instances 0]
        add [lindex $instances 1]

        ## Set second macro right to first
        [member 1] right [[member 0] getWidth]
        [member 1] right 10
    }

    addGroup "B" {

        add [lindex $instances 2]
        add [lindex $instances 3]

        ## Set second macro right to first
        [member 1] right [[member 0] getWidth]
        [member 1] right 10
    }

    ## Set second group above first 
    [member 1] up [[member 0] getHeight]
    [member 1] up 10
}

## Output SVG
set svg "<svg 
        xmlns=\"http://www.w3.org/2000/svg\" 
        version=\"1.1\" 
        width=\"[top getWidth]\" 
        height=\"[top getHeight]\">"

## Only output macros
top eachRecursive {
    if {[$it isa HardMacro]} {
        set svg "$svg
        <rect x=\"[$it getAbsoluteX]\" 
            y=\"[$it getAbsoluteY]\" 
            width=\"[$it getWidth]\" 
            height=\"[$it getHeight]\" 
            fill=\"gray\"/>"
    }
}

## Write
set svg "$svg</svg>"
odfi::files::writeToFile "lef-example.svg" $svg
