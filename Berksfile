source 'https://supermarket.chef.io'

metadata

group :integration do
  cookbook 'sysctl'
  cookbook 'pgtest', path: 'test/fixtures/cookbooks/pgtest'
end

group :compat do
  cookbook 'build-essential', '<4.0'
end
