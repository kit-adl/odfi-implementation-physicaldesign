# ODFI Physical Design TCL Tools
# Copyright (C) 2016 Richard Leys  <leys.richard@gmail.com> , University of Karlsruhe  - Asic and Detector Lab Group
# Copyright (C) 2016 Markus Mueller <markus.mueller@ziti.uni-heidelberg.de> , University of Heidelberg - Computer Architecture Group
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
package provide odfi::implementation::flow 1.0.0
package require Itcl 3.4
package require odfi::common 
package require odfi::list 2.0.0

namespace eval edid::flow {

    ## Set to 1 when starting a flow
    variable inflow 0

    ################################################################################
    ## Open Window
    ################################################################################

    ## \brief Opens a mangementWindow
    proc managementWindow args {

        ## Create Window
        #####################
        catch {destroy .edid}
        frame .edid
        wm toplevel .edid 1
        wm title .edid ${edid::designName}

        ## Design Infos
        ########################
        label .edid.designName -text "Design: ${edid::designName}"
        grid .edid.designName -column 0 -row 0 -columnspan 2 -sticky we

        ## Add Reload environment button
        ###################
        catch {destroy .reloadEnvironmentButton}
        button .edid.reloadEnv -text "Reload environment" -command {
                ::edid::reloadEnvironment
        }
        grid .edid.reloadEnv -column 0 -row 1

        catch {destroy .reloadManagerButton}
        button .edid.reloadManagerButton -text "Reload Manager Window" -command {
                ::edid::flow::managementWindow
        }
        grid .edid.reloadManagerButton -column 1 -row 1

        ## Add a button For each step
        ################################
        set count  2
        odfi::list::each [getSteps] {

            puts "Add step: $it"

            ## Component name is the object name, with _ instead of .
            ## because . is used by Tk for component paths
            set stepName [regsub -all {\.} $it "_"]
            set stepName [regsub -all {:} $stepName ""]

            button .edid.$stepName -text "$it" -command "$it reloadExecute"

            grid .edid.$stepName -column 0 -row $count -columnspan 2 -sticky we

            incr count
        }

        #pack .reloadEnvironmentButton -in .edid
        #pack .edid -expand true




        ## Show window
        ####################


    }

    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClassesObjects [namespace current]


