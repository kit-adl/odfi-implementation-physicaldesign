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
package provide odfi::implementation::edid::design      1.0.0
package require odfi::list 2.0.0
package require odfi::common

## Other files to source for this module
set otherFiles {
    design-reports-1.0.0.tm
}

namespace eval edid::design {

    ## Path to this library script
    variable libraryScript [file normalize [info script]]

    ## This variable contains the path to the script that configure the designs
    variable designsScript


    ## \brief Re-source the designs script
    proc reloadDesigns args {

        odfi::common::logInfo "Loading designs by sourcing: $::edid::design::designsScript"
        uplevel #0 {source $::edid::design::designsScript}

    }

    ## Reload this library
    proc reloadLibrary args {

        #tkcon iconify

        ## Close UI
        ####################

        package forget odfi::implementation::edid::design
        package forget odfi::common
        package forget odfi::list

        package require odfi::common
        package require odfi::list
        package require odfi::implementation::edid::design


        reloadDesigns






    }

    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClasses [namespace current]

    itcl::class ConfigSource {

        ## Generic configuration source (key value pairs list)
        public variable configuration {}

        ## List of possible configuration parents
        public variable parents {}

        constructor {{cParents {}}} {


            ## Set parent if necessaray
            if {[llength $cParents]>0} {
                set parents $cParents
            }

        }

        ## \brief Set the named configuration value in this configuration source
        public method setConfig {name value} {

            lappend configuration [string trim "$name"]
            lappend configuration $value

            #puts "Adding config to [itcl::scope $this], now size is [llength $configuration]"

        }

        ##\brief Returns the value of parametername from this configuration of one of its parent
        ## It resolves embedded other configuration values in resulting string, by replacing %parameterName% strings
        public method getConfig parameterName {

            set parameterName [string trim $parameterName]

            ## Search for a value in current config or parents
            ##########
            set value ""
            set currentConfigs [list $this]
            while {[llength $currentConfigs]>0} {

                ## Take first
                set cfg [lindex $currentConfigs 0]
                set currentConfigs [lreplace $currentConfigs 0 0]


                set configSize [llength [$cfg cget -configuration]]
                set configList [$cfg cget -configuration]

                ## Search
                set entry [lsearch -exact $configList "$parameterName"]

                #puts "Searching for $parameterName in $cfg ($configList) of size $configSize, with result $entry"

                ## If found, stop
                if {$entry>=0} {
                    set value [lindex $configList [expr $entry+1]]
                    break
                } else {

                    ## Not Found
                    ##  - Add parents to the list
                    if {[llength [$cfg cget -parents]]>0} {
                        #puts "-> Adding [$cfg cget -parents] to search path"
                        set currentConfigs [concat $currentConfigs [$cfg cget -parents]]
                    }

                }

            }

            ## If no value found, error
            if {$value==""} {
                error "Requested config $parameterName, but no value was found in local or parent configurations"
            } else {

                ## Resolve String
                #####################
                set value [subst $value]

            }
            return $value


        }

        ## \brief Substitute all the %varname% substrings in str by getting configuration parameter
        public method subst str {


            ## Substitute until nothing to substitute is found
            set count 1
            while {$count > 0 } {
                set count [regsub -all {%(.+)%} $str {[getConfig \1]} str]
                set str [::subst $str]
            }
            return $str
        }

        ## \brief add a new parent configuration source
        public method addParent configurationObject {

            #puts "Adding Configuration $configurationObject to $this"
            lappend parents $configurationObject
        }

        ## \brief applies a closure on this object
        public method apply closure {

            if {[llength $closure]>0} {
                odfi::closures::doClosure $closure
            }

        }

        ## \brief Returns list of all local configuration parameters
        public method listLocalConfig args {

            set res {}
            foreach {key val} $configuration {
                lappend res $key
            }
            return $res
        }



    }

