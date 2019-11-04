# == Class: bareos::director
# This class manages the bareos director service, packages and configuration directory.
# Parameters should be configured in the upper class `::bareos`.
#
# This class will be automatically included when a resource is defined.
# It is not intended to be used directly by external resources like node definitions or other modules.
class bareos::director(
  $manage_service    = $::bareos::manage_service,
  $manage_package    = $::bareos::manage_package,
  $manage_database   = $::bareos::manage_database,
  $manage_config_dir = $::bareos::manage_config_dir,
  $package_name      = $::bareos::director_package_name,
  $package_ensure    = $::bareos::package_ensure,
  $service_name      = $::bareos::director_service_name,
  $service_ensure    = $::bareos::service_ensure,
  $service_enable    = $::bareos::service_enable,
  $config_dir        = "${::bareos::config_dir}/bareos-dir.d"
) inherits ::bareos {
  include ::bareos::director::director

  if $manage_package {
    package { $package_name:
      ensure => $package_ensure,
      tag    => ['bareos', 'bareos_director'],
    }
  }

  if $manage_service {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
      tag    => ['bareos', 'bareos_director'],
    }
  }

  # directories
  $config_director_dirs = [
    $config_dir,
    "${config_dir}/catalog",
    "${config_dir}/client",
    "${config_dir}/console",
    "${config_dir}/counter",
    "${config_dir}/director",
    "${config_dir}/fileset",
    "${config_dir}/job",
    "${config_dir}/jobdefs",
    "${config_dir}/messages",
    "${config_dir}/pool",
    "${config_dir}/profile",
    "${config_dir}/schedule",
    "${config_dir}/storage",
  ]

  if $manage_config_dir {
    file { $config_director_dirs:
      ensure  => directory,
      purge   => true,
      recurse => true,
      force   => true,
      mode    => $::bareos::file_dir_mode,
      owner   => $::bareos::file_owner,
      group   => $::bareos::file_group,
      require => Package[$package_name],
      notify  => Service[$service_name],
      tag     => ['bareos', 'bareos_director'],
    }
  }

  if $manage_database {
    File <| tag == 'bareos_director' |> -> exec { 'bareos director init catalog':
      command     => '/usr/lib/bareos/scripts/create_bareos_database && /usr/lib/bareos/scripts/make_bareos_tables && /usr/lib/bareos/scripts/grant_bareos_privileges',
      notify      => Service[$::bareos::director::service_name],
      refreshonly => true,
      tag         => ['bareos', 'bareos_director'],
    }
  }
}