    ## Step
    #################################################
    itcl::class Step {

        public variable id

        ## \brief Array with parameters for this step
        public variable parameters

        ## \brief Implementation script to be executed
        public variable implementation

        ## \brief Namespace in which the implementation will be executed
        public variable implementationNS "::"


        public variable preScripts {}
        public variable postScripts {}

        ## The file that was sourced to create Step. This is used by reload function to resource file
        public variable sourceFile

        ## List containing textual expectations of step result to generate Review report
        public variable expectations {}

        ## Stores a description for the step
        public variable description ""

        ## Construct a Step using a qualified id and a script to be run
        constructor args {

            ## Init
            #############
            array set parameters {}

            ## Implementation
            ####################

            ## Get Parent NS, two levels up because created using new Step Factory
            #set topLevel [expr ([info frame] -2 < 1) ? 1 : 2]
            #set parentNs [uplevel 2 namespace current]
            #set implementationNS $parentNs


            #odfi::common::logInfo "Constructing step $this: $parentNs"
            #set implementation $script




        }

        ## \brief applies a closure to the step
        public method apply closure {

            odfi::closures::doClosure $closure
        }

        ## \brief Add some text to result expectations
        public method expect text {
            lappend expectations $text
        }

        public method description desc {
            set description $desc
        }

        ## \brief Add a parameter to the parameters array
        public method withParameter {name default} {

            set parameters($name) $default

        }

        ## \brief Return the parameter value from the parameters array
        public method getParameter name {
            return [lindex [array get parameters $name] 1]
        }

        ## \brief Sets the code definition for the step
        #
        public method withScript script {


            ## Get Parent NS, two levels up because created using new Step Factory
            #set topLevel [expr ([info frame] -2 < 1) ? 1 : 2]
            set parentNs [uplevel 2 namespace current]
            if {$parentNs==[namespace parent]} {
                set parentNs [uplevel 3 namespace current]
            }
            set implementationNS $parentNs
            set implementation $script

            odfi::common::logInfo "Constructing step $this : $parentNs"

        }


        ## \brief Append a script to the current script
        public method addScript script {

            ## Determine Source
            #########################
            set sourceScript [uplevel {::info script}]
            if {$sourceScript==""} {
                set sourceScript default
            }

            ## Add To Post Scripts or replace
            #####################
            if {[odfi::list::arrayContains $postScripts $sourceScript]} {
                set postScripts [odfi::list::arrayReplace $postScripts $sourceScript $script]
            } else {
                lappend postScripts $sourceScript $script
            }

        }

        ## \brief Prepend a script to the current script
        public method prependScript script {

            ## Determine Source
            #########################
            set sourceScript [uplevel {::info script}]
            if {$sourceScript==""} {
                set sourceScript default
            }

            ## Add To Pre Scripts or replace
            #####################
            if {[odfi::list::arrayContains $preScripts $sourceScript]} {
                set preScripts [odfi::list::arrayReplace $preScripts $sourceScript $script]
            } else {
                lappend preScripts $sourceScript $script
            }

            #puts "Prepend from sourced: $sourceScript // $script"

            #set implementation "$script\n$implementation"

        }

        public method reloadInfo args {
            reload
            getInfo
        }

        public method getInfo args {

            ::edid::log "Step Namespace: $implementationNS"
            ::edid::log "Post Scripts: "
            foreach {sourceFile prepscript} $preScripts {
                ::edid::log "--> From $sourceFile"
            }

            ::edid::log "Post Scripts: "
            foreach {sourceFile postscript} $postScripts {
                ::edid::log "--> From $sourceFile"
            }

        }

        ## \brief Returns the implementation code of this step
        # @return The implementation code, with a nice comment providing details on the step
        public method getCode args {

            set result {}
            lappend result "#########################"
            lappend result "## Step: $this"
            lappend result "#########################"
            lappend result ""

            ## Merge PreScripts
            foreach {sourceFile prepScript} $preScripts {
                lappend result $prepScript
            }

            ## Merge Implementation
            lappend result $implementation

            ## Merge postScripts
            foreach {sourceFile postScript} $postScripts {
                lappend result $postScript
            }

            return [join $result "\n"]
        }

        ## \brief Runs the Constructor provided script
        ##  args can contain:
        ##    -simulate : Does not eval code, but prepares everything else
        ##    -inFlow   : Sets the edid::flow::inflow variable so that isInFlow returns 1
        public method execute args {

            ## Parameters
            #################
            if {[lsearch -exact $args -simulate]>-1} {
                set simulate true
            } else {
                set simulate false
            }

            if {[lsearch -exact $args -inFlow]>-1} {
                set edid::flow::inflow 1
            }

            ## ? Catch everything that's coming up to reset correctly inFlow variable
            if {[catch {

                ::edid::log "flow step prepare \"$id\" Preparing step $id"

                ## Add Parameters to execution
                namespace inscope $implementationNS "array set parameters {}"

                #set parametersExtra "array set parameters {}"
                foreach {key value} [array get parameters] {
                    #lappend parametersExtra "set parameters($key) $value\n"
                    if {[llength $value]>1} {
                        namespace inscope $implementationNS "set parameters($key) {$value}"
                    } else {
                        namespace inscope $implementationNS "set parameters($key) $value"
                    }

                }

                ## Add step variable
                namespace inscope $implementationNS "set step $this"

                #puts "Parameters: $parametersExtra"

                ## Gather Code
                ###################
                set mergedCode {}

                ## Merge PreScripts
                foreach {sourceFile prepScript} $preScripts {
                    lappend mergedCode $prepScript
                }

                ## Merge Implementation
                lappend mergedCode $implementation

                ## Merge postScripts
                foreach {sourceFile postScript} $postScripts {
                    lappend mergedCode $postScript
                }

                ## Run
                ##################
                ::edid::log "flow step execute \"$id\" Starting step $id"

                ## Simulate : only log
                ###############
                if {$simulate==true} {

                    ::edid::log "flow step simulate \"$id\" Would be run"

                } else {

                    set mergedCode [join $mergedCode "\n"]
                    namespace inscope $implementationNS "$mergedCode"
                }



            } res]} {

                ## Reset inFlow
                set edid::flow::inflow 0
                error $res

            }
            ## Reset inFlow
            set edid::flow::inflow 0

            return
        }




        ## Reloads The Step source file
        public method reload args {

            namespace inscope :: {
                source
            } $sourceFile
        }

        ## \brief #reload and #execute step
        public method reloadExecute args {

            reload $args
            execute $args

        }

        ## \brief Same as reloadExecute but with edid::reloadEnvironment before
        public method reloadEnvExecute args {

            edid::reloadEnvironment
            execute $args

        }

        ## @return 1 if the step is executed as part of a flow (from a flow or another step)
        public method isInFlow args {

            return $edid::flow::inflow

        }

        ## \brief Returns a docbook compatible table with lines of expectations
        ##   Report columns are : Step name / Description | Ok | Not OK | Remarks
        ##   Total columns: 4
        ## @warning Don't use this in encounter
        public method reportExpectations args {

            ## Check not in encounter
            if {[string match "*encounter*" [info nameofexecutable]]} {

                edid::error "Don't use reportExpectations in Encounter!! Use an external script"
                return
            }

            ## Create Line with step name
            #################################
            set out [odfi::common::newStringChannel]

            puts $out "
            <tr>
                <td class='step-id' colspan='4'><span>$id</span></td>
            </tr>
            "

            ## Create Line For Each Expectation
            ############################
            set i 0
            foreach expectation $expectations {

                set checkId "$id-check-$i"
                puts $out "
                <tr id=\"$checkId\">
                    <td  class='check-description'>$expectation</td>
                    <td class='check-ok'><input  type='checkbox' value=\"javascript:checkPass('$checkId')\"/></td>
                    <td class='check-notok'><input type='checkbox'/></td>
                    <td></td>
                </tr>
                "

                incr i
            }


            ## Get Result
            flush $out
            set result [read $out]
            close $out

            ## Return
            return $result

        }


    }

