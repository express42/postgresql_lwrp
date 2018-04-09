# # encoding: utf-8

# Inspec default test

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

pg_version = attribute('pg_version', default: nil, description: 'Set postgresql version')

control 'postgres users' do
  title 'Users should be configured'

  describe postgres_user(pg_version, 'main', 'test01', 'test01') do
    it { should have_login }
    it { should have_privilege('rolreplication') }
    it { should_not have_privilege('rolsuper') }
  end

  describe postgres_user(pg_version, 'main', 'test-02', 'test-02') do
    it { should have_login }
    it { should have_privilege('rolsuper') }
  end
end

control 'postgres master' do
  title 'Postgres cluster'

  describe package("postgresql-#{pg_version}") do
    it { should be_installed }
  end

  # Chef 14 resource service is broken on a first run on Ubuntu 14.
  if os.name == 'ubuntu' && os.release.to_f > 14.04
    describe service('postgresql') do
      it { should be_enabled }
    end
  end

  describe postgres_cluster(pg_version, 'main') do
    it { should be_running }
  end

  describe port(5432) do
    it { should be_listening }
  end
end

control 'postgres databases' do
  title 'Check postgres databases'

  describe postgres_database(pg_version, 'main', 'test01') do
    it { should be_created }
    it { should have_owner('test01') }
  end

  describe postgres_database(pg_version, 'main', 'test-02') do
    it { should be_created }
    it { should have_owner('test-02') }
    it { should_not have_owner('test01') }
  end

  describe postgres_database(pg_version, 'main', 'test-03') do
    it { should_not be_created }
  end
end

control 'postgres extensions' do
  title 'Check postgres extensions'
  describe postgres_extension(pg_version, 'main', 'cube', 'test01') do
    it { should be_installed }
  end

  describe postgres_extension(pg_version, 'main', 'count_distinct', 'test01') do
    it { should be_installed }
  end
end

control 'postgres slave' do
  title 'Postgres cluster'
  # Chef 14 resource service is broken on a first run on Ubuntu 14.
  if os.name == 'ubuntu' && os.release.to_f > 14.04
    describe service('postgresql') do
      it { should be_enabled }
    end
  end

  describe postgres_cluster(pg_version, 'slave') do
    it { should be_running }
  end

  describe postgres_cluster(pg_version, 'slave2') do
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

  %w(
    daemontools
    lzop
    mbuffer
    pv
    python3-dev
  ).each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end

  %w(
    wal-e
    boto
  ).each do |pip_package|
    describe pip(pip_package, '/opt/wal-e/bin/pip') do
      it { should be_installed }
    end
  end
end
