# Make sure puppet group exists
group { 'puppet': ensure => present }

# Add following directories to users path
Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }

# Set server variables from yaml file
$server_values = hiera('server', false)

# Ensure packages defined in common.yaml are installed
ensure_packages( $server_values['packages'] )

# Don't run apt-get update
class {'apt':
  always_apt_update => false,
}

# Add PPA for PHP 5.3
#apt::ppa { 'ppa:ondrej/php5-oldstable': }
#apt::ppa { 'ppa:eugenesan/ppa': }


# Install RVM
class { 'rvm': version => '1.25.7' }

# Make sure RVMs system user is vagrant
rvm::system_user { vagrant: }

# Install nginx
class { 'nginx': }

# Install mongodb
# class { 'mongodb': }

class {'::mongodb::globals':
  service_name => 'mongodb'
}->
class {'::mongodb::server':}


# Get all configuration info from nginx.yaml
$nginx = hiera('nginx', false)

# Install PHP with custom settings
class { 'php':
  package             => 'php-fpm',
  service             => 'php7.0-fpm',
  service_autorestart => false,
  config_file         => '/etc/php/7.0/fpm/php.ini',
  module_prefix       => '',
#  version  => '5.3',
  require             => Class["apt"],
}

# Install php modules defined in nginx.yaml
php::module {
  [
    $nginx['phpmodules']
  ]:
  notify  => Service["php7.0-fpm"]
}

# Make sure php-fpm is always running
service { 'php7.0-fpm':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  hasstatus  => true,
  require    => Package['php-fpm'],
}

php::module { "cli":
   module_prefix => "php-"
}

# Install PHP Devel package
class { 'php::devel':
  require => Class['php'],
}

# Install PHP Pear
class { 'php::pear':
  require => Class['php'],
}

# Install xdebug
class { 'xdebug':
  service => 'nginx',
}

# Install composer
class { 'composer':
  require => Package['php-fpm', 'curl'],
}

# Install mysql server and set root password
class { '::mysql::server':
  root_password => 'drupaldev',
  create_root_user => true
}

# Install specific version of drush
#php::pear::module { 'drush-6.2.0.0':
#  repository  => 'pear.drush.org',
#  use_package => 'no',
#}

# Install Pear package console table
php::pear::module { 'Console_Table':
  use_package => 'no',
}                         

# Set php ini values from nginx.yaml
php::ini { 'php.ini':
  value => $nginx['phpini'],
  require => Package["php-cli"]
}

class { 'ruby':
      gems_version  => 'latest'
    } 

class ruby::dev {
  require ruby
  package { $ruby::params::ruby_dev:
    ensure => installed,
    bundler_provider => apt,
  }
} 
# Install mailcatcher
#class { 'mailcatcher':
#   require => ruby-dev
#}

php::pecl::module { "xhprof":
  use_package     => 'false',
  preferred_state => 'beta',
  notify  => Service["php7.0-fpm"],
}

#php::pecl::module { "mongodb": 
#  use_package     => 'false',
#  notify  => Service["php7.0-fpm"],
#}

# Build site values for provision of site specific things
if $site_values == undef {
  $site_values = hiera('sites', false)
}

if count($site_values['vhosts']) > 0 {
  create_resources(nginx_vhost, $site_values['vhosts'])
}

if is_hash($site_values['databases']) and count($site_values['databases']) > 0 {
  create_resources(mysql_db, $site_values['databases'])
}

if ($site_values['solr'] != undef) {
  if count($site_values['solr']) > 0 {
    class { solr:
      cores => $site_values['solr'],
    }
  }
}

#class { 'phpmyadmin':
#  path     => "/var/www/phpmyadmin",
#  user     => "vagrant",
#  revision => "origin/MAINT_4_0_10",  
#  servers  => [
#    {
#      desc => "local",
#      host => "127.0.0.1",
#    },
#  ]
#}

class {'phpmyadmin':
  version => "4.4.15"
}

