default['postgresql']['cloud_backup']['packages'] = %w(daemontools lzop mbuffer pv python-dev)
default['postgresql']['cloud_backup']['install_source'] = 'pypi'
default['postgresql']['cloud_backup']['version'] = '0.7.3'
default['postgresql']['cloud_backup']['wal_e_path'] = '/usr/local/bin/wal-e'
default['postgresql']['cloud_backup']['github_repo'] = 'https://github.com/wal-e/wal-e'
default['postgresql']['cloud_backup']['pips'] = %w(
  argparse
  boto
  gevent
)
