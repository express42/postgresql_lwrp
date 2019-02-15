default['postgresql']['cloud_backup']['wal_g']['packages'] = %w(
)

default['postgresql']['cloud_backup']['wal_g']['version'] = 'v0.2.4'
default['postgresql']['cloud_backup']['wal_e']['url'] = "https://github.com/wal-g/wal-g/releases/download/#{node['postgresql']['cloud_backup']['wal_g']['version']}/wal-g.linux-amd64.tar.gz"
default['postgresql']['cloud_backup']['wal_g']['ckecksum'] = '9148de0fbf7427700d123d07194114bc19fbec4d007ca1ee5819ce748b4d72bb'
default['postgresql']['cloud_backup']['wal_g']['bin'] = '/usr/local/bin/wal-g'
