node.default['postgresql']['client']['version'] = node['pgtest']['version']

include_recipe 'pgtest::master'
include_recipe 'pgtest::create_user'
include_recipe 'pgtest::create_database'
include_recipe 'pgtest::install_ext'
include_recipe 'pgtest::slave'
include_recipe 'pgtest::slave_init_nostart'
include_recipe 'pgtest::cloud_backup'
