include_recipe 'postgresql::official_repository'
include_recipe 'postgresql::default'

postgresql 'main' do
  cluster_create_options('locale' => 'ru_RU.UTF-8')
  configuration(
    connection: {
      max_connections: 300,
      ssl_renegotiation_limit: 0
    },
    resources: {
      shared_buffers: '64MB',
      maintenance_work_mem: '8MB',
      work_mem: '2MB'
    },
    queries: { effective_cache_size: '200MB' },
    wal: { checkpoint_completion_target: '0.9' },
    logging: { log_min_duration_statement: '200' }
  )
  hba_configuration(
    [
      { type: 'host', database: 'all', user: 'all', address: '0.0.0.0/0', method: 'md5' },
      { type: 'host', database: 'replication', user: 'postgres', address: '0.0.0.0/0', method: 'md5' }
    ]
  )
end