    #################################################
    ## A flow is a list of Steps to be executed
    #################################################
    itcl::class Flow {

        public variable id

        public variable steps {}

        constructor thesteps {

            ## Filter Steps starting with "#" for comments
            set steps {}
            foreach step $thesteps {

                if {![string match "#*" $step]} {
                    lappend steps $step
                }

            }

        }



        ## \brief Runs All the steps
        public method execute args {

            ## Parameters
            #################
            if {[lsearch -exact $args -simulate]>-1} {
                set simulate true
            } else {
                set simulate false
            }

            ::edid::log "flow execute \"$id\" Starting flow $id"


            set edid::flow::inflow 1


            if {[catch {
                foreach step [getSteps] {
                    $step execute $args
                    set edid::flow::inflow 1
                }

                } res]} {

                ## Error in step -> Reset inflow variable
                ::edid::log "error in step [$step cget -id]"
                set edid::flow::inflow 0

                error $res
            }


            set edid::flow::inflow 0

            return


        }

        ## \brief Runs All the steps
        public method reloadExecute args {

            ::edid::log "flow execute \"$id\" Starting flow $id"

            foreach step [getSteps] {
                $step reloadExecute
            }
        }

        ## \brief Executes flow, until provided step
        public method executeUntil stepName {
            error "flow.executeUntil not implemented"
        }

        ## \brief Executes flow, starting at provided step
        public method executeFrom stepName {

            set execute false
            foreach step [getSteps] {

                ## IF step matches the provided stepName -> start executing
                if {$execute==false && [$step cget -id]==$stepName} {
                    set execute true
                }

                if {$execute==true} {
                    $step execute
                }

            }
        }

        ## \brief Returns a list with the resolved steps.
        # This is useful because steps names provided in constructor can have unresolved variable names
        public method getSteps args {

            set resultSteps {}
            odfi::list::each $steps {
                lappend resultSteps [odfi::common::resolveVariable $it]
            }

            return $resultSteps

        }

        ## Returns the implementation code of this flow, i.e the concatenation of all substeps and subflows code
        public method getCode args {

            ## Fetch Code
            set resultCode ""
            foreach step [getSteps] {
                set resultCode "$resultCode[$step getCode]"
            }

            return $resultCode
        }

        ## \brief Writes a script to filePath, contaning all the steps and subflows code
        # This is useful to get one file with all the commands for the flow
        public method toFile args {

            ## Fetch Code
            set resultCode ""
            foreach step [getSteps] {
                set resultCode "$resultCode [$step getCode]"
            }

            ## Output to file
            set filePath $args
            if {$filePath==""} {
                exec mkdir -p saves/flows/
                set filePath saves/flows/$id.tcl

            }
            puts "Saving Flow Concatenated script to $filePath"
            set f [open $filePath w]
            puts $f $resultCode
            close $f

        }

        ## \brief Prints all the steps that would be executed by this flow
        public method printSteps args {

            odfi::list::each [getSteps] {
                puts "-> $it"
            }

        }

        ## \brief Checks all the provided steps are present
        public method verify args {

            ## Check Steps presence
            #############################
            set ok true
            foreach step [getSteps] {

                if {[llength [itcl::find objects $step]]==0} {
                    edid::warn "Flow $this contains an undefined steps/subflow: $step"
                     set ok false
                }
            }

            ## Report
            #########
            if {$ok} {
                edid::log "Everything Looks fine :-)"
            }

        }

        ## \brief Returns a docbook compatible table with lines of expectations for all steps of this flow
        ##   Report columns are : Step name / Description | Ok | Not OK | Remarks
        ##   Total columns: 4
        ## @warning Don't use this in encounter
        public method reportExpectations args {

            ## Check not in encounter
            if {[string match "*encounter*" [info nameofexecutable]]} {

                edid::error "Don't use reportExpectations in Encounter!! Use an external script"
                return
            }

            ## Prepare Table
            ######################
            set out [odfi::common::newStringChannel]
            puts $out "
            <table id='flow-table-$id' class='flow-table'>
                <thead>
                    <tr>
                        <th> Step / Check </th>
                        <th width='20'> Ok </th>
                        <th width='20'> Not Ok </th>
                        <th width='99%'> Remarks </th>
                    </tr>
                </thead>
            "

            ## Foreach Step, add the lines to table body
            ###################
            puts $out "<tbody>"
            foreach step [getSteps] {

                puts $out "
                    [$step reportExpectations]
                "

            }

            ## End Table
            ##############
            puts $out "</tbody>"
            puts $out "</table>"

            ## Get Result
            flush $out
            set result [read $out]
            close $out

            ## Return
            return $result

        }

    }



