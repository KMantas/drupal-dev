class phpmyadmin(
  $ensure         = $phpmyadmin::params::ensure,
  $version        = $phpmyadmin::params::version,
  $installdir     = $phpmyadmin::params::instdir,
  $vhost_name     = $phpmyadmin::params::vhost_name,
  $vhost_port     = $phpmyadmin::params::vhost_port,
  $vhost_priority = $phpmyadmin::params::vhost_priority,
  $root_password  = $phpmyadmin::params::root_password,
) inherits phpmyadmin::params {

	include phpmyadmin::dependencies
	case $ensure {
		present: {
			phpmyadmin::install {$version:
				installdir => $installdir,
			}
			
		}
		absent : { phpmyadmin::uninstall {'uninstall':} }
		default: { fail("Unsupported option for \"ensure\" param: ${ensure}") }
	}
}
