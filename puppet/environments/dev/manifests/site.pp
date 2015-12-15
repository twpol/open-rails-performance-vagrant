class { 'epel':
    before => Class['graphite'],
}

if $::osfamily == 'RedHat' and versioncmp($::operatingsystemrelease, '7.0') >= 0 {
    class { 'firewalld::configuration':
        default_zone => 'trusted',
    }
}

class { 'apache':
    default_vhost => false,
}

package { 'pytz':
    notify => Class['graphite'],
    ensure => 'latest',
}

class { 'graphite':
    notify => Class['Apache::Service'],
    gr_graphite_ver => '0.9.15',
    gr_carbon_ver   => '0.9.15',
    gr_whisper_ver  => '0.9.15',
    gr_web_server             => 'none',
    gr_disable_webapp_cache   => true,
    gr_memcache_hosts         => ['127.0.0.1:11211'],
}

# Without this, Puppet does not let us install Class['graphite'] before Apache::Vhost['graphite.example.com'].
file { '/opt/graphite':
    ensure => 'directory',
}

apache::vhost { 'graphite.example.com':
    port => 80,
    docroot => '/opt/graphite/webapp',
    wsgi_application_group      => '%{GLOBAL}',
    wsgi_daemon_process         => 'graphite',
    wsgi_daemon_process_options => {
        processes          => '5',
        threads            => '5',
        display-name       => '%{GROUP}',
        inactivity-timeout => '120',
    },
    wsgi_import_script          => '/opt/graphite/conf/graphite.wsgi',
    wsgi_import_script_options  => {
        process-group     => 'graphite',
        application-group => '%{GLOBAL}',
    },
    wsgi_process_group => 'graphite',
    wsgi_script_aliases => {
        '/' => '/opt/graphite/conf/graphite.wsgi',
    },
    headers => [
        'set Access-Control-Allow-Origin "*"',
        'set Access-Control-Allow-Methods "GET, OPTIONS, POST"',
        'set Access-Control-Allow-Headers "origin, authorization, accept"',
    ],
    directories => [
        {
            path => '/media/',
            order => 'deny,allow',
            allow => 'from all',
        },
    ],
}
