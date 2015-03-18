package require odfi::implementation::techfile 1.0.0
package require odfi::scenegraph 2.0.0
package require odfi::scenegraph::layouts 2.0.0
package require odfi::implementation::partition
set location [file dirname [file normalize [info script]]]


## Test parameters
set fieldsCount 20
set methodsCount 20

set test_var 0
set test_var2 20

proc test_start_rec count {

    if {$count==0} {
        test_simple        
    } else {
        test_start_rec [expr $count-1]        
    }
    

}

proc test_simple args {
    
   
    
    
    
    ## Test
    ################
    set repCount 2000
    set withClosures true
    set test_var_nc 0
    set test_var2_nc 20    
    
    if {!$withClosures} {
    
        for {set i 0} {$i<$repCount} {incr i} {

            set test_var [expr $test_var_nc * ($test_var2_nc**2)] 
            odfi::closures::value test_var
            odfi::closures::value test_var2                        
        }        
    
    } else {
    
        odfi::closures::run {
        
        
            #for {::set i 0} {$i<$repCount} {::incr i}
            ::repeat $repCount {
                
                   odfi::closures::applyLambda {
                            #set test_var [expr $test_var * ($test_var2**2)]
                            odfi::closures::value test_var
                            odfi::closures::value test_var2 
                            odfi::closures::value i                                                           
                            
                   }              
            }    
        
        }        
    
    
    }    


    
    after 1000
    
    puts "Done"      
    
       
    
}


test_start_rec 5
test_start_rec 10





