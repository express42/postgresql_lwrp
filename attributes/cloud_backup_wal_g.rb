default['postgresql']['cloud_backup']['wal_g']['packages'] = %w(
)

default['postgresql']['cloud_backup']['wal_g']['version'] = 'v0.2.11'
default['postgresql']['cloud_backup']['wal_g']['url'] = "https://github.com/wal-g/wal-g/releases/download/#{node['postgresql']['cloud_backup']['wal_g']['version']}/wal-g.linux-amd64.tar.gz"
default['postgresql']['cloud_backup']['wal_g']['checksum'] = '313a617311ad58005c407c2e9b06b3556785559b051e5fae5d147c17ba36f2bc'
default['postgresql']['cloud_backup']['wal_g']['bin'] = '/usr/local/bin/wal-g'
