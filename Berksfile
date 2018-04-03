source 'https://supermarket.chef.io'

metadata

group :integration do
  cookbook 'sysctl'
  cookbook 'pgtest', path: 'test/fixtures/cookbooks/pgtest'
end

group :compat do
  cookbook 'build-essential'
  cookbook 'apt'
  cookbook 'ohai'
end
