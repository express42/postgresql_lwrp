include_recipe 'postgresql::default'

postgresql_database 'test01' do
  in_version node['postgresql']['defaults']['server']['version']
  in_cluster 'main'
  owner 'test01'
end

postgresql_database 'test02' do
  in_version node['postgresql']['defaults']['server']['version']
  in_cluster 'main'
  owner 'test02'
end
