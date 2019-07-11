postgresql_cloud_backup 'test-wal-e' do
  in_version node['pgtest']['version']
  in_cluster 'main'
  parameters(
    'PGPORT' => '5432',
    'AWS_ACCESS_KEY_ID' => 'example',
    'AWS_SECRET_ACCESS_KEY' => 'example',
    'WALE_S3_PREFIX' => 'example'
  )
end

postgresql_cloud_backup 'test-wal-g' do
  utility 'wal-g'
  in_version node['pgtest']['version']
  in_cluster 'walg'
  parameters(
    'PGPORT' => '5432',
    'AWS_ACCESS_KEY_ID' => 'example',
    'AWS_SECRET_ACCESS_KEY' => 'example',
    'WALG_S3_PREFIX' => 'example'
  )
end
