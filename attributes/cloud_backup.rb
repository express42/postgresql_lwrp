default['postgresql']['cloud_backup']['packages'] = %w(daemontools lzop mbuffer pv python-dev libffi-dev)
default['postgresql']['cloud_backup']['install_source'] = 'pypi'
default['postgresql']['cloud_backup']['version'] = '0.7.3'
default['postgresql']['cloud_backup']['wal_e_bin'] = '/opt/wal-e/bin/wal-e'
default['postgresql']['cloud_backup']['wal_e_path'] = '/opt/wal-e'
default['postgresql']['cloud_backup']['github_repo'] = 'https://github.com/wal-e/wal-e'
