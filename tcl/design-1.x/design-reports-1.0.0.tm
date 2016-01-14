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
namespace eval edid::design::reports {


    #################
    ## base class for reports
    ###############
    itcl::class Report {
        inherit edid::design::ConfigInterface

        protected variable name ""

        ## \brief Just a string to give a type tag to the reports
        protected variable type "undefined"

        protected variable group ""

        protected variable datapoints {}

        public method setGroup fGroup {
            set group $fGroup
        }

        public method getGroup args {
            return $group
        }

        public method getName args {
            return $name
        }

        public method getType args {
            return $type
        }

        public method hasMetadata name {
            return [lsearch -exact [listMetadatas] $name]
        }

        ## \brief Returns a list with entries pairs: id of available metadatas and name
        public method listMetadatas args {
            return {}
        }

        ## \brief Return the value of Metadata with given id, or "" if not defined
        public method getMetadata id {
            return ""
        }


        ## \brief Returns a list of the various available viewTypes for this report
        public method listViews args {
            return {}
        }

        ## \brief Returns the data for this reports for the given view type
        public method view viewType {
            return ""
        }

        ## \brief Returns the content type returned by the report for the given viewType
        public method viewContentType viewType {
            return ""
        }

        ## Data Points
        ######################



        ## \brief Add a data point with name, type and a closure to be executed
        public method datapoint {name type {closure {}}} {

            set datapoint  [::new [namespace parent]::Datapoint #auto $name $type]
            lappend datapoints $datapoint
            $datapoint apply $closure
            #set datapoints($name,type) $type
            #array set datapoints [list available]
        }

        ## \brief Returns a list of pairs with datapoint type and name
        public method getDatapoints args {

            return $datapoints

        }

        public method getDatapoint name {

            foreach dp $datapoints {
                if {[$dp getName]==$name} {
                    return $dp
                }
            }

        }

        #public method

    }


    ####################
    ## Data point stuff
    ####################
    itcl::class Datapoint {

        protected variable name ""
        protected variable type ""

        protected variable values

        constructor {cName cType} {
            set name $cName
            set type $cType

            set values [dict create]
            dict set values keys ""
        }

        public method getName args {
            return $name
        }
        public method getType args {
            return $type
        }

        public method apply closure {
            if {[llength $closure]>0} {
                odfi::closures::doClosure $closure
            }
        }

        ##\ brief Record a value
        public method record {at valueKey actualValue for {valueView default}} {


            puts "DP $name, recording $actualValue for key $valueKey view $valueView"

            ## Append key to key list
            #if {[dict exists $values keys]}
            dict set values keys [lsort -unique [concat [dict get $values keys] $valueKey]]

            ## Append available view
            if {![dict exists $values $valueKey,views]} {
                dict set values $valueKey,views $valueView
            } else {
                dict set values $valueKey,views [lsort -unique [concat [dict get $values $valueKey,views] $valueView]]
            }

            ## Append value
            dict set values $valueKey,$valueView $actualValue

            #set values($valueKey,views)
            #array set values
            #set values($valueKey,$valueView,$value)

        }

        ## \return all the value keys available for this datapoint
        public method getValueKeys args {


            #return [dict keys $values {*[a-zA-Z]}]

            return [dict get $values keys]

        }

        ## \return all the views for a value keys
        public method getValueKeyViews key {

            if {[dict exists $values $key,views]} {
                return [dict get $values $key,views]
            } else {
                 error "The key $key has no views defined, no value has ever beem recorded for this key"
            }



        }

        ## \brief Returns value for the specified key and view
        public method getValueKeyView {key {view default}} {

            if {[dict exists $values $key,$view]} {
                return [dict get $values $key,$view]
            } else {
                error "Searched view $view for $key does not exist. Either key or view have not been defined"
            }

        }

        #public method getViewsFor

    }


    ## \brief This is just a report group, which is also somehow a report
    itcl::class ReportGroup {
        inherit Report

        ## The reports contained into this group
        protected variable reports {}

        constructor cName {

            ## init
            set name $cName
        }

        public method addReport report {
            lappend $reports $report
        }

        public method getReports args {
            return $reports
        }

        # \brief Returns a list of the various available viewTypes for this report
        public method listViews args {
            return {plain}
        }

        ## \brief Returns the content type returned by the report for the given viewType
        public method viewContentType viewType {
           switch -exact -- $viewType {
               plain {
                   "text/plain"
               }
               default {return ""}
           }
        }

        ## \brief Returns the data for this reports for the given view type
        public method view viewType {
            switch -exact -- $viewType {
               plain {
                   return "Group: $name"
               }
               default {return ""}
           }
        }



    }


    ## \brief A report that is simply a file
    ##################
    itcl::class FileReport {
        inherit Report

        ## \brief Path to report file
        protected variable filePath

        constructor cFilePath {

            ## Init
            ################
            set filePath    $cFilePath
            set name        [file tail $filePath]
            set type        "file"

        }

        ## Metadata
        #######################

        public method listMetadatas args {
            return {
                size            "Size"
                last-modified   "Last Modified"
                status          "Status"
            }
        }

        public method getMetadata id {
            switch -exact -- $id {
                size {
                    file size $filePath
                }
                last-modified {
                    file stat $filePath stats
                    set time $stats(ctime)

                    return [clock format $time -format {%d-%m-%Y %H:%M:%S} -timezone Europe/Berlin]
                }
                status {
                    return "ready"
                }
                default {return ""}
            }
        }

        ## Views
        #######################
        public method listViews args {
            return {plain}
        }


        public method viewContentType viewType {
            switch -exact -- $viewType {
                plain {
                   return "text/plain"
                }
                default {return ""}
            }
        }


        public method view viewType {
            switch -exact -- $viewType {
                plain {
                    ## Read file
                    ################
                    set f [open $filePath]
                    set content [read $f]
                    close $f
                    return $content
                }
                default {return ""}
            }
        }



    }


    ## \brief A file report class with basic facilities to handle parsing/reparsing etc...
    itcl::class ParsedReport {
        inherit FileReport

        protected variable status "to be parsed"

        ## \brief Default Path where the parsed status may be saved
        protected variable parsedFilePath

        ## \brief Set by implementation to signal reloading has been done
        protected variable reloaded false

        constructor cFilePath {FileReport::constructor $cFilePath} {

            ## Init
            #############
            set parsedFilePath "${cFilePath}.design-parsed"

            ## Status update
            ##############





        }

        ## Views (just dummy here for parent propagation)
        #######################
        public method listViews args {
            return [FileReport::listViews]
        }


        public method viewContentType viewType {
            return [FileReport::viewContentType $viewType]
        }


        public method view viewType {
            return [FileReport::view $viewType]
        }


        public method getMetadata id {
            switch -exact -- $id {
                status {

                    ## If source file is not newer than parsed one, can be reloaded
                    if {$reloaded==true} {
                        set status "reloaded"
                    } elseif {![file isfile $parsedFilePath]} {

                        set status "not parsed"

                    } elseif {([file mtime $filePath]<[file mtime $parsedFilePath])} {

                        ## Reload if necessary

                        set status "reloadable"

                    } else {
                        set status "to be reparsed"
                    }

                    return $status
                }
                default {return [namespace parent]::FileReport::getMetadata $id}
            }
        }


        protected variable parseStart 0
        private variable parseCurrent 0
        public method ptime message {

            set now [clock milliseconds]
            set past [expr $now-$parseCurrent]
            set parseCurrent $now

            puts "\[$past\] $message"
        }


        ## \brief This method ask implementation doParse for parsing if the
        public method parse args {



            ## Force ?
            set force false
            if {[lsearch -exact $args -force]!=-1} {
                set force true
            }



            ## If source file is not newer than parsed one, can be reloaded
            if {$force!=true && $reloaded == false && [file isfile $parsedFilePath] && ([file mtime $filePath]<[file mtime $parsedFilePath])} {


                ## Reload
                reload

            } else {

                set parseStart [clock milliseconds]
                set parseCurrent $parseStart

                ## (Re)Parse
                doParse
            }

        }

        ## \brief IMPLEMENT parsing
        public method doParse args {

        }

        ## \brief IMPLEMENT reload
        public method reload args {

        }

    }


}
