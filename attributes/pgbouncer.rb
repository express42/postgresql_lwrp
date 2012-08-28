default["postgresql"]["defaults"]["pgbouncer"]["pkg"] = "pgbouncer"

default["postgresql"]["defaults"]["pgbouncer"]["bind"] = {
  :listen_addr => "127.0.0.1",
  :listen_port => 6432,
  :unix_socket_dir => "/var/run/postgresql"
}

default["postgresql"]["defaults"]["pgbouncer"]["pgbouncer_config"] = "/etc/pgbouncer/pgbouncer.ini"

default["postgresql"]["defaults"]["pgbouncer"]["auth"] = {
  :auth_type => "plain",
  :auth_file => "/etc/pgbouncer/userlist.txt"
}

default["postgresql"]["defaults"]["pgbouncer"]["pool_mode"] = "session"
default["postgresql"]["defaults"]["pgbouncer"]["users"] = Hash.new
default["postgresql"]["defaults"]["pgbouncer"]["admin_users"] = Array.new
default["postgresql"]["defaults"]["pgbouncer"]["stats_users"] = Array.new

default["postgresql"]["defaults"]["pgbouncer"]["limits"] = {
  :max_client_conn => 3000,
  :default_pool_size => 2000,
  :reserve_pool_size => 20,
  :reserve_pool_timeout => 3
}

default["postgresql"]["defaults"]["pgbouncer"]["network"] = {
  :tcp_keepalive => 1
}

default["postgresql"]["defaults"]["pgbouncer"]["logger"] = {
  :log_connections => 1,
  :log_disconnections => 1,
  :log_pooler_errors => 1,
  :logfile => "/var/log/postgresql/pgbouncer.log",
  :pidfile => "/var/run/postgresql/pgbouncer.pid"
}

default["postgresql"]["defaults"]["pgbouncer"]["server_reset_query"] = 'DISCARD ALL;'

default["postgresql"]["defaults"]["pgbouncer"]["misc"] = {
  :ignore_startup_parameters => "application_name"
}
