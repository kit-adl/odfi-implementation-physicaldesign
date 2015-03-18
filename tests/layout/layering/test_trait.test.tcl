package require nx 2.0.0

nx::Class create Stack {

   #
   # Stack of Things
   #

   :variable things {}

   :public method push {thing} {
      set :things [linsert ${:things} 0 $thing]
      return $thing
   }

   :public method pop {} {
      set top [lindex ${:things} 0]
      set :things [lrange ${:things} 1 end]
      return $top
   }
}

nx::Class create Safety {

  #
  # Implement stack safety by defining an additional
  # instance variable named "count" that keeps track of
  # the number of stacked elements. The methods of
  # this class have the same names and argument lists
  # as the methods of Stack; these methods "shadow"
  # the methods of class Stack.
  #

  :variable count 0

    :public method showCount args {
        puts "Actual count: ${:count}"
    }
    
  :public method push {thing} {
    incr :count
    next
  }

  :public method pop {} {
    if {${:count} == 0} then { error "Stack empty!" }
    incr :count -1
    next
  }
}


Stack create s1
s1 push a
s1 push b
s1 push c
puts [s1 pop]
puts [s1 pop]
s1 destroy


#-object-mixin Safety
Stack create s2 
s2 object mixins add Safety

s2 showCount
s2 push a
s2 pop
s2 pop
s1 info precedence
s2 info precedence

