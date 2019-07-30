default['postgresql']['cloud_backup']['wal_g']['packages'] = %w(
)

default['postgresql']['cloud_backup']['wal_g']['version'] = 'v0.2.9'
default['postgresql']['cloud_backup']['wal_e']['url'] = "https://github.com/wal-g/wal-g/releases/download/#{node['postgresql']['cloud_backup']['wal_g']['version']}/wal-g.linux-amd64.tar.gz"
default['postgresql']['cloud_backup']['wal_g']['checksum'] = '433fee2d28c3bcfaf6aa5e6a235af8b52f3d9c75898e5f28e3dbb66309e7a623'
default['postgresql']['cloud_backup']['wal_g']['bin'] = '/usr/local/bin/wal-g'
