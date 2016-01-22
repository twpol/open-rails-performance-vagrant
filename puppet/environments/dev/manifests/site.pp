class { 'epel':
}
Class['epel'] -> Package<| |>

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

class { 'nodejs':
    notify => Class['statsd'],
    nodejs_dev_package_ensure => 'present',
    npm_package_ensure        => 'present',
    repo_class                => '::epel',
}



class { 'collectd':
    minimum_version => '5.5', # Needed to avoid running Puppet twice.
    purge        => true,
    recurse      => true,
    purge_config => true,
}

class { 'collectd::plugin::cpu':
}

class { 'collectd::plugin::load':
}

class { 'collectd::plugin::memory':
}

collectd::plugin::write_graphite::carbon { 'graphite':
}

class { 'statsd':
    backends     => ['./backends/graphite'],
    graphiteHost => 'localhost',
    graphite_legacyNamespace => false,
    flushInterval => 10000, # Must match interval for Graphite storage schema.
    percentThreshold => [90, 95, 99],
}

class { 'graphite':
    notify => Class['Apache::Service'],
    gr_graphite_ver => '0.9.15',
    gr_carbon_ver   => '0.9.15',
    gr_whisper_ver  => '0.9.15',
    gr_web_server             => 'none',
    gr_disable_webapp_cache   => true,
    gr_storage_schemas        => [
        {
            name       => 'stats',
            pattern    => '^stats\.',
            retentions => '10s:6h,1min:6d,10min:1800d',
        },
        {
            name       => 'collectd',
            pattern    => '^collectd\.',
            retentions => '10s:6h,1min:6d,10min:1800d',
        },
        # Default rules:
        {
            name       => 'carbon',
            pattern    => '^carbon\.',
            retentions => '1m:90d',
        },
        {
            name       => 'default',
            pattern    => '.*',
            retentions => '1s:30m,1m:1d,5m:2y',
        }
    ],
    gr_storage_aggregation_rules => {
        'min'     => { pattern => '\.lower(_\d+)?$', xFilesFactor => '0.1', aggregationMethod => 'min' },
        'max'     => { pattern => '\.upper(_\d+)?$', xFilesFactor => '0.1', aggregationMethod => 'max' },
        'sum'     => { pattern => '\.sum(_\d+)?$',   xFilesFactor => '0',   aggregationMethod => 'sum' },
        'count'   => { pattern => '\.count$',        xFilesFactor => '0',   aggregationMethod => 'sum' },
        'default' => { pattern => '.*',              xFilesFactor => '0.3', aggregationMethod => 'average' },
    },
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
