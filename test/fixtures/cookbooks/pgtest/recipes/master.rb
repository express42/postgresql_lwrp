include_recipe 'postgresql_lwrp::apt_official_repository'
include_recipe 'postgresql_lwrp::default'
include_recipe 'sysctl::default'

sysctl_param 'kernel.shmmax' do
  value 68_719_476_736
end

postgresql 'main' do
  cluster_create_options('locale' => 'en_US.UTF-8')
  cluster_version node['pgtest']['version']
  configuration(
    listen_addresses: '*',
    max_connections: 300,
    ssl_renegotiation_limit: 0,
    archive_mode: 'on',
    archive_command: 'exit 0',
    shared_buffers: '64MB',
    maintenance_work_mem: '8MB',
    work_mem: '2MB',
    effective_cache_size: '200MB'
  )
  hba_configuration(
    [
      { type: 'host', database: 'all', user: 'all', address: '0.0.0.0/0', method: 'md5' },
      { type: 'host', database: 'replication', user: 'postgres', address: '127.0.0.1/32', method: 'trust' },
    ]
  )
end
