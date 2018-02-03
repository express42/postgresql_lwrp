include_recipe 'postgresql_lwrp::default'

postgresql_database 'test01' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  owner 'test01'
end

postgresql_database 'test-02' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  owner 'test-02'
end
