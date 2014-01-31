# Class: icinga::client
#
# This subclass manages Icinga client components. This class is just the entry point for Puppet to get at the
# icinga::client:: subclasses.
#

class icinga::client (

) inherits icinga::params {
  
  #Apply our classes in the right order. Use the squiggly arrows (~>) to ensure that the 
  #class left is applied before the class on the right and that it also refreshes the 
  #class on the right.
  class {'icinga::client::install':} ~>
  class {'icinga::client::config':} ~>
  class {'icinga::client::service':}
}