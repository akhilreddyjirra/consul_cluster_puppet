# == Class consul_srv::config
#
# This class is called from consul_srv::init to install the config file.
#
# == Parameters
#
# [*config_hash*]
#   Hash for Consul to be deployed as JSON
#
# [*purge*]
#   Bool. If set will make puppet remove stale config files.
#
class consul_srv::config(
  $config_hash,
  $purge = true,
) {

  if ($consul_srv::init_style_real != 'unmanaged') {

    case $consul_srv::init_style_real {
      'upstart': {
        file { '/etc/init/consul.conf':
          mode    => '0444',
          owner   => 'root',
          group   => 'root',
          content => template('consul_srv/consul.upstart.erb'),
        }
        file { '/etc/init.d/consul':
          ensure => link,
          target => '/lib/init/upstart-job',
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
      }
      'systemd': {
        ::systemd::unit_file{'consul.service':
          content => template('consul_srv/consul.systemd.erb'),
        }
      }
      'init','redhat': {
        file { '/etc/init.d/consul':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul_srv/consul.init.erb')
        }
      }
      'debian': {
        file { '/etc/init.d/consul':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul_srv/consul.debian.erb')
        }
      }
      'sles': {
        file { '/etc/init.d/consul':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul_srv/consul.sles.erb')
        }
      }
      'launchd': {
        file { '/Library/LaunchDaemons/io.consul.daemon.plist':
          mode    => '0644',
          owner   => 'root',
          group   => 'wheel',
          content => template('consul_srv/consul.launchd.erb')
        }
      }
      'freebsd': {
        file { '/etc/rc.conf.d/consul':
          mode    => '0444',
          owner   => 'root',
          group   => 'wheel',
          content => template('consul_srv/consul.freebsd-rcconf.erb')
        }
        file { '/usr/local/etc/rc.d/consul':
          mode    => '0555',
          owner   => 'root',
          group   => 'wheel',
          content => template('consul_srv/consul.freebsd.erb')
        }
      }
      default: {
        fail("I don't know how to create an init script for style ${consul_srv::init_style_real}")
      }
    }
  }

  file { $consul_srv::config_dir:
    ensure  => 'directory',
    owner   => $consul_srv::user_real,
    group   => $consul_srv::group_real,
    purge   => $purge,
    recurse => $purge,
  }
  -> file { 'consul config.json':
    ensure  => present,
    path    => "${consul_srv::config_dir}/config.json",
    owner   => $::consul_srv::user_real,
    group   => $::consul_srv::group_real,
    mode    => $::consul_srv::config_mode,
    content => consul_sorted_json($config_hash, $::consul_srv::pretty_config, $::consul_srv::pretty_config_indent),
    require => File[$::consul_srv::config_dir],
  }

}
