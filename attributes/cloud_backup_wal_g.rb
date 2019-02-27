default['postgresql']['cloud_backup']['wal_g']['packages'] = %w(
)

default['postgresql']['cloud_backup']['wal_g']['version'] = 'v0.2.6'
default['postgresql']['cloud_backup']['wal_e']['url'] = "https://github.com/wal-g/wal-g/releases/download/#{node['postgresql']['cloud_backup']['wal_g']['version']}/wal-g.linux-amd64.tar.gz"
default['postgresql']['cloud_backup']['wal_g']['ckecksum'] = 'a743d11592feff6f63c995044060bfd9ba5870f43f71bfc5b67c74e095d33136'
default['postgresql']['cloud_backup']['wal_g']['bin'] = '/usr/local/bin/wal-g'
