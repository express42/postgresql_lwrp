# # encoding: utf-8

# Inspec default test

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

pg_version = attribute('pg_version', default: nil, description: 'Set postgresql version')

control 'postgres users' do
  title 'Users should be configured'
  describe postgres_user('test01', 'test01') do
    it { should have_login }
    it { should have_privilege('rolreplication') }
    it { should_not have_privilege('rolsuper') }
  end

  describe postgres_user('test-02', 'test-02') do
    it { should have_login }
    it { should have_privilege('rolsuper') }
  end
end
control 'postgres master' do
  title 'Postgres cluster'
  describe package("postgresql-#{pg_version}") do
    it { should be_installed }
  end
  describe service('postgresql') do
    it { should be_enabled }
  end
  describe postgres_cluster('main') do
    it { should be_running }
  end
  describe port(5432) do
    it { should be_listening }
  end
end

control 'postgres extensions' do
  title 'Check postgres extensions'
  describe postgres_extension('cube', ['test01']) do
    it { should be_installed }
  end

  describe postgres_extension('count_distinct', ['test01']) do
    it { should be_installed }
  end
end
control 'postgres slave' do
  title 'Postgres cluster'
  describe service('postgresql') do
    it { should be_enabled }
  end

  describe postgres_cluster('slave') do
    it { should be_running }
  end

  describe postgres_cluster('slave2') do
    it { should be_stopped }
  end

  describe port(5433) do
    it { should be_listening }
  end

  describe port(5434) do
    it { should_not be_listening }
  end
end

control 'cloud_backup_tests' do
  title 'Check cloud backup installation'

  %w(daemontools lzop mbuffer pv python-dev).each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end

  describe pip('virtualenv') do
    it { should be_installed }
  end

  describe command('/opt/wal-e/bin/pip show wal-e') do
    its(:exit_status) { should eq 0 }
  end
end
