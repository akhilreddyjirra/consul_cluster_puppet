# == Class consul_srv::install
#
# Installs consul based on the parameters from init
#
class consul_srv::install {

  case $::operatingsystem {
    'windows': {
      $binary_name = 'consul.exe'
      $binary_mode = '0775'
      $data_dir_mode = '775'
      $binary_owner = 'Administrators'
      $binary_group = 'Administrators'
    }
    default: {
      $binary_name = 'consul'
      $binary_mode = '0555'
      $data_dir_mode = '755'
      # 0 instead of root because OS X uses "wheel".
      $binary_owner = 'root'
      $binary_group = 0
    }
  }

  if $consul_srv::data_dir {
    file { $consul_srv::data_dir:
      ensure => 'directory',
      owner  => $consul_srv::user_real,
      group  => $consul_srv::group_real,
      mode   => '0755',
    }
  }

  case $consul_srv::install_method {
    'docker': {
      # Do nothing as docker will install when run
    }
    'url': {
      $install_prefix = pick($consul_srv::config_hash[data_dir], '/opt/consul')
      $install_path = pick($consul_srv::archive_path, "${install_prefix}/archives")

      # only notify if we are installing a new version (work around for switching to archive module)
      if getvar('::consul_version') != $consul_srv::version {
        $do_notify_service = $consul_srv::notify_service
      } else {
        $do_notify_service = undef
      }

      include archive
      file { [
        $install_path,
        "${install_path}/consul-${consul_srv::version}"]:
        ensure => directory,
        owner  => $binary_owner,
        group  => $binary_group,
        mode   => $binary_mode,
      }
      -> archive { "${install_path}/consul-${consul_srv::version}.${consul_srv::download_extension}":
        ensure       => present,
        source       => $consul_srv::real_download_url,
        proxy_server => $consul_srv::proxy_server,
        extract      => true,
        extract_path => "${install_path}/consul-${consul_srv::version}",
        creates      => "${install_path}/consul-${consul_srv::version}/${binary_name}",
      }
      -> file {
        "${install_path}/consul-${consul_srv::version}/${binary_name}":
          owner => $binary_owner,
          group => $binary_group,
          mode  => $binary_mode;
        "${consul_srv::bin_dir}/${binary_name}":
          ensure => link,
          notify => $do_notify_service,
          target => "${install_path}/consul-${consul_srv::version}/${binary_name}";
      }
    }
    'package': {
      package { $consul_srv::package_name:
        ensure => $consul_srv::package_ensure,
        notify => $consul_srv::notify_service
      }

      if $consul_srv::manage_user {
        User[$consul_srv::user_real] -> Package[$consul_srv::package_name]
      }

      if $consul_srv::data_dir {
        Package[$consul_srv::package_name] -> File[$consul_srv::data_dir]
      }
    }
    'none': {}
    default: {
      fail("The provided install method ${consul_srv::install_method} is invalid")
    }
  }

  if ($consul_srv::manage_user) and ($consul_srv::install_method != 'docker' ) {
    user { $consul_srv::user_real:
      ensure => 'present',
	  password => 'consul',
	  home    => '/home/consul',
      system => true,
      groups => $consul_srv::extra_groups,
      shell  => $consul_srv::shell,
    }

    if ($consul_srv::manage_group) and ($consul_srv::install_method != 'docker' ) {
      Group[$consul_srv::group_real] -> User[$consul_srv::user_real]
    }
  }
  if ($consul_srv::manage_group) and ($consul_srv::install_method != 'docker' ) {
    group { $consul_srv::group_real:
      ensure => 'present',
      system => true,
    }
  }
}
