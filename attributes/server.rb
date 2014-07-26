default['postgresql']['defaults']['server']['version'] = '9.2'

default['postgresql']['defaults']['server']['configuration']['listen_addresses'] = 'localhost'
default['postgresql']['defaults']['server']['configuration']['port'] = 5432
default['postgresql']['defaults']['server']['configuration']['max_connections'] = 100
default['postgresql']['defaults']['server']['configuration']['shared_buffers'] = '100MB'
default['postgresql']['defaults']['server']['configuration']['temp_buffers'] = '8MB'
default['postgresql']['defaults']['server']['configuration']['max_prepared_transactions'] = 0
default['postgresql']['defaults']['server']['configuration']['work_mem'] = '2MB'
default['postgresql']['defaults']['server']['configuration']['maintenance_work_mem'] = '64MB'
default['postgresql']['defaults']['server']['configuration']['max_stack_depth'] = '2MB'
default['postgresql']['defaults']['server']['configuration']['max_files_per_process'] = '1000'
default['postgresql']['defaults']['server']['configuration']['vacuum_cost_delay'] = 0
default['postgresql']['defaults']['server']['configuration']['wal_level'] = 'hot_standby'
default['postgresql']['defaults']['server']['configuration']['fsync'] =  'on'
default['postgresql']['defaults']['server']['configuration']['synchronous_commit'] = 'on'
default['postgresql']['defaults']['server']['configuration']['checkpoint_segments'] = '64'
default['postgresql']['defaults']['server']['configuration']['wal_sync_method'] = 'fsync'
default['postgresql']['defaults']['server']['configuration']['checkpoint_completion_target'] = '0.9'
default['postgresql']['defaults']['server']['configuration']['effective_cache_size'] = node['memory']['total'].to_i / 2
default['postgresql']['defaults']['server']['configuration']['log_destination'] = 'stderr'
default['postgresql']['defaults']['server']['configuration']['syslog_ident'] = 'postgres'
default['postgresql']['defaults']['server']['configuration']['log_min_duration_statement'] = 200
default['postgresql']['defaults']['server']['configuration']['log_truncate_on_rotation'] = 'on'
default['postgresql']['defaults']['server']['configuration']['log_rotation_age'] = '1d'
default['postgresql']['defaults']['server']['configuration']['log_rotation_size'] = 0
default['postgresql']['defaults']['server']['configuration']['log_line_prefix'] = '%t [%p]: [%l-1]'
default['postgresql']['defaults']['server']['configuration']['track_activities'] = 'on'
default['postgresql']['defaults']['server']['configuration']['track_counts'] = 'on'
default['postgresql']['defaults']['server']['configuration']['autovacuum'] = 'on'
default['postgresql']['defaults']['server']['configuration']['autovacuum_naptime'] = '1min'
default['postgresql']['defaults']['server']['configuration']['archive_mode'] = 'off'
default['postgresql']['defaults']['server']['configuration']['max_wal_senders'] = 5
default['postgresql']['defaults']['server']['configuration']['wal_keep_segments'] = 32
default['postgresql']['defaults']['server']['configuration']['hot_standby'] = 'off'
default['postgresql']['defaults']['server']['configuration']['max_standby_archive_delay'] = '30s'
default['postgresql']['defaults']['server']['configuration']['max_standby_streaming_delay'] = '30s'
default['postgresql']['defaults']['server']['configuration']['wal_receiver_status_interval'] = '10s'
default['postgresql']['defaults']['server']['configuration']['hot_standby_feedback'] = 'on'
default['postgresql']['defaults']['server']['configuration']['extra_float_digits'] = 0
default['postgresql']['defaults']['server']['configuration']['client_encoding'] = 'UTF8'
default['postgresql']['defaults']['server']['configuration']['ssl'] = true
default['postgresql']['defaults']['server']['configuration']['ssl_cert_file'] = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
default['postgresql']['defaults']['server']['configuration']['ssl_key_file'] = '/etc/ssl/private/ssl-cert-snakeoil.key'
default['postgresql']['defaults']['server']['configuration']['ssl_renegotiation_limit'] = 0
default['postgresql']['defaults']['server']['configuration']['lc_messages'] = 'en_US.UTF-8'
default['postgresql']['defaults']['server']['configuration']['lc_monetary'] = 'en_US.UTF-8'
default['postgresql']['defaults']['server']['configuration']['lc_numeric'] = 'en_US.UTF-8'
default['postgresql']['defaults']['server']['configuration']['lc_time'] = 'en_US.UTF-8'
default['postgresql']['defaults']['server']['configuration']['default_text_search_config'] = 'pg_catalog.russian'

default['postgresql']['defaults']['server']['ident_configuration'] = []

default['postgresql']['defaults']['server']['hba_configuration'] = [
  { type: 'local', database: 'all', user: 'postgres', address: '',        method: 'peer' },
  { type: 'local', database: 'all', user: 'all', address: '',             method: 'peer' },
  { type: 'host',  database: 'all', user: 'all', address: '127.0.0.1/32', method: 'md5'  },
  { type: 'host',  database: 'all', user: 'all', address: '::1/128',      method: 'md5'  }
]
