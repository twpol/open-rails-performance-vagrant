class { 'epel': }

class { 'graphite':
    require => Class['epel']
}