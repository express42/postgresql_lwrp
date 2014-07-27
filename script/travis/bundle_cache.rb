require 'fog'

file_name = 'bundle.tgz'
s3_file_path = "postgresql-cookbook/#{file_name}"
local_file_path = file_name

storage = Fog::Storage.new(
                             provider: 'AWS',
                             aws_access_key_id: ENV['AWS_KEY'],
                             aws_secret_access_key: ENV['AWS_SECRET_KEY']
)

`rm -rf #{local_file_path}`
`tar -cjf bundle.tgz .bundle`

bucket = storage.directories.get(ENV['AWS_BUCKET'])
file = File.open(local_file_path)
bucket.files.create(body: file.read, key: s3_file_path, public: true)
