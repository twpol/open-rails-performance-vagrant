class { 'epel':
}

class { 'firewalld::configuration':
    default_zone => 'trusted',
}

class { 'apache':
    default_vhost => false,
}

class { 'graphite':
    require => Class['epel'],
    gr_web_server => 'none',
}

apache::vhost { 'graphite.example.com':
    port => 80,
    docroot => '/opt/graphite/webapp',
}
