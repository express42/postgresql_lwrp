include_recipe 'postgresql_lwrp::default'

postgresql_extension 'cube' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  db 'test01'
end

pgxn_extension 'count_distinct' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  db 'test01'
  version '1.3.2'
  stage 'stable'
end
