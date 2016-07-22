source 'https://supermarket.chef.io'

metadata

group :integration do
  cookbook 'sysctl', '<0.8.0'
  cookbook 'pgtest', path: 'test/fixtures/cookbooks/pgtest'
end

group :compat do
  cookbook 'build-essential', '<4.0'
  cookbook 'apt', '<4.0'
  cookbook 'ohai', '=3.0.1'
end
