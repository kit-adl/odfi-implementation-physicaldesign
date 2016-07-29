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
package provide odfi::implementation::libfile 1.0.0
package require odfi::language::nx 1.0.0


odfi::language::nx::new ::odfi::implementation::libfile {

    :timingLib name {
        +expose name
        +exportToPublic
        
        +var comment "" 
        +var date ""
        +var revision ""
        
        +method parseFile f {
        
            ## Get Content
            ###############
            set fd [open $f]
            set content [read $fd] 
            close $fd
        
            ## Get Definitions
            ##########
            
            ## Name 
            regexp {library\s\(([\w_-]+)\)} $content -> name
            set :name $name
            
            ## Date
             regexp {date\s*:\s*"([\w\s:\$-_\.]+)";} $content -> :date 
            
            ## Voltage Maps 
            set res [regexp -all -inline {voltage_map\s*\(\s*([\w]+)\s*,\s*([0-9\.]+)\)} $content]
            foreach {match voltage value} $res {
                #puts "Founds voltage: $voltage -> $value"
                :voltage $voltage $value
            }
            
            ## Units
            set res [regexp -all -inline {([\w]+)_unit\s*:\s*"([\w\s:\$-_\.]+)";} $content]
            foreach {match name value} $res {
                #puts "Founds voltage: $voltage -> $value"
                :unit $name $value
            }
            
            ## Cells
            ############
            set strengthSeparator "X"
            array set containerArray {}
            
            set res [regexp -all -inline {cell\s*\(([\w]+)\)\s*\{((?:[^\{\}]|\{[^\}]*\})*)\}} $content]
            #set res [regexp -all -inline -expanded {cell\s*\(([\w]+)\)\s*\{((?:\{(?-1)\}|[^{}]+)*)\}} $content]
            #puts "Cell matching: [llength $res]"
            foreach {match cellName cellContent} $res {
            
                ## Find Type by using strength separator or Number at end of name
                set containerName "default" 
                if {[regexp "(\\w+)$strengthSeparator(\\w+)" $cellName -> typeName strength]} {
                    set containerName $typeName
                } elseif {[regexp {(\w+[A-Za-z])([0-9]+)$} $cellName -> typeName strength]} {
                    set containerName $typeName
                }
                
                #puts "Container for: $cellName -> $containerName"
                
                ## Get Container
                set targetContainer  ""
                if {[llength [array names containerArray -exact $containerName]]==0} {
                    set targetContainer [:cellType $containerName]
                    array set containerArray [list $containerName $targetContainer]
                } else {
                    #puts "Reget: [array get containerArray $containerName]"
                    set targetContainer [lindex [array get containerArray $containerName] 1]
                }
                
                $targetContainer cell $cellName $cellContent {
                    
                }
            }
        
        }
        
        
        ## Definitions
        ##############
        
        :voltage name value {
        
        }
        
        :unit name value {
        
        }
        
        ## EOF Definitions
        
        ## Cell
        ##############
        :cellType name {
        
            :cell name content {
                +var parsed false
                +var area 0
                
                ## Pins
                ###########
                :powerPin name content {
                
                }
                
                :pin name content {
                
                }
                
                ## Power Information
                :leakage relatedPin {
                    +var value 0
                    +var when ""
                }
                
                ## parsing
                +method checkParsed args {
                    if {!${:parsed}} {
                        set :parsed true
                       # puts "Parsin  content: ${:content}"
                        
                        ## Area
                        regexp {area\s*:\s*([0-9\.]+)\s*;} ${:content} -> :area 
                        
                        ## Leakage
                        set allPGPins [regexp -all -inline {leakage_power\s*\(\s*\)\s*\{((?:[^\{\}]|\{[^\}]*\})*)\}} ${:content}]
                        foreach {match lContent} $allPGPins {
                            
                            #puts "Found LEAK: $lContent"
                           
                            set whenFound [regexp {when\s*:\s*"(.+)"\s*;} $lContent -> when]
                            if {$whenFound!=1} {
                                continue
                            }
                            regexp {value\s*:\s*([0-9\.]+)\s*;} $lContent -> value 
                            regexp {related_pg_pin\s*:\s*(.+)\s*;} $lContent -> related 
                            :leakage $related {
                                :value set $value
                                :when set $when
                            }
                        }
                        
                        ## Power Pins
                        set allPGPins [regexp -all -inline {pg_pin\s*\(([\w]+)\)\s*\{((?:[^\{\}]|\{[^\}]*\})*)\}} ${:content}]
                        foreach {match pinName pinContent} $allPGPins {
                        
                        }
                    }
                }
            }
        }
        
        
        
        
    }


}