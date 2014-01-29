# Class: icinga::server::config
#
# This class manages configuration for Icinga servers.
#
# Parameters:

class icinga::server::config {

  include icinga::params
  
  #Create an htpasswd entry for the 'icingaadmin' user. This requires the httpauth module
  #to be installed: https://github.com/jamtur01/puppet-httpauth
  httpauth { 'icingaadmin':
    file      => '/etc/icinga/htpasswd.users',
    password  => $icinga::params::icingaadmin_password,
    realm     => 'realm',
    mechanism => basic,
    ensure    => present,
  }

  file { '/etc/icinga/htpasswd.users':
    path    => '/etc/icinga/htpasswd.users',
    ensure  => file,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '644',
  }

  case $operatingsystem {
    #File and template variable names for Red Had/CentOS systems:
    'RedHat', 'CentOS': {}
    #File and template variable names for Debian/Ubuntu systems:
    /^(Debian|Ubuntu)$/: {
      $etc_default_template = "icinga/ubuntu_etc-default-icinga.erb"
      $ido2db_cfg_template = "icinga/ubuntu_ido2db.cfg.erb"
    }
    #Fail if we're on any other OS:
    default: { fail("${operatingsystem} is not supported!") }
  }

  #/etc/default/icinga resource
  file { '/etc/default/icinga':
    path    => '/etc/default/icinga',
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    content => template($etc_default_template),
  }

  #/etc/icinga/icinga.cfg resource
  file { '/etc/icinga/icinga.cfg':
    path    => '/etc/icinga/icinga.cfg',
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    content => template('icinga/icinga.cfg.erb'),
  }

  #/etc//etc/icinga/ido2db.cfg
  file { '/etc/icinga/ido2db.cfg':
    path    => '/etc/icinga/ido2db.cfg',
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '600',
    content => template($ido2db_cfg_template),
  }
  
  #/etc/icinga/modules/idoutils.cfg
  file { '/etc/icinga/modules/idoutils.cfg':
    path    => '/etc/icinga/modules/idoutils.cfg',
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    content => template('icinga/idoutils.cfg.erb'),
  }

  #/etc/icinga/idomod.cfg
  file { '/etc/icinga/idomod.cfg':
    path    => '/etc/icinga/idomod.cfg',
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    content => template('icinga/idomod.cfg.erb'),
  }
}