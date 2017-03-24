class xdebug::params {

  $install_cli = true

  case $::osfamily {
    'Debian': {
      $pkg      = 'php-xdebug'
      $php      = 'php'
      $ini_file = '/etc/php/7.0/mods-available/xdebug.ini'
    }
    default: {
      fail("Unsupported platform: ${::osfamily}")
    }
  }
}
