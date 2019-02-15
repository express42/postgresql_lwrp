include_recipe 'postgresql_lwrp::default'

postgresql_extension 'cube' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  db 'test01'
end

pgxn_extension 'semver' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  db 'test01'
  version '0.20.3'
  stage 'stable'
  only_if { node['pgtest']['version'].to_f > 9.1 }
end
