include_recipe 'postgresql_lwrp::default'

postgresql_extension 'cube' do
  in_version node['postgresql']['defaults']['server']['version']
  in_cluster 'main'
  db 'test01'
end
