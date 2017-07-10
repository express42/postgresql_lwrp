require 'serverspec'

set :backend, :exec
set :path, '/sbin:/usr/sbin:$PATH'

RUNNING = 0
STOPPED = 3

def get_port(version, name)
  postmaster_content = command("cat /var/lib/postgresql/#{version}/#{name}/postmaster.pid").stdout.split
  postmaster_content[3].to_i
end

def postgresql_cluster(version, name)
  command("su postgres -c \"/usr/lib/postgresql/#{version}/bin/pg_ctl -D /var/lib/postgresql/#{version}/#{name} status\"").exit_status
end

def postgresql_check_owner(version, name, database, user)
  pg_port = get_port(version, name)
  psql_out = command("su postgres -c \"psql -p #{pg_port} -tql 2>/dev/null\"").stdout.strip.split("\n")
  psql_out.each do |t|
    return true if t.split('|')[0].strip == database && t.split('|')[1].strip == user
  end
  false
end

def postgresql_check_priv(version, name, user, priv)
  pg_port = get_port(version, name)
  psql_out = command("su postgres -c \"psql -qt -p #{pg_port} -c \\\"SELECT #{priv} FROM pg_roles where rolname='#{user}'\\\" 2>/dev/null\"").stdout.strip
  psql_out == 't'
end

def postgresql_check_login(version, name, user, password)
  pg_port = get_port(version, name)
  psql_out = command("PGPASSWORD='#{password}' su postgres -c \"psql -h 127.0.0.1 -p #{pg_port} -U #{user} -d postgres -c \\\"SELECT 1\\\" 2>/dev/null\"").exit_status
  psql_out == 0
end

def postgresql_extension_installed?(version, name, database, extension)
  pg_port = get_port(version, name)
  psql_out = command("echo -n \"SELECT extname FROM pg_extension\"| sudo -u postgres psql -t -p \"#{pg_port}\" \"#{database}\" 2>/dev/null")
  return true if psql_out.stdout.include? extension
  false
end

def master_tests(pg_version)
  describe package("postgresql-#{pg_version}") do
    it { should be_installed }
  end

  describe service('postgresql') do
    it { should be_enabled }
  end

  describe 'master service postgresql' do
    it 'should be running' do
      expect(postgresql_cluster(pg_version, 'main')).to eq(RUNNING)
    end
  end

  describe port(5432) do
    it { should be_listening }
  end
end

def create_database_tests(pg_version)
  describe 'database test01' do
    it 'should be created and have owner test01' do
      expect(postgresql_check_owner(pg_version, 'main', 'test01', 'test01')).to eq(true)
    end
  end

  describe 'database test-02' do
    it 'should be created and have owner test-02' do
      expect(postgresql_check_owner(pg_version, 'main', 'test-02', 'test-02')).to eq(true)
    end
  end
end

def create_users_tests(pg_version)
  describe 'user test01' do
    it 'should be able to login with password' do
      expect(postgresql_check_login(pg_version, 'main', 'test01', 'test01')).to eq(true)
    end
    it 'should have replication privileges' do
      expect(postgresql_check_priv(pg_version, 'main', 'test01', 'rolreplication')).to eq(true)
    end
    it 'should not have replication privileges' do
      expect(postgresql_check_priv(pg_version, 'main', 'test01', 'rolsuper')).to eq(false)
    end
  end

  describe 'user test-02' do
    it 'should be able to login with password' do
      expect(postgresql_check_login(pg_version, 'main', 'test-02', 'test-02')).to eq(true)
    end
    it 'should have replication privileges' do
      expect(postgresql_check_priv(pg_version, 'main', 'test-02', 'rolsuper')).to eq(true)
    end
  end
end

def install_extension_tests(pg_version)
  describe 'extension should be installed for test01 database' do
    it 'extension from postgresql-contrib should be installed' do
      expect(postgresql_extension_installed?(pg_version, 'main', 'test01', 'cube')).to eq(true)
    end
    it 'extension from pgxn should be installed' do
      expect(postgresql_extension_installed?(pg_version, 'main', 'test01', 'count_distinct')).to eq(true)
    end
  end
end

def slave_tests(pg_version)
  describe package("postgresql-#{pg_version}") do
    it { should be_installed }
  end

  describe service('postgresql') do
    it { should be_enabled }
  end

  describe 'slave service postgresql' do
    it 'should be running' do
      expect(postgresql_cluster(pg_version, 'slave')).to eq(RUNNING)
    end
  end

  describe 'another slave service postgresql' do
    it 'should be not running' do
      expect(postgresql_cluster(pg_version, 'slave2')).to eq(STOPPED)
    end
  end

  describe port(5433) do
    it { should be_listening }
  end

  describe port(5434) do
    it { should_not be_listening }
  end
end

def cloud_backup_tests
  %w(daemontools lzop mbuffer pv python-dev).each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
  describe package('virtualenv') do
    it { should be_installed.by('pip') }
  end
  describe package('wal-e') do
    let(:path) { '/opt/wal-e/bin:$PATH' }
    it { should be_installed.by('pip') }
  end
  describe command('/opt/wal-e/bin/wal-e version') do
    its(:exit_status) { should eq 0 }
  end
end
