# == Class consul_srv::service
#
# This class is meant to be called from consul
# It ensure the service is running
#
class consul_srv::run_service {

  $service_name = $consul_srv::init_style_real ? {
    'launchd' => 'io.consul.daemon',
    default   => 'consul',
  }

  $service_provider = $consul_srv::init_style_real ? {
    'unmanaged' => undef,
    default     => $consul_srv::init_style_real,
  }

  if $consul_srv::manage_service == true and $consul_srv::install_method != 'docker' {
    if $::operatingsystem == 'windows' {
      class { 'consul_srv::windows_service':
        before => Service['consul'],
      }
    }

    service { 'consul':
      ensure   => $consul_srv::service_ensure,
      name     => $service_name,
      enable   => $consul_srv::service_enable,
      provider => $service_provider,
    }
  }

  if $consul_srv::install_method == 'docker' {

    $server_mode = pick($consul_srv::config_hash[server], false)

    if $server_mode {
      $env = [ '\'CONSUL_ALLOW_PRIVILEGED_PORTS=\'' ]
      $docker_command = 'agent -server'
    }
    else {
      $env = undef
      $docker_command = 'agent'
    }

    docker::run { 'consul':
      image   => "${consul_srv::docker_image}:${consul_srv::version}",
      net     => 'host',
      volumes => [ "${::consul_srv::config_dir}:/consul/config", "${::consul_srv::data_dir}:/consul/data" ],
      env     => $env,
      command => $docker_command
    }
  }

  case $consul_srv::install_method {
    'docker': {
      $wan_command = "docker exec consul consul join -wan ${consul_srv::join_wan}"
      $wan_unless = "docker exec consul consul members -wan -detailed | grep -vP \"dc=${consul_srv::config_hash_real['datacenter']}\" | grep -P 'alive'"
    }
    default: {
      $wan_command = "consul join -wan ${consul_srv::join_wan}"
      $wan_unless = "consul members -wan -detailed | grep -vP \"dc=${consul_srv::config_hash_real['datacenter']}\" | grep -P 'alive'"
    }
  }

  if $consul_srv::join_wan {
    exec { 'join consul wan':
      cwd       => $consul_srv::config_dir,
      path      => [$consul_srv::bin_dir,'/bin','/usr/bin'],
      command   => $wan_command,
      unless    => $wan_unless,
      subscribe => Service['consul'],
    }
  }
}
