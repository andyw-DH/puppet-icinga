# Class: icinga::server::install
#
# This class installs the server components of Icinga.

class icinga::server::install {
  #Apply our classes in the right order. Use the squiggly arrows (~>) to ensure that the 
  #class left is applied before the class on the right and that it also refreshes the 
  #class on the right.
  #
  #Here, we're setting up the package repos first, then installing the packages:
  include icinga::params
  class{'icinga::server::install::repos':} ~> class{'icinga::server::install::packages':} ~> class{'icinga::server::install::execs':} -> Class['icinga::server::install']

}

##################
#Package repositories
##################
class icinga::server::install::repos { 

  case $operatingsystem {
    #Add the yum repo for Red Had and CentOS systems:
    'RedHat', 'CentOS': {}
    #Add the Icinga PPA for Debian/Ubuntu systems:
    /^(Debian|Ubuntu)$/: { 
      #Include the apt module's base class so we can...
      include apt
      #...use the module to add the Icinga PPA:
      apt::ppa { 'ppa:formorer/icinga': }
    }
    #Fail if we're on any other OS:
    default: { fail("${operatingsystem} is not supported!") } 
  }

}

##################
#Packages
##################
class icinga::server::install::packages {
  
  #Pick the right list of packages
  case $operatingsystem {
    #Red Hat/CentOS systems:
    'RedHat', 'CentOS': {
      #Pick the right DB lib package name based on the database type the user selected:
      case $icinga::params::server_db_type {
        'mysql':    { $lib_db_package = 'icinga-idoutils-libdbi-mysql'}
        'pgsql': { $lib_db_package = 'icinga-idoutils-libdbi-pgsql'}
        default: { fail("${icinga::params::server_db_type} is not supported!") }
      }
      
      $package_provider = 'yum'
    } 
    #Debian/Ubuntu systems: 
    /^(Debian|Ubuntu)$/: {
      #Pick the right DB lib package name based on the database type the user selected:
      case $icinga::params::server_db_type {
        'mysql':    { $lib_db_package = 'libdbd-mysql'}
        'pgsql': { $lib_db_package = 'libdbd-pgsql'}
        default: { fail("${icinga::params::server_db_type} is not supported!") } 
      }
      
      $package_provider = 'apt'
      $icinga_packages = ["icinga", "icinga-doc", "icinga-idoutils", "nagios-nrpe-server", "nagios-plugins-basic", "nagios-plugins-common", "nagios-plugins-standard", "nagios-snmp-plugins", $lib_db_package]
    }
    #Fail if we're on any other OS:
    default: { fail("${operatingsystem} is not supported!") } 
  }

  #Install the packages we specified above:
  package {$icinga_packages:
    ensure   => installed,
    provider => $package_provider,
  }

}

class icinga::server::install::execs {

  case $operatingsystem {
    #Exec resources for Red Hat/CentOS systems
    'RedHat', 'CentOS': {}
    #Exec resources for Debian/Ubuntu systems
    /^(Debian|Ubuntu)$/: {
      #dpkg override commands; these let the nagios user access some Icinga folders necessary
      #for the web UI to work:   
      exec { 'dpkg-overrides':
        user    => 'root',
        path    => '/usr/bin:/usr/sbin:/bin/:/sbin',
        command => "dpkg-statoverride --update --add nagios www-data 2710 /var/lib/icinga/rw; dpkg-statoverride --update --add nagios nagios 751 /var/lib/icinga; touch /etc/icinga/dpkg_override_done.txt",
        creates => "/etc/icinga/dpkg_override_done.txt",
        require => Class['icinga::server::install::packages'],
      }
      
      #This case statement loads the DB schema for the appropriate database the user picked in params.pp:
      case $icinga::params::server_db_type {
        'mysql':    {}
        'pgsql': {
          exec { 'debianubuntu-postgres-schema-load':
            user    => 'root',
            path    => '/usr/bin:/usr/sbin:/bin/:/sbin',
            command => "su postgres -c 'psql -d icinga < /usr/share/dbconfig-common/data/icinga-idoutils/install/pgsql'; touch /etc/icinga/postgres_schema_loaded.txt",
            creates => "/etc/icinga/postgres_schema_loaded.txt",
            require => Class['icinga::server::install::packages'],
          }
        }
        default: { fail("${icinga::params::server_db_type} is not supported!") }
      }
    }
  }
  
}