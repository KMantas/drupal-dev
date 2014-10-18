# == Class: xhprof
#
# This class installs the xhprof package along with the necessary configuration
# files and a virtual host for accessing the output.
#
# === Parameters
#
# [*version*]
#   The version of the package to install. Defaults to '0.9.4'.
#
# === Examples
#
#   class { 'xhprof': }
#
# === Requirements
#
# This class requires the apache class from PuppetLabs.
class xhprof($version = '0.9.4') {
  if ! defined(Package['php-pear']) {
    package { 'php-pear':
      ensure => present,
    }
  }

  exec { 'xhprof-install':
    command => 'pecl install pecl.php.net/xhprof-0.9.4',
    creates => '/usr/share/php/xhprof_html',
    require => [Package['build-essential'], Package['php-pear'], Package['graphviz']],
  }

  file { '/etc/php5/conf.d/xhprof.ini':
    source  => 'puppet:///modules/xhprof/xhprof.ini',
    require => Exec['xhprof-install'],
  }
}
