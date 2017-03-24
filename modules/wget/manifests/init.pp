class wget
{
	define fetch(
		$source      = $title,
		$destination = '/tmp/download.wget',
		$owner       = 'root',
		$group       = 'root',
		$chmod       = 0644,
		$timeout     = 0,
		$nocheckcert = false,
	) {
		include wget::dependencies
		$nocheckcmd = $nocheckcert ? {
			true  => '--no-check-certificate ',
			false => '',
		}
		exec {"wget-${source}":
			command => "wget ${nocheckcmd}${source} -O ${destination}",
		    timeout => $timeout,
			path    => '/usr/bin',
			require => Package['wget'],
			onlyif  => "test ! -f ${destination}",
		}
		exec {"wget-chmod-${destination}":
			command => "chmod ${chmod} ${destination}",
			path    => '/bin',
			require => Exec["wget-${source}"],
		}
		exec {"wget-chown-${destination}":
			command => "chown ${owner} ${destination}",
			path    => '/bin',
			require => Exec["wget-${source}"],
		}
		exec {"wget-chgrp-${destination}":
			command => "chgrp ${group} ${destination}",
			path    => '/bin',
			require => Exec["wget-${source}"],
		}
	}
}
