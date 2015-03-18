

package require odfi::scenegraph
package require odfi::scenegraph::layouts
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

    ## Add All macros 
    add $instances

    ## Automatic layout
    layout flowGrid {
        spacing 5
        rows 2
    }
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
odfi::files::writeToFile "lef-example-grid.svg" $svg


exit 0


odfi::scenegraph::newLayout "flowGrid" {

  ## Get constraints
  set rows    [$constraints getInt rows]
  set spacing [$constraints getInt spacing]

  ## Work on $group variable
  $group each {

  }
  
}
