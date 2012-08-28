default["postgresql"]["defaults"]["server"]["version"] = "9.1"

default["postgresql"]["defaults"]["server"]["connection"] = {
  :listen_addresses => "localhost",
  :port => 5432,
  :max_connections => "100",
  :unix_socket_directory => "'/var/run/postgresql'"
}

default["postgresql"]["defaults"]["server"]["resources"] = {
  :shared_buffers => "100MB",
  :temp_buffers => "8MB",
  :max_prepared_transactions => "0",
  :work_mem => "2MB",
  :maintenance_work_mem => "128MB",
  :max_stack_depth => "2MB",
  :max_files_per_process => "1000",
  :vacuum_cost_delay => "0"
}

default["postgresql"]["defaults"]["server"]["wal"] = {
  :wal_level => "hot_standby",
  :fsync => "on",
  :synchronous_commit => "on",
  :checkpoint_segments => "64",
  :wal_sync_method => "fsync",
  "checkpoint_completion_target" => "0.8"
}

default["postgresql"]["defaults"]["server"]["queries"] = {
  :effective_cache_size => "128MB"
}

default["postgresql"]["defaults"]["server"]["logging"] = {
  :log_destination => "'stderr'",
  :syslog_ident => "'postgres'",
  :log_min_duration_statement => "200",
  :log_truncate_on_rotation => "on",
  :log_rotation_age => "1d",
  :log_rotation_size => "0",
  :log_line_prefix => "'%t [%p]: [%l-1] '"
}

default["postgresql"]["defaults"]["server"]["statistics"] = {
  :track_activities => "on",
  :track_counts => "on"
}

default["postgresql"]["defaults"]["server"]["autovacuum"] = {
  :autovacuum => "on",
  :autovacuum_naptime => "1min"
}
default["postgresql"]["defaults"]["server"]["archiving"] = {
  :archive_mode => "off"
}
default["postgresql"]["defaults"]["server"]["replication"] = {
  :max_wal_senders => 5,
  :wal_keep_segments => 32
}
default["postgresql"]["defaults"]["server"]["standby"] = {
  :hot_standby => 'off',
  :max_standby_archive_delay => '30s',
  :max_standby_streaming_delay => '30s',
  :wal_receiver_status_interval => '10s',
  :hot_standby_feedback => 'off'
}
default["postgresql"]["defaults"]["server"]["client_connections"] = {
  :extra_float_digits => "0",
  :client_encoding => "UTF8"
}
default["postgresql"]["defaults"]["server"]["locale"] = {
  :lc_messages => "'en_US.UTF-8'",
  :lc_monetary => "'ru_RU.UTF-8'",
  :lc_numeric => "'ru_RU.UTF-8'",
  :lc_time => "'ru_RU.UTF-8'",
  :default_text_search_config => "'pg_catalog.russian'"
}

default["postgresql"]["defaults"]["ident_configuration"] = []

default["postgresql"]["defaults"]["hba_configuration"] = []
