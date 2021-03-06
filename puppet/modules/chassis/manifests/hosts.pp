# Setup the avahi hosts
class chassis::hosts(
	$aliases = [],
	$subdomains = false,
) {
	package { [ 'avahi-daemon', 'python-pip', 'python-avahi', 'pkg-config', 'libdbus-glib-1-dev' ]:
		ensure => latest,
	}

	exec { 'upgrade pip':
		path    => '/bin:/usr/bin',
		command => 'pip install --upgrade pip==9.0.3',
		require => Package['python-pip']
	}

	ensure_packages( ['mdns-publisher'], {
		ensure   => present,
		provider => 'pip',
		require  => [ Package['python-pip'], Package['libdbus-glib-1-dev'], Exec['upgrade pip'] ],
	})

	file { '/lib/systemd/system/chassis-hosts.service':
		ensure  => 'file',
		mode    => '0644',
		content => template('chassis/chassis-hosts.service.erb'),
		notify  => Service['chassis-hosts'],
		require => Package['mdns-publisher'],
	}

	if ( $subdomains ) {
		file { '/vagrant/local-config-hosts.php':
			source => 'puppet:///modules/chassis/local-config-hosts.php',
			mode   => '0644',
		}
	} else {
		file { '/vagrant/local-config-hosts.php':
			ensure => absent,
		}
	}

	service { 'chassis-hosts':
		ensure  => running,
		enable  => true,
		require => [
			Package[ 'avahi-daemon' ],
			Package[ 'python-avahi' ],
			File[ '/lib/systemd/system/chassis-hosts.service' ],
		],
		notify  => Exec['systemctl-daemon-reload'],
	}
}