# Template for installing a nginx vhost
define nginx_vhost (
  $server_name,
  $server_aliases = [],
  $www_root,
  $listen_port,
  $index_files,
  $envvars = [],
  ){
  $merged_server_name = concat([$server_name], $server_aliases)

  if is_array($index_files) and count($index_files) > 0 {
    $try_files = $index_files[count($index_files) - 1]
  } else {
    $try_files = 'index.php'
  }

  nginx::resource::vhost { $server_name:
    server_name => $merged_server_name,
    www_root    => $www_root,
    listen_port => $listen_port,
    index_files => $index_files,
    try_files   => ['$uri', '$uri/', "/${try_files}?\$args"],
  }
  
  nginx::resource::location { "${server_name}-drupal":
    ensure              => present,
    vhost               => $server_name,
    location            => '@drupal',
    proxy               => undef,    
    www_root            => $www_root,
    location_cfg_append => { 'rewrite' => '^/(.*)$ /index.php?q=$1 last' },
    notify              => Class['nginx::service'],
  }
  
  nginx::resource::location { "${server_name}-css":
    ensure              => present,
    vhost               => $server_name,
    location            => '~ \.css$',
    proxy               => undef,    
    www_root            => $www_root,
    location_cfg_append => { 
      'access_log' =>  'off',
      'try_files' => '$uri =404',
       
    },
    notify              => Class['nginx::service'],
  }                                                                        
                                                       
  nginx::resource::location { "${server_name}-js":
    ensure              => present,
    vhost               => $server_name,
    location            => '~ \.js$',
    proxy               => undef,    
    www_root            => $www_root,
    location_cfg_append => { 
      'access_log' =>  'off',
      'try_files' => '$uri =404',
       
    },
    notify              => Class['nginx::service'],
  }   
  
  nginx::resource::location { "${server_name}-styles":
    ensure              => present,
    vhost               => $server_name,
    location            => '~ ^/sites/.*/files/styles/',
    proxy               => undef,
    try_files           => ['$uri', '@drupal'],
    www_root            => $www_root,    
    notify              => Class['nginx::service'],
  }     
  
  nginx::resource::location { "${server_name}-img":
    ensure              => present,
    vhost               => $server_name,
    location            => '~* ^.+\.(jpg|jpeg|gif|png|ico)$',
    proxy               => undef,
    try_files           => ['$uri', '@drupal'],
    www_root            => $www_root,    
    notify              => Class['nginx::service'],
  }                                                
                                                                                                          

  nginx::resource::location { "${server_name}-php":
    ensure              => present,
    vhost               => $server_name,
    location            => '~ \.php$',
    proxy               => undef,
    #try_files           => ['$uri', '$uri/', "/${try_files}?\$args"],
    try_files           => ['$uri', '@drupal'],
    www_root            => $www_root,
    location_cfg_append => {
      'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
      'fastcgi_param'           => 'PATH_INFO $fastcgi_path_info',
      'fastcgi_param '           => 'PATH_TRANSLATED $document_root$fastcgi_path_info',
      'fastcgi_param  '           => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
      'fastcgi_pass'            => '127.0.0.1:9000',
      'fastcgi_index'           => 'index.php',
      'include'                 => 'fastcgi_params'
    },
    notify              => Class['nginx::service'],
  }
  if $server_name != 'phpmyadmin.local' {
    file { $www_root:
      ensure => "directory",
    }
  }
}

# Template for instaling a mysql db
define mysql_db (
  $user,
  $password,
  $host,
  $grant    = [],
  $sql_file = false
  ) {
    if $name == '' or $password == '' or $host == '' {
    fail( 'MySQL DB requires that name, password and host be set. Please check your settings!' )
  }

  mysql::db { $name:
    user     => $user,
    password => $password,
    host     => $host,
    grant    => $grant,
    sql      => $sql_file,
  }
}

#vcsrepo { '/var/www/phpmyadmin.local/src':
#    ensure   => latest,
#    provider => 'git',
#    source   => 'https://github.com/phpmyadmin/phpmyadmin.git',
#    revision => 'origin/master',
#  }
 


# Install automysqlbackup and set default folder
#class { 'automysqlbackup':
#  backup_dir           => '/home/vagrant/db'
#}

#Fix for phpsock not being writable
file_line {'sock1':
  path => '/etc/php/7.0/fpm/pool.d/www.conf',
  line => 'listen.owner = www-data',
  ensure => present,
  require => Package['php-fpm'],
}
file_line {'sock2':
  path => '/etc/php/7.0/fpm/pool.d/www.conf',
  line => 'listen.group = www-data',
  ensure => present,
  require => Package['php-fpm'],
}
file_line {'sock3':
  path => '/etc/php/7.0/fpm/pool.d/www.conf',
  line => 'listen.mode = 0660',
  ensure => present,
  notify => Service["php7.0-fpm"],
  require => Package['php-fpm'],                                         
}

file_line {'sock4':
  path => '/etc/php/7.0/fpm/pool.d/www.conf',
  line => 'listen = 127.0.0.1:9000',
  ensure => present,
  notify => Service["php7.0-fpm"],
  require => Package['php-fpm'],
}