    itcl::class ConfigInterface {

        ## Generic configuration source
        public variable configuration

        constructor args {
            set configuration [::newAbsolute [namespace parent]::ConfigSource #auto_[regsub -all ":" [itcl::scope $this] "" ]]
        }

        public method withConfiguration closure {

            $configuration apply $closure
        }

        ## \brief Imports Another ConfigInterface class as parent
        public method import obj {


            if {[odfi::common::isClass $obj [namespace parent]::ConfigSource]} {

                ## If imported is a config source, add as parent
                $configuration addParent $obj

            } elseif {[odfi::common::isClass $obj [namespace parent]::ConfigInterface]} {

                ## If imported is a config interface, add its configuration as parent
                $configuration addParent [$obj cget -configuration]
            }

        }

        public method getConfig parameterName {
            return [$configuration getConfig $parameterName]
        }

        public method setConfig {parameterName value } {
            $configuration setConfig $parameterName $value
        }



        ## \brief Returns list of all local configuration parameters
        public method listLocalConfig args {

            return [$configuration listLocalConfig]
        }

    }

    ##############
    ## Environment
    #################
    itcl::class EnvironmentSetup {
            inherit ConfigInterface

        ## Design name, defaults to object name
        public variable name

        ## Commands to execute to setup environment to start the tools
        public variable setupCommand ""



        constructor cl {

            ## Defaults
            ###############
            set name [regsub -all ":" [itcl::scope $this] "" ]

            ## Load closure
            if {[llength $cl]>0} {
                eval $cl
            }

        }

        ## Get Name of environment
        public method getName args {
            return $name
        }

        ## \brief Imports Another EnvironmentSetup class"s parameter
        public method import obj {

            ## Import Configuration
            ConfigInterface::import $obj

            if {[odfi::common::isClass $obj [namespace current]]} {
                set setupCommand [$obj cget -setupCommand]
            }

        }

    }



    ##############
    ## Design
    #################
    itcl::class Design {
        inherit ConfigInterface

        ## Design name, defaults to object name
        public variable name

        ## Only the name of this object, used for sub objects naming
        private variable objectName

        ## A script that can be run to setup the design in the tool
        public variable setupScript {}

        ## Folder were the script that created this object is running
        public variable baseFolder

        ## \brief List of design configs
        public variable designConfigs {}


        ## Constructor with closure executed in context of this Design
        #  Automatically set variables:
        #   - base folder : Folder of Script that is currently running
        constructor cl {



            ## Init
            ######################
            #set name [lindex [regsub -all ":" [itcl::scope $this] "" ]
            set name [lindex [split [itcl::scope $this] "::"] end]
            set objectName $name

            ## Set default Folder
            set baseFolder [file dirname [info script]]/$name


            odfi::common::logInfo "Created design $name"

            ## Load closure
            if {[llength $cl]>0} {
                odfi::closures::doClosure $cl
            }




        }

        ## \brief Creates a new Design Config for this design and given environment
        # Executes closure as constructor of this Design Config
        # @return the created DesignConfig object
        public method forEnvironment {environment closure} {

            ## Create Config
            set designConfig [createDesignConfig "::${objectName}.[$environment getName]" $environment $this $closure]

            ## Save it
            lappend designConfigs $designConfig

            return $designConfig

        }


        ## Prepare the runs of the design
        # - Creates the run folders with run_ prefixed
        # - Copy initDb files in the folder if necessary
        # - Call on implementation
        public method prepareRuns args {

            ::odfi::list::each $designConfigs {

                $it prepareRuns $args
            }

        }


        ## \brief Write a Sublime project with all the runs of all configurations
        public method writeSublimeProjectFile args {


            set sublimeBasePath ""
            #catch {set sublimeBasePath "[getConfig sublime-designspath]/"}
            set sublimeBasePath "[getConfig sublime-designspath]/"

            puts "SUBLIME PATH: $sublimeBasePath"


            ## Open File
            #############

            ## Write base folders structure
            set projectName "$name"
            set sublimeProjectFile [open $projectName/${objectName}.sublime-project "w+"]

            odfi::common::println "{"                   $sublimeProjectFile
            odfi::common::println "    \"folders\":"    $sublimeProjectFile
            odfi::common::println "    \["              $sublimeProjectFile

            ## Gather run folders outputs
            set runFoldersStructs {}
            foreach designConfig $designConfigs {
                foreach run [$designConfig cget -runs] {

                    set tmp [odfi::common::newStringChannel]
                    set folderName        "$name.[[$run getEnvironment] getName].run_[$run getName]"
                    set folderPath        [$run getFolderPath -relative]
                    odfi::common::println "         {"                                              $tmp
                    odfi::common::println "             \"name\": \"$folderName\","                 $tmp
                    odfi::common::println "             \"path\": \"[file normalize ${sublimeBasePath}$folderPath]\"" $tmp
                    odfi::common::print   "         }"                                              $tmp

                    flush $tmp
                    lappend runFoldersStructs [read $tmp]
                    close $tmp
                }
            }

            ## Output folders
            odfi::common::println [join $runFoldersStructs ",\n"]  $sublimeProjectFile

            ## Close folder structure
            odfi::common::println "    \]"  $sublimeProjectFile
            odfi::common::println "}"       $sublimeProjectFile

            ## Close File
            close $sublimeProjectFile

        }


        ## \brief Executes Closure for each design config, with $it as variable to config
        #  The execution context is per default the on of caller, not this object
        #   Returns a list with the result of each run
        public method eachDesignConfig closure {

            return [::odfi::list::transform $designConfigs $closure 1]

        }


        ## \brief Returns the name of the design
        public method getName args {
            return $name
        }
        public method getFullName args {
            return $objectName
        }

        ## \brief Returns the simple object name of this design
        public method getObjectName args {
            return $objectName
        }


        ## Implementation Specific
        ################################

        protected method createDesignConfig {newName environment design closure} {

            return [::new [namespace parent]::DesignConfig "${newName}" $environment $design $closure]


        }

    }

    ##############
    ## DesignConfig
    ##  - Combination of a design, and environment Setup, to create runs
    ##  - Created from a design
    #################
    itcl::class DesignConfig {
            inherit ConfigInterface

        ## Config name, defaults to object name
        public variable name

        ## Only the name of this object, used for sub objects naming
        private variable objectName

        ## Reference environment
        public variable environment

        ## Reference design
        public variable design

        ## Map name<->runs
        public variable runs {}

        ## Folder path of this config, inited in constructor
        public variable folderPath


        constructor {cEnvironment cDesign closure} {

            ## Init
            #################

            #array set runs { }
            set name        [regsub -all ":" [itcl::scope $this] "" ]
            set objectName  $name
            set environment $cEnvironment
            set design      $cDesign
            set folderPath  [$design getName]/[$environment getName]

            ## Add design and environment as configuration parents
            ############
            $configuration addParent [$environment cget -configuration]
            $configuration addParent [$design cget -configuration]

            ## Closure
            ##############
            if {[llength $closure]>0} {
                odfi::closures::doClosure $closure
            }
        }

        ## \brief Creates a new Run object from runName string and optional closure
        public method addRun {runName {closure {}}} {

            ## Check already existing
            #if {[llength [array get runs $runName]]>0} {
            #    error "Trying to add $runName as run to design $this, but already existing"
            #}

            ## Create
            set run [createRun "::${objectName}.${runName}" $runName $closure]

            ## Add
            #array set [itcl::scope $this]::runs [list $runName $run]
            #set runs($runName) $run
            lappend runs $run

            odfi::common::logInfo "Created run ${objectName}.${runName} -> $run ([llength $runs])"

        }

        ## Prepare the runs of the design
        # - Creates the run folders with run_ prefixed
        # - Copy initDb files in the folder if necessary
        # - Call on implementation
        public method prepareRuns args {

            foreach {run} $runs {

                $run setup $args

            }



        }

        ## \brief Executes Closure for each design config, with $it as variable to config
        #  The execution context is per default the on of caller, not this object
        public method eachRun closure {

            return [::odfi::list::transform $runs $closure 1]
            #::odfi::list::each $runs $closure 1

        }

        ## Get/Setters
        ##################
        public method getName args {
            return $name
        }
        public method getFullName args {
            return $objectName
        }

        public method getDesign args {
            return $design
        }

        public method getEnvironment args {
            return $environment
        }

        ## Implementation Specific
        ################################

        ## \brief Creates Default run
        # @warning objectName is already set correctly, don"t change it
        protected method createRun {objectName runName {closure {}}} {

            set run [::new Run "::${objectName}" $this $runName $closure]
            return $run
        }


    }

    ##############
    ## Run
    ##  - Represents a Run in a design
    #################
    itcl::class Run {
        inherit ConfigInterface

        ## Name of this run
        public variable name

        ## Design Configuration
        public variable designConfig
        protected variable design
        protected variable environment

        ## Folder path of this run, inited in constructor
        protected variable folderPath

        ## \brief Post setup closure
        public variable postSetup {}

        ## Constructs from parent design, environement setup, a name and an optional closure
        constructor {cName cDesignConfig closure} {

            ## Init
            #############
            set name             $cName
            set designConfig     $cDesignConfig
            set design           [$designConfig getDesign]
            set environment      [$designConfig getEnvironment]

            set folderPath       [$designConfig cget -folderPath]/run_$name

            ## Add Design config as configuration parent
            $configuration addParent [$designConfig cget -configuration]

            ## Default configuration improvement
            ###########
            if {[file isdirectory $folderPath/scripts-repository]} {
                $configuration setConfig repository $folderPath/scripts-repository
            }

            ## Closure
            ##################
            if {[llength $closure]>0} {
                odfi::closures::doClosure $closure
            }


        }

        ## Prepare this run
        # - Creates the run folder with run_ prefixed
        # - Copy initDb files of parent in the folder if necessary
        # - Call on implementation
        # @warning Does nothing per default if the run folder already exists
        #
        public method setup args {

            ## Parameters
            #################
            set force 0
            if {[lsearch -exact $args "-force"]!=-1} {
                set force 1
            }


            ## Check folder does not exist
            if {!$force && [file exists $folderPath]} {
                odfi::common::logInfo "Design [$design getName], run $name not setup because folder exists"
                return
            }


            odfi::common::logInfo "Design Config [$designConfig getName], preparing run $name"
            odfi::common::logInfo "Target folder: $folderPath"

            ## - Create dir
            exec mkdir -p $folderPath

            ## Copy Initial data if config is provided
            ##################
            if {![catch {set initialData [$configuration getConfig initial-data]} res]} {



                ## Initial data can have a copy pattern
                set copyPattern "*"
                if {[llength $initialData]>1} {
                    set copyPattern [lindex $initialData 1]
                }

                odfi::common::logInfo "Initial Data: [lindex $initialData 0] to $folderPath $copyPattern"

                ## - Copy initDb files of parent in the folder if necessary
                odfi::common::copy [lindex $initialData 0] $folderPath $copyPattern
                #if {[llength $initialData]>0} {
                 #   odfi::list::each $initialData {
                #        odfi::common::copy $it $folderPath $copyPattern
                #    }
                #}



            } else {
                puts "-> Initial data error: $res"
            }



            ## Sublime Project
            ########################
            writeSublimeProjectFile


            ## Git Clone source
            ###############
            if {![catch {set gitScriptSource [$configuration getConfig scripts-git-repository]} res]} {

                ## Prepare
                set branchName "[$design getName].[$environment getName].run_$name"
                set sourceBranch "master"
                odfi::common::logInfo "A Git repository for the scripts has been given"
                odfi::common::logInfo "Cloning $gitScriptSource to ./scripts-repository "

                ## Clone and configure
                odfi::common::logInfo "Branch will be: $branchName"
                catch {exec git clone $gitScriptSource $folderPath/scripts-repository}
                set actualPwd [pwd]
                cd $folderPath/scripts-repository
                catch {exec git checkout -b $branchName}
                catch {exec git config --add push.default current}
                catch {exec git branch --set-upstream $branchName origin/$sourceBranch}

                ## Record path to config
                $configuration setConfig repository $folderPath/scripts-repository

                cd $actualPwd
            }



            ## - Post Setup
            ##################
            if {[llength $postSetup]>0} {
                odfi::closures::doClosure $postSetup
            }
        }

        public method writeSublimeProjectFile args {

            ## Sublime Project
            ########################
            set projectName "[$design getName].[$environment getName].run_$name"
            set sublimeProjectFile [open $folderPath/${projectName}.sublime-project "w+"]
            odfi::common::println "{" $sublimeProjectFile
            odfi::common::println "    \"folders\":" $sublimeProjectFile
            odfi::common::println "    \["          $sublimeProjectFile

            odfi::common::println "         {" $sublimeProjectFile
            odfi::common::println "             \"name\": \"$projectName\"," $sublimeProjectFile
            odfi::common::println "             \"path\": \"[file normalize $folderPath]\"" $sublimeProjectFile
            odfi::common::println "         }" $sublimeProjectFile

            odfi::common::println "    \]"          $sublimeProjectFile
            odfi::common::println "}" $sublimeProjectFile
            close $sublimeProjectFile


        }

        ## Implementation Specific
        ##################

        ## \brief Returns all the found reports in this run
        # @return An empty list as default implementation
        public method getReports args {
            return {}
        }

        ## Get/Setters
        ##################
        public method getName args {
            return $name
        }
        public method getFullName args {
            return $name
        }

        public method getDesignConfig args {
            return $designConfig
        }

        public method getDesign args {
            return $design
        }

        public method getEnvironment args {
            return $environment
        }

        ## \brief Returns the Folder path for this run (non normalized)
        # If -relative is provided in args, then no normalize is called on path
        public method getFolderPath args {
            if {[lsearch -exact -relative $args]!=-1} {
                return $folderPath
            } else {
                return [file normalize $folderPath]
            }

        }



    }


    ### Extra fun functions
    ##############################

    ## \brief Write a project file for Sublime Text, under given projectName and designs
    # Uses the first provided design folder path as base path
    proc writeDesignsSublimeProjectFile {projectName designs} {

        set firstDesign [lindex $designs 0]

        set sublimeBasePath ""
        #catch {set sublimeBasePath "[getConfig sublime-designspath]/"}
        set sublimeBasePath "[$firstDesign getConfig sublime-designspath]/"

        puts "SUBLIME PATH: $sublimeBasePath"


        ## Open File
        #############

        ## Write base folders structure
        set sublimeProjectFile [open $projectName/${projectName}.sublime-project "w+"]

        odfi::common::println "{"                   $sublimeProjectFile
        odfi::common::println "    \"folders\":"    $sublimeProjectFile
        odfi::common::println "    \["              $sublimeProjectFile

        ## Gather run folders outputs
        set runFoldersStructs {}
        foreach design $designs {

            $design eachDesignConfig {

                set designConfig $it
                $designConfig eachRun {

                    set run $it
                    set tmp [odfi::common::newStringChannel]
                    set folderName        "[$design getFullName].[[$run getEnvironment] getName].run_[$run getName]"
                    set folderPath        [$run getFolderPath -relative]
                    odfi::common::println "         {"                                              $tmp
                    odfi::common::println "             \"name\": \"$folderName\","                 $tmp
                    odfi::common::println "             \"path\": \"[file normalize ${sublimeBasePath}$folderPath]\"" $tmp
                    odfi::common::print   "         }"                                              $tmp

                    flush $tmp
                    lappend runFoldersStructs [read $tmp]
                    close $tmp
                }

            }
        }

        ## Output folders
        odfi::common::println [join $runFoldersStructs ",\n"]  $sublimeProjectFile

        ## Close folder structure
        odfi::common::println "    \]"  $sublimeProjectFile
        odfi::common::println "}"       $sublimeProjectFile

        ## Close File
        close $sublimeProjectFile

    }


}

## Additional files
##############################
foreach sourceFile $otherFiles {
   source [file dirname [file normalize [info script]]]/$sourceFile
}

