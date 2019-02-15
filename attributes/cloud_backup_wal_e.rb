# https://github.com/poise/poise-python/issues/133
default['poise-python']['options']['pip_version'] = '18.0'

default['postgresql']['cloud_backup']['wal_e']['packages'] = %w(
  gcc
  lzop
  mbuffer
  pv
  python3-dev
  libffi-dev
  libssl-dev
)

default['postgresql']['cloud_backup']['wal_e']['pypi_packages'] = %w(
  boto
)

default['postgresql']['cloud_backup']['wal_e']['install_source'] = 'pypi'
default['postgresql']['cloud_backup']['wal_e']['version'] = '1.1.0'
default['postgresql']['cloud_backup']['wal_e']['bin'] = '/opt/wal-e/bin/wal-e'
default['postgresql']['cloud_backup']['wal_e']['path'] = '/opt/wal-e'
default['postgresql']['cloud_backup']['wal_e']['github_repo'] = 'https://github.com/wal-e/wal-e'