    ## \brief  Factory to create a Step. Updates existing object
    #
    proc newStep {id {script {}}} {

        ## Step file
        set stepFile [info script]
        #puts "Creating step $id from $stepFile"

        ## Create or update
        #############
        #set step [::new Step ::$id $script]
        set existing [itcl::find objects ::$id]
        if {[llength $existing]>0} {

            ## Update
            set step [lindex $existing 0]

        } else {

            ## Create
            set step [Step ::$id]
        }

        ## Configure
        ##################
        $step configure -sourceFile $stepFile
        $step withScript $script
        $step withParameter script-file $stepFile
        #$step configure -implementation $script
        $step configure -id $id
        return $step


    }

    ## \brief  Factory to create a Step The provided script will only be appied to the step, it is not a step implementation script
    #
    proc newStepWith {id {script {}}} {

        ## Create Step
        ################
        set step [[namespace current]::newStep $id {}]

        ## Apply
        ##############
        $step apply $script

        return $step


    }

    ## \brief Prints all the available steps
    proc listSteps args {

        set steps [lsort [itcl::find objects -class edid::flow::Step]]
        foreach step $steps {
            puts "$step"
        }

    }

    ## \brief Returns all the available steps
    proc getSteps args {

        return [lsort [itcl::find objects -class edid::flow::Step]]

    }


