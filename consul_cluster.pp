node 'puppet-agent-3' {

#Pre Requisites
#package { "unzip": ensure => 'installed', }
#file {"/opt/consul" : ensure => directory, }

#Create consul group
#group { 'consul': ensure => 'absent', }

#Create a user
#user { 'consul':
#  ensure  => 'present',
#  groups  => ['sudo', 'consul'],
#  home    => '/home/consul',
#  password  => 'consul',
#}

class { '::consul_srv':
  config_hash => {
    'bootstrap_expect' => 3,
    'data_dir'         => '/opt/consul',
    'client_addr'      => '0.0.0.0',
    'datacenter'       => 'consul',
    'log_level'        => 'INFO',
    'node_name'        => $::hostname,
    'bind_addr'        => $::ipaddress_eth0,
    'server'           => true,
    'ui'               => true,
  }
}



}

# Install agent in other Nodes


node 'puppet-agent-2', 'puppet-agent-1' {

class { '::consul_srv':
  config_hash => {
    'data_dir'      => '/opt/consul',
    'datacenter'    => 'consul',
    'log_level'     => 'INFO',
    'node_name'     => $::hostname,
    'bind_addr'     => $::ipaddress_eth0,
    'retry_join'    => ['159.65.154.3'],
  }
}

}

