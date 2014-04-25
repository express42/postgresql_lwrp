include_recipe 'postgresql::default'

postgresql_user 'test01' do
  in_version '9.2'
  in_cluster 'main'
  unencrypted_password 'test01'
  replication true
end

postgresql_user 'test02' do
  in_version '9.2'
  in_cluster 'main'
  unencrypted_password 'test02'
  superuser true
end
