class wget::dependencies {
	if !defined(Package['wget']) {
		package {'wget': ensure => present}
	}
}