    ## Creates a new Flow with ID and steps list
    # @return The Flow object
    proc newFlow {id steps} {




        ## Delete Existing
        set existing [itcl::find objects ::$id]
        if {[llength $existing]>0} {
            itcl::delete object $existing
        }

        ## Create
        Flow ::flow.$id $steps
        ::flow.$id configure -id flow.$id

        return ::flow.$id

    }

    ## Prints all the available Flows
    proc listFlows args {

        set flows [lsort [itcl::find objects -class edid::flow::Flow]]
        foreach flow $flows {
            puts "$flow"
        }

    }



    ## Store the current step we are running
    variable currentStep ""


    ## Advertises the start of a flow
    proc start flowName {

        puts "##EDID## flow start $flowName"

    }

    ## This Procedure looks for the scripts to source for a specific step
    ## It also advertises on standart output the running of the step
    ##
    ## Script sourcing strategy:
    ##
    ##   - if existing: scripts/base/stepName.overrides.tcl before
    ##
    ##   - scripts/stepName.tcl
    ##   oder
    ##   - scripts/base/stepName.tcl
    ##
    ## @param critical Fails if no scripts to be sourced were found
    proc step {stepName {critical true}} {

        ## Advertise
        puts "##EDID## flow step $stepName"

        ## Determine script to execute
        set script false
        variable cStepName
        variable cCritical
        set cStepName $stepName
        set cCritical $critical

        namespace inscope ::  {

            upvar cStepName localStepName
            upvar cCritical localCritical

            ## Source base or scripts step script
            if {[file isfile scripts/$localStepName.tcl]} {
                source scripts/$localStepName.tcl
            } elseif {[file isfile scripts/base/${localStepName}_base.tcl]} {

                source scripts/base/${localStepName}_base.tcl



            } elseif {$localCritical==true} {
                error "Could not locate any script to source for step: $localStepName"
            }

            ## Source Overrides or Base overrides
            if {[file isfile scripts/$localStepName.overrides.tcl]} {
                source scripts/$localStepName.overrides.tcl
            } elseif {[file isfile scripts/base/${localStepName}.overrides_base.tcl]} {
                source scripts/base/${localStepName}.overrides_base.tcl
            }

        }

        ## Store current step
        variable currentStep
        set currentStep $stepName

    }

    ## Advertises an operation that happened during a step
    ## Tries to source a script based on the same rules as steps, but with $stepName_$operationName.tcl
    proc do {operationName {critical false}} {

        ## Advertise
        puts "##EDID## flow do $operationName"

        ## Set Operation full name: currentStep_operationName
        variable currentStep
        variable cFullName
        variable cCritical
        set cFullName "${currentStep}_${operationName}"
        set cCritical $critical

        namespace inscope ::  {

            upvar cFullName localFullName
            upvar cCritical localCritical

            ## Source base or scripts step script
            if {[file isfile scripts/$localFullName.tcl]} {
                source scripts/$localFullName.tcl
            } elseif {[file isfile scripts/base/${localFullName}_base.tcl]} {
                source scripts/base/${localFullName}_base.tcl
            } elseif {$localCritical==true} {
                error "Could not locate any script to source for step: $stepname"
            }

            ## Source Overrides or base overrides
            if {[file isfile scripts/$localFullName.overrides.tcl]} {
                source scripts/$localFullName.overrides.tcl
            } elseif {[file isfile scripts/base/${localFullName}.overrides_base.tcl]} {
                source scripts/base/${localFullName}.overrides_base.tcl
            }
        }

    }

    ## Announces and eventually record a parameter with a certain value
    ## Right now only announce on output, but could be use between scripts parts
    proc recordParameter {parameterName parameterValue} {

        puts "##EDID## flow parameter $parameterName $parameterValue"

    }


}
