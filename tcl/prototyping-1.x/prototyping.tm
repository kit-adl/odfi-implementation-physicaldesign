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
package provide odfi::implementation::edid::prototyping 1.0.0
package require odfi::common
package require odfi::list 2.0.0


namespace eval edid::prototyping::fp {

    odfi::common::resetNamespaceClasses [namespace current]


    #####################################################
    ## Factories
    #####################################################

    ## \brief Creates a new Group.
    proc newGroup {name closure} {

        ## Create Group
        return [uplevel :[list ::new ::edid::prototyping::fp::Group $name $closure]]

    }

    #####################################################
    ## Layouting Stuff
    #####################################################
    array set supportedLayouts {}

    ## Describes a layout. Scripts provided in #newLayout will be added to such an object
    itcl::class Layout {

        public variable id
        public variable script

        ## The group variable will be filled when layouting is called, before evaluating script
        public variable group

        ## This variable will be filled with constraints provided by user, or an empty set
        public variable constraints

        private variable emptyConstraints

        constructor {cId cScript} {
            set id $cId
            set script $cScript
            set emptyConstraints [namespace current]::[[namespace parent]::Constraints #auto]
        }

        ## \brief Layout the given set of objects using this layout script function. objects is copied to class objects variable
        # @return nothing, the layout function updates the nodes positions
        public method layout {fgroup {cstr ""} } {



            if {$cstr==""} {
                set constraints $emptyConstraints
            } else {

                ## Adapt constraints if necessary
                ##########

                #puts "PRovided constraints: $cstr"

                ## IF object is already a constraints set, keep like this, if not, create constraints set
                if {[llength [itcl::find objects $cstr -class [namespace parent]::Constraints]]==0} {
                    #puts "Creating constraints object"

                    set constraints [[namespace parent]::newConstraints $cstr]
                } else {
                    set constraints $cstr
                }

            }
            set group $fgroup
            eval $script

        }

        ## Group The members node togetehr, and return a new Group object
        public method group {members {cstr ""}} {

            ## Create group
            set group [namespace current]::[[namespace parent]::Group #auto $members]

            ## Layout
            layout $group $cstr

            ## Return
            return $group
        }


    }

    ## Represents Constraints for layouting
    itcl::class Constraints {

        ## The simple named parameters constraints
        public variable parameters {}

        ## \brief Records some constraints provided in pList using "name value" pairs
        public method addConstraints pList {

            foreach {name value} $pList {

                ## Overwrite if existing
                set index [lsearch -exact $parameters $name]
                if {$index!=-1} {
                    set valueIndex [expr $index+1]
                    set parameters [lreplace $parameters $valueIndex $valueIndex $value]
                } else {

                    #puts "Adding constraints: /$name/ with value $value"
                    lappend parameters $name
                    lappend parameters $value
                }



            }
        }

        ## \brief Mergin the values of otherConstraints into those constraints
        ##        Already existing constraints are overwritten
        ## @param otherConstraints A list of constraints, or an object
        ## @return This object to allow stream interface
        public method merge otherConstraints {

            if {[odfi::common::isClass $otherConstraints [namespace current]]} {
                addConstraints [$otherConstraints cget -parameters]
            } else {
                addConstraints $otherConstraints
            }

            return $this

        }


        ## \brief Returns the named constraint as an int, or the provided #default parameter value
        public method getInt {name {default 0}} {

            ## Search
            set res [lsearch -exact $parameters $name]

            #puts "Searching constraint: $name, res: $res"

            ## Return default if nothing
            if {$res==-1} {
                return [expr int($default)]
            } else {
                return [expr int([odfi::common::resolveVariable [lindex $parameters [expr $res+1]]])]
            }

        }

        ## \brief Returns the named constraint as a "true"/"false" string, or the provided #default parameter value
        # The default value is false
        public method getTrueFalse {name {default false}} {

            ## Search
            set res [lsearch -exact $parameters $name]

            ## Return default if nothing
            if {$res==-1} {
                return $default
            } else {
                return [odfi::common::resolveVariable [lindex $parameters [expr $res+1]]]
            }

        }
    }

    ## \brief Registers a new layout object und provided id, and given implementation script
    # @return the object representing the layout
    proc newLayout {id script} {

        ## Create Object and Register
        ##################
        set obj [::new [namespace current]::Layout ::layout.$id $id $script]

        puts "Registered layout $obj under $id name"
        set [namespace current]::supportedLayouts($id) $obj

        return $obj

    }


    proc newConstraints values {

        ## Create Constraints
        set constraints [namespace current]::[Constraints #auto]
        $constraints addConstraints $values

        return $constraints



    }




    #####################################################
    ## Scene Graph like interface for floorplaning
    #####################################################
    itcl::class Node {

        ## The parent node of this node
        public variable parent ""

        public variable x 0
        public variable y 0

        ## The orientation of this node R0 R90 R180... encounter rotation placement
        public variable orientation R0

        ## \brief Executes the provided closure into this object
        public method apply closure {
            ::odfi::closures::doClosure $closure
        }

        ## Returns an ID string for this object
        public method getId args {
            return $this
        }


        ## \brief Set the parent of this node to the provided obj
        public method setParent obj {
            set parent $obj
        }

        ## \brief returns the parent object of this node. "" if not defined
        public method getParent args {
            return $parent
        }

        ## \brief Invalidates the parent's size cache if there is a parent, and it is a group
        public method invalidateParentSize args {
            if {$parent!="" && [odfi::common::isClass $parent [namespace parent]::Group]} {
                $parent invalidateSize
            }
        }

        ## \brief Changes the orientation of node to get a mirrored on X Axe
        public method mirrorX args {

            if {$orientation == "R0" || $orientation == "R180"} {
               set orientation "MX"
            } elseif {$orientation == "MX"} {
                set orientation "R90"
            } elseif {$orientation == "R90" || $orientation == "R270"} {
                set orientation "MY90"
            } elseif {$orientation == "MY90"} {
                set orientation "R90"
            }

        }

        ## \brief Changes the orientation of node to get a mirrored on Y Axe
        public method mirrorY args {

            if {$orientation == "R0" || $orientation == "R180"} {
                set orientation "MY"
            } elseif {$orientation == "MY"} {
                set orientation "R0"
            } elseif {$orientation == "R90" || $orientation == "R270"} {
                set orientation "MX90"
            } elseif {$orientation == "MX90"} {
                set orientation "R90"
            }

        }

        ## \brief Return orientation
        public method getOrientation args {
            return $orientation
        }

        ## \brief Set orientation
        public method setOrientation orient {
            set orientation $orient
        }

        ## \brief return X position relative to parent
        public method getX args {
            return $x
        }

        ## \brief Set X position relative to parent
        public method setX fX {
            set x [expr $fX < 0 ? 0 : $fX]
            invalidateParentSize
        }

        ## \brief return Y position relative to parent
        public method getY args {
            return $y
        }

        ## \brief Set Y position relative to parent
        public method setY fY {
            set y [expr $fY < 0 ? 0 : $fY]
            invalidateParentSize
        }

        ## \brief Set The X/Y position of this node
        public method setPosition {x y} {
            setPositionFromList [list $x $y]
        }

        ## \brief Set the X/Y position of this node by passing a list {x y} of the coordinates
        public method setPositionFromList position {
            setX [lindex $position 0]
            setY [lindex $position 1]
        }

        ## \brief Increments the Y position by fy
        public method up fy {
            setY [expr [getY] + $fy]

        }

        ## \brief Decrements the X position by x
        public method down fy {
            setY [expr [getY] - $fy]

        }

        ## \brief Increments the X position by fx
        public method right fx {
            setX [expr [getX] + $fx]

        }

        ## \brief Decrements the X position by fx
        public method left fx {
            setX [expr [getX] - $fx]

        }

        ## \brief Place at #fx from the most right position in parent group, wit
        # @warning Does nothing if no parent
        public method fromRight fx {
            if {$parent==""} {
                return
            }
            #invalidateSize
            puts "From right with size: [getWidth]"
            setX [expr [$parent getWidth] - [getWidth] - $fx]
        }

        ## \brief Returns absolute X position
        public method getAbsoluteX args {

            ## If no Parent, only return this position, otherwise, it is the parents absolute + our x
            if {$parent==""} {
                return [getX]
            } else {
                return [expr [$parent getAbsoluteX]+[getX]]
            }

        }

        ## \brief Returns absolute Y position
        public method getAbsoluteY args {

            ## If no Parent, only return this position, otherwise, it is the parents absolute + our y
            if {$parent==""} {
                return [getY]
            } else {
                return [expr [$parent getAbsoluteY]+[getY]]
            }

        }

        ## \brief Returns absolute position list {x y}
        public method getAbsolutePosition args {

           return [list [getAbsoluteX] [getAbsoluteY]]

        }

        ## \brief Returns the actual Width, meaning that width/height are switched if the orientation defines a R90 R270 MX/Y90 orientation
        public method getWidth args {

            if {$orientation=="R90" || $orientation=="R270" || $orientation=="MX90" || $orientation=="MY90"} {
                return [getR0Height]
            }
            return [getR0Width]

        }

        ## \brief Returns the actual Height, meaning that width/height are switched if the orientation defines a R90 R270 MX/Y90 orientation
        public method getHeight args {

            if {$orientation=="R90" || $orientation=="R270" || $orientation=="MX90" || $orientation=="MY90"} {
                return [getR0Width]
            }

            return [getR0Height]
        }

        ## \brief Returns a list with {width,height} for this node
        public method getSize args {
            return [list [getWidth] [getHeight]]
        }


        ## \brief Get the non oriented Width
        # @warning User must implement this
        public method getR0Width args {
            error "Undefined"
        }

        ## \brief Get the non oriented Width
        # @warning User must implement this
        public method getR0Height args {
            error "Undefined"
        }

    }

    ###################
    ## \brief Group in a florrplaning tree
    ##################
    itcl::class Group {
        inherit Node

        ## This is a list containing the member nodes of the group
        public variable members {}

        ## The last layout used on this group. Used by relayout function
        public variable lastLayout      ""
        public variable lastConstraints ""

        ## \brief R0 Width cache
        public variable r0Width -1

        ## \brief R0 Height cache
        public variable r0Height -1

        ## If some members are Tech Macro, a HardMacro instance is created
        constructor closure {

             ## Eval closure
             if {$closure!=""} {
                odfi::closures::doClosure $closure
             }

        }


        ## \brief Add obj to members list in last position, and set its parent to this group
        # If Some new objects are Tech macro, a hard macro is created
        # @return The added objects, for streaming interface
        public method add obj {
            set newMembers [prepareObjectsForAdd $obj]
            set members [concat $members $newMembers]
            return $newMembers

        }

        ## \brief Add obj to members in first position
        # @return The added objects, for streaming interface
        public method addFirst obj {
            set newMembers [prepareObjectsForAdd $obj]
            set members [concat $newMembers $members]
            return $newMembers
        }

        ## \brief add A new Group to this group
        ## Creates the group using default type
        public method addGroup {name closure} {

            ## Create
            set newGroup [::new [namespace current] [itcl::scope $this]_$name $closure]

            ## add
            return [add $newGroup]

        }

        ## \brief Prepares the obj objects list for adding, by instanciating HardMacros for Macros, and making names fully namespaced
        # @return the prepared list
        private method prepareObjectsForAdd obj {

            set res {}
            foreach o $obj {

                ## If o is not an object name, try to resolve as variable
                ######################
                set existing [itcl::find objects $o]
                if {[llength $existing]==0} {
                    #puts "Object $o not found"
                    set o [odfi::common::resolveVariable $o]
                    set existing [itcl::find objects $o]
                    if {[llength $existing]==0} {

                        ## Try using add Caller namespace
                        set uplevelns [uplevel 2 {namespace current}]
                        set existing [itcl::find objects ${uplevelns}::$o]
                        if {[llength $existing]==0} {
                            error "Adding to group, provided object $o not resolvable to any object"
                        }
                        set o [lindex $existing 0]
                        #puts "not resolved : $uplevelns"


                    }
                    set o [lindex $existing 0]
                }
                #set obj [lindex $existing 0]


                ## Convert tech Macro to HardMacro Node if necessary
                if {[odfi::common::isClass $o "::edid::tech::Macro"]} {
                    set o [$o toHardMacro]
                }

                ## If object name is not fully namespaced, prepend this namespace to it, because it then has been created locally here probably
                if {[string match "::*" $o]==0} {
                    set o [namespace current]::$o
                }

                ## Remove from existing parent
                if {[$o getParent]!=""} {

                    #puts "Object $o had a parent [$o getParent], remove it"
                    [$o getParent] remove $o
                }

                ## Set parent
                $o setParent $this
                lappend res $o
            }

            return $res

        }

        ## \brief Switches the two indexed members of group with each other
        public method switch {first second} {

            ## Get Objects
            set firstMember [member $first]
            set secondMember [member $second]

            ## Replace
            set members [lreplace $members $first $first $secondMember]
            set members [lreplace $members $second $second $firstMember]
        }

        ## \brief Reverses the order of the members list.
        # @warning Doest not use lreverse because of TCL 8.4 compatibility
        public method reverse args {

            set newMembers {}
            foreach m $members {
                set newMembers [concat $m $newMembers]
            }
            set members $newMembers

        }

        ## \brief Remove Given Element
        public method remove obj {
            set objIndex [lsearch -exact $members $obj]
            if {$objIndex!=-1} {
                set members [lreplace $members $objIndex $objIndex]
            }

        }

        ## \brief Remove all empty groups
        public method removeEmptyGroups args {

            each {
                if {[odfi::common::isClass $it [namespace current]] && [$it size]==0} {
                    remove $it
                }
            }

        }

        ## \brief returns a copy of the internal members list
        public method members args {
            return [concat $members]
        }

        ## \brief Returns the group member at specified index
        public method member index {
            return [lindex $members $index]
        }

        ## \brief Search of a member having the given name in its object name
        #   If the name if hierarchical, separated by '/', then each component of the path defines a subgroup, making a sub tree search
        public method memberByName hierName {

            set result ""

            #puts "Searching by name: $hierName"

            ## Split name and init search
            set nameComponents [split $hierName /]
            set groupsToSearch [list [list $this $nameComponents]]
            while {[llength $groupsToSearch]>0} {

                ## Take current Group to search
                set currentGroup [lindex [lindex $groupsToSearch 0] 0]
                set pathToSearch [lindex [lindex $groupsToSearch 0] 1]
                set groupsToSearch [lreplace $groupsToSearch 0 0]

                ## Take first path component
                set firstComponentPath [lindex $pathToSearch 0]

                #puts "---> Exploring $currentGroup for $firstComponentPath, with members $members"

                ## - If path starts with "@", then it is an absolute index
                ## - Otherwise make a name search
                ####################
                if {[string match "@*" $firstComponentPath]} {

                    ## Get Member by index
                    set member [$currentGroup member [string range $firstComponentPath 1 end]]

                    ## Remainining path length == 1, end
                    ## Remainining path length > 1, continue on this member
                    if {[llength $pathToSearch]>1} {
                        lappend groupsToSearch [list $member [lrange $pathToSearch 1 end]]
                    } else {
                        set result $member
                        break
                    }

                } else {

                    ## Is  there a member with a name ending with the provided first path component ?
                    foreach member [$currentGroup members] {


                        set match [string match "*$firstComponentPath" $member]

                        #puts "-------->is $member matching ? $match "

                        if {$match} {

                            ## Match:
                            ## Remainining path length == 1, end
                            ## Remainining path length > 1, continue on this member
                            if {[llength $pathToSearch]>1} {
                                lappend groupsToSearch [list $member [lrange $pathToSearch 1 end]]
                            } else {
                                set result $member
                                break
                            }

                        }

                    }
                    ## End of members search

                }

                if {$result!=""} {
                    break
                }

            }
            ## EOF Recursive loop

            if {$result==""} {
                odfi::common::logWarn "memberByName result empty for $hierName"
            }

            return $result


        }

        ##\brief Returns the number of members of this group
        public method size args {
            return [llength $members]
        }

        ## \brief execute script closure on each element.
        # Available variable: $i for index, $it for actual element
        public method each script {


            set callerNS [uplevel 1 {namespace current}]

            set membersCopy [members]
            for {set i 0} {$i < [llength $membersCopy]} {incr i} {
                eval "uplevel 1 {" "set elt [lindex $membersCopy $i];" "set it [lindex $membersCopy $i];" "$script}"

            }
        }

        ## \brief execute script closure on each element starting at element with index #startIndex.
        # Available variable: $i for index, $it for actual element
        public method eachFrom {startIndex script} {

            set callerNS [uplevel 1 {namespace current}]
            set membersCopy [members]
            for {set i 0} {$i < [llength $membersCopy]} {incr i} {
                if {$i>=$startIndex} {
                    eval "uplevel 1 {" "set elt [lindex $membersCopy $i];" "set it [lindex $membersCopy $i];" "$script}"
                }
            }

        }

        ## \brief Calls script once on each groups of #number of elements. an elts variable provides the group content, the i index provides the group index
        public method eachInGroupsOf {number script} {

            set numberofGroups [expr ceil(double([size])/double($number))]
            set membersCopy [members]
            for {set i 0} {$i < $numberofGroups} {incr i} {

               # puts "eachInGroupsOf index $i of $numberofGroups (num: $number and size: [size])"

                ## Calculate range
                set first [expr $i*$number]
                set last  [expr ($first+($number-1))>=[llength $membersCopy]? [llength $membersCopy]-1 : $first+($number-1)]


                ## create group
                set elts [lrange $membersCopy $first $last]

                ## call script
                eval "uplevel 1 {" "set elts {$elts};" "$script}"
            }


        }

        ## \brief Executes the provided script on all the Subtree
        public method eachRecursive script {

             ## Recursive List initialisation
             ###########
             set elementsToProceed [members]

             ## While
             while {[llength $elementsToProceed]>0} {

                ## Take current Group to search
                set currentElement [lindex $elementsToProceed 0]
                set elementsToProceed [lreplace $elementsToProceed 0 0]

                ## Add all members to list, but only if it is a group
                if {[odfi::common::isClass $currentElement [namespace current]]} {
                    set elementsToProceed [concat $elementsToProceed [$currentElement members]]
                }

                ## Evaluate closure in one uplevel to this
                #set it $currentElement
                ::odfi::closures::doClosure [concat "set it $currentElement;" $script] 1

            }


        }

        ## \brief Works like regroup, with regroups all the members by grouping togeteher the provided #count number
        public method regroupBy {count {layoutName ""} {cstr ""}} {

            eachInGroupsOf $count {

                regroup $elts $layoutName $cstr

            }


        }


        ## Takes the members of this group provided in the members list, group them in a new subgroup, then layout using layoutName
        # @param cstr Can be a constraints object, or a list or paired constraints, in which case an object will be build
        public method regroup {gmembers {layoutName ""} {cstr ""}} {


            ## Resolved list between real objects and string names
            set realMembers {}

            ## Remove group members that are specified in the new group
            ##############
           # puts "Regrouping togeteher $gmembers"
            foreach gmember $gmembers {

                ## If element is not an object, try a byName search
                ###########
                if {[::odfi::common::isClass $gmember [namespace parent]::Node]} {
                    lappend realMembers $gmember
                } else {

                    set found [memberByName $gmember]
                    if {$found!=""} {
                        lappend realMembers $found
                    }

                }

                ## Find element and remove if found
                #set gmemberIndex [lsearch -exact $members $gmember]
                #if {$gmemberIndex!=-1} {
                #    remove [lindex $members $gmemberIndex]
                #}

            }


            ## Create Group
            #####################
            set newGroup [namespace current]::[[namespace parent]::Group #auto "add [list $realMembers]"]
            add $newGroup
            #$newGroup setParent $this

            ## Layout
            ##############
            if {$layoutName!=""} {
                $newGroup layout $layoutName $cstr
            }

            return $newGroup


        }

        ## \brief Adds all gmembers to this group. Each group present in #gmembers will be removed, and their members merged into this group (first lelvel ungrouping)
        public method merge {gmembers} {

            foreach gmember $gmembers {

                ## IF gmember is in the current group, remove it
                ########
                remove $gmember

                ## If Group, merge members into this group
                ##############
                if {[odfi::common::isClass $gmember [namespace current]]} {
                    add [$gmember members]
                } else {
                    add $gmember
                }


            }

        }

        ## \brief Merges all children of this group's subgroup's into this group
        public method ungroupFirstLevel args {


            merge [members]

        }

        ## \brief Layouts the group given the provided layout Name
        public method layout {layoutName {cstr ""}} {

            ## Get The Layout Object
           # set layoutObject $edid::prototyping::fp::supportedLayouts($layoutName)
           set layoutObject ::layout.$layoutName



            ## If group is empty -> don't do anything
            ############
            if {[size]==0} {
                ::odfi::common::logWarn "Tried to layout $this with $layoutName, but group is empty, not doing anything"
                return
            }


            ## Layout
            if {$layoutObject!=""} {

                 ## Save last used layout
                set lastLayout $layoutName

                $layoutObject layout $this $cstr

                 ## Save last used layout
                set lastLayout $layoutName
                set lastConstraints $cstr

                ## Update R0Width and R0Height
                set r0Width  -1
                set r0Height -1

            } else {
                ::odfi::common::logWarn "Tried to layoutusing $layoutName, which was not found"
                return
            }


        }

        ## \brief Layouts the group using the last used layout, and a new set of constraints
        ##  If layout has not been called once before, this does nothing
        public method relayout {{cstr ""}} {

            ## Check
            if {$lastLayout==""} {
                return
            }

            ## Merge Constraints
            if {[llength $lastConstraints]>0} {
                set cstr [concat $lastConstraints $cstr]
            }

            ## We can re-layout
            layout $lastLayout $cstr

        }

        ## \brief Invalidates Width/height cache to force recalculation
        public method invalidateSize args {
            set r0Width  -1
            set r0Height -1

            invalidateParentSize
        }

        ## \brief Returns Width of the group, which is the most right member+width - most left member
        public method getR0Width args {

            ## IF empty -> 0
            if {[size]==0} {
                return 0
            }

            ## If Width already calculated, return
            if {$r0Width>=0} {
                return $r0Width
            }

            set mostLeft [lindex $members 0]
            set mostRight [lindex $members 0]

            foreach m $members {

                set mostRightendX   [expr [$mostRight getX]+[$mostRight getWidth]]
                set actualEndX      [expr [$m getX]+[$m getWidth]]

                set mostLeftX       [$mostLeft getX]
                set actualX         [$m getX]

                ## If actual X+Width is > mostRight, this is the new mostRight
                ## If actual X is < mostLeft, this is the new most left
                if {  $actualEndX > $mostRightendX} {
                    set mostRight $m
                }
                if {$actualX < $mostLeftX} {
                    set mostLeft $m
                }



            }


            set mostRightendX   [expr [$mostRight getX]+[$mostRight getWidth]]
            set mostLeftX       [$mostLeft getX]

           # puts "End of R0 return, most right end X $mostRightendX"
            set r0Width [expr ([$mostRight getX]+[$mostRight getWidth])-([$mostLeft getX])]
            return $r0Width

        }

        ## \brief Returns Height of the group, which is the bottom most member+height - top most member
        public method getR0Height args {

            ## IF empty -> 0
            if {[size]==0} {
                return 0
            }

            ## If Height already calculated, return
            if {$r0Height>=0} {
                return $r0Height
            }

            set mostTop [lindex $members 0]
            set mostBottom [lindex $members 0]

            foreach m $members {

                set mostBottomendY   [expr [$mostBottom getY]+[$mostBottom getHeight]]
                set actualEndY     [expr [$m getY]+[$m getHeight]]

                set mostTopY       [$mostTop getY]
                set actualY         [$m getY]

                ## If actual X+Width is > mostRight, this is the new mostRight
                ## If actual X is < mostLeft, this is the new most left
                if {$actualEndY > $mostBottomendY} {
                    set mostBottom $m
                }
                if {$actualY < $mostTopY} {
                    set mostTop $m
                }



            }
            set r0Height [expr [$mostBottom getY]+[$mostBottom getHeight]-([$mostTop getY])]
            return $r0Height

        }

    }


    ## Represents a hardmacro, created from a Tech Macro definition
    ####################
    itcl::class HardMacro {
        inherit Node

        ##  The tech Macxro object
        public variable macro

        constructor cMacro {
            set macro $cMacro

            ## Get defaults from cMacro
            set orientation [$macro cget -defaultOrientation]

        }

        ## Return name of the macro
        public method getName args {
            return [$macro getName]
        }

        ## \brief Returns the macro R0 Width
        public method getR0Width args {
            return [$macro getWidth]
        }

        ## \brief Returns the macro R0 Height
        public method getR0Height args {
            return [$macro getHeight]
        }

    }



    #####################################################
    ## Floorplan Definition (used to output result prototyping)
    #####################################################

    itcl::class FloorplansViewer {

        common viewerTemplate [file dirname [info script]]/floorplan_template.html

        ## List of floorplans to view
        public variable floorplans {}

        ## Output File
        public variable outputFile

        ## Output Folder
        public variable outputFolder

        public method addFloorplan fp {
            lappend floorplans $fp
        }


        public method plotViewerToFile outputFile {

            puts "Viewer Template: $viewerTemplate"

            #preparePlotting

            set outputFile $outputFile
            set outputFolder [file dirname $outputFile]
            odfi::common::embeddedTclFromFileToFile $viewerTemplate $outputFile $this


        }


    }

    ## Defines A Flooplan
    itcl::class Floorplan {

        inherit Group

        ## Name of the floorplan site
        public variable name ""

        ## Width of the die
        public variable dieWidth

        ## Height of the die
        public variable dieHeight

        ## Position of the core
        public variable coreX
        public variable coreY

        ## Width of the core
        public variable coreWidth -1

        ## Height of the core
        public variable coreHeight -1


        constructor closure {Group::constructor ""} {

            if {$closure!=""} {
                odfi::closures::doClosure $closure
            }

        }

        ## \brief If coreWidth is defined, return it, otherwise rely on parent
        public method getR0Width args {

            puts "Overriden R0Width:$coreWidth "
            if {$coreWidth>0} {
                puts "Returning overriden width"
                return $coreWidth
            }
            return [Group::getR0Width]
        }

        public method getR0Height args {
            if {$coreHeight>0} {
                  return $coreHeight
            }
            return [Group::getR0Height]

        }

    }

    ## Defines a blackbox, that is a cell with a name and an Height.
    ## We can then use this definition to create Block Instances
    itcl::class BlackBox {

        public variable name

        public variable width

        public variable height

        constructor bname {
            set name $bname
        }

        public method setSize {nwidth nheight} {
            set width $nwidth
            set height $nheight
        }

    }


}
