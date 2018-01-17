# encoding: utf-8
# author: Kirill Kuznetsov

class PostgresDatabase < Inspec.resource(1)
  name 'postgres_database'
  desc 'Use the postgres_database InSpec audit resource to test PostgreSQL cluster databases.'
  example "
    describe postgres_database('9.6', 'main', 'test01') do
      it { should be_created }
      it { should have_owner('test01')}
    end
  "

  def initialize(version, cluster, name)
    @name = name
    @version = version
    @cluster = cluster
    @port = get_port(version, cluster)
  end

  def created?
    return true if query("SELECT datname FROM pg_database where datname='#{@name}'") == @name
    false
  end

  def has_owner?(owner)
    return true if query("SELECT pg_get_userbyid(datdba) FROM pg_database where datname='#{@name}'") == owner
    false
  end

  def to_s
    "Database #{@name}"
  end

  private

  def query(query)
    psql_cmd = create_psql_cmd(query, 'postgres')
    cmd = inspec.command(psql_cmd)
    out = cmd.stdout + "\n" + cmd.stderr
    if cmd.exit_status != 0 || out =~ /could not connect to .*/ || out.downcase =~ /^error:.*/
      false
    else
      cmd.stdout.strip
    end
  end

  def escaped_query(query)
    Shellwords.escape(query)
  end

  def create_psql_cmd(query, db)
    "su postgres -c \"psql -d #{db} -p #{@port} -q -t -c #{escaped_query(query)}\""
  end

  def get_port(version, cluster)
    postmaster_content = inspec.command("cat /var/lib/postgresql/#{version}/#{cluster}/postmaster.pid").stdout.split
    postmaster_content[3].to_i
  end
end
