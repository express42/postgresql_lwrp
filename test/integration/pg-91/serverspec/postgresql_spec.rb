require 'spec_helper'

pg_version = '9.1'

describe package("postgresql-#{pg_version}") do
  it { should be_installed }
end

describe service('postgresql') do
  it { should be_enabled }
end

describe 'master service postgresql' do
  it 'should be running' do
    postgresql_cluster(pg_version, 'main').should be RUNNING
  end
end

describe port(5432) do
  it { should be_listening }
end
