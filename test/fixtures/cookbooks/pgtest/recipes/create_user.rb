include_recipe 'postgresql_lwrp::default'

postgresql_user 'test01' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  encrypted_password 'test01'
  replication true
end

postgresql_user 'test-02' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  encrypted_password 'test-02'
  superuser true
end
