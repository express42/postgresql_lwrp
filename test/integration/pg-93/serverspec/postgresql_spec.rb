require 'spec_helper'

pg_version = '9.3'

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

describe 'slave service postgresql' do
  it 'should be running' do
    postgresql_cluster(pg_version, 'slave').should be RUNNING
  end
end

describe 'another slave service postgresql' do
  it 'should be not running' do
    postgresql_cluster(pg_version, 'slave2').should be STOPPED
  end
end

describe port(5432) do
  it { should be_listening }
end

describe port(5433) do
  it { should be_listening }
end
