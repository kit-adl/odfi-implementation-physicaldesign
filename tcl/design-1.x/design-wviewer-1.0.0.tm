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
package provide odfi::implementation::edid::design::wviewer 1.0.0
package require odfi::implementation::edid::design 1.0.0
package require odfi::ewww::webdata 1.0.0

namespace eval edid::design::www {

    set webappBase [file dirname [file normalize [info script]]]/www-app

    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClasses [namespace current]

    ##################
    ## Creates an Embedded Webserver on a port, and registers handlers for viewing
    ###################
    itcl::class DesignViewer {
        inherit odfi::ewww::webdata::WebdataApplication

        ## \brief The webserver
        protected variable server

        constructor {port} {odfi::ewww::webdata::WebdataApplication::constructor "designs" {}} {

            ## Init
            #############
            set applicationFolder $edid::design::www::webappBase

            ## Prepare Server
            ########
            set server [new odfi::ewww::webdata::WebdataServer my_server 8888]
            $server deploy $this


            ## Configure
            ##################
            set errorView $applicationFolder/500.html


            ########################
            ## Prepares Views
            ########################
            set appF $applicationFolder
            set designs [itcl::find objects * -isa edid::design::Design]

            view / {

                html "$appF/index.html"


            }

            view /2 {


                html "$appF/index2.html"

                #faces "$appF/index-faces.xhtml"


            }

            ## Summary view for all designs
            view /summary {

                model designs $designs
                tview "views/global/global-summary.html"
            }





            ########################
            ## Prepare Data Sources
            ########################

            #### Global
            #################
            data /global/designs/list {

            }

            #### For designs
            ##################
            data /designs/list {

                ## Find all Designs Classes
                #############
                set data [itcl::find objects * -isa ::edid::design::Design]


                set content {}
                odfi::list::each $data {
                    set objectName [lindex [split $it :] end]
                    lappend content "\{ \"name\":\"$objectName\"\}"
                }
                set content \{"name":"Designs","children":\[[join $content ,]\]\}

                puts "Looking for all designs: $content"
            }

            #### For designs
            ##################


            ########################
            ## Prepare Actions
            ########################

            ## Global
            #######################
            action /global/reload {

                run {
                   odfi::common::logInfo "Reloading"

                    catch {odfi::common::deleteObject www_viewer}
                    edid::design::reloadDesigns
                }



            }


            ########################
            ## Inject designs
            ########################
            foreach design $designs {

                odfi::common::logInfo "Setting up design: [$design getName], source object: [$design getObjectName]"


                ## Views
                #############

                #### Design
                ############

                ###### Summary
                view /[$design getObjectName]/summary {

                    ## Set design variable to model for the view
                    model design $design

                    ## Select TCL view parser
                    tview $appF/views/designs/summary-simple.html

                }

                #### Configs
                ##################
                $design eachDesignConfig {

                    set designConfig $it

                    ###### Summary
                    view /[$design getObjectName]/[$it getName]/summary {
                        model designConfig $it
                        tview $appF/views/design-config/design-config-summary-simple.html
                    }

                    ###### Runs
                    ######################
                    $it eachRun {

                        set run $it

                        ###### Summary
                        view /[$design getObjectName]/[$designConfig getName]/[$run getName]/summary {

                            model run           $run
                            model design        $design
                            model designConfig  $designConfig

                            ## view Injection points ?
                            catch {set injectionPoints [$run getViewInjects]}

                            tview $appF/views/run/run-summary.html
                        }

                        ###### Register Views From Run

                        ###### Actions

                        ## Setup Force action
                        action /[$design getObjectName]/[$designConfig getName]/[$run getName]/setupForce {

                            model run       $run

                            run {
                                $run setup -force
                            }


                        }

                        ###### Reports
                       # puts "Adding run [$run getName] reports: [llength [$run getReports]]  "
                        foreach report [$run getReports] {


                            data /[$design getObjectName]/[$designConfig getName]/[$run getName]/[$report getName] {

                                $report setConfig "access-uri" $path

                                ## Required model data for this data production
                                model run       $run
                                model report    $report

                                ## Content type and implementation for this data view
                                set dataView    "plain"
                                set dataSource  $report

                                #puts "Adding report with data source: $dataSource"

                                #set contentType [$report viewContentType "data"]
                                #set implementation {
                                #    $report view "data"
                                #}

                            }

                            ## Clean action
                            action /[$design getObjectName]/[$designConfig getName]/[$run getName]/[$report getName]/reset {

                                model run       $run
                                model report    $report

                                run {
                                    $report reset
                                }


                            }
                        }

                    }

                }


            }

        }

        destructor {

            catch {odfi::common::deleteObject  $server}

        }

        public method start args {

            $server start

        }

    }

}
