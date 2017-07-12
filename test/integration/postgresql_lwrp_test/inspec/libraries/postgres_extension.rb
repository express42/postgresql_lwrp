# encoding: utf-8
# author: Dmitry Mischenko

class PostgresExtension < Inspec.resource(1)
  name 'postgres_extension'
  desc 'Use the postgres_extension InSpec audit resource to test installation of PostgreSQL database extensions'
  example "
    describe postgres_extension('cube', ['test01']) do
      it { should be_installed }
    end
  "

  def initialize(name, db = ['postgres'], host = 'localhost', port = nil)
    @name = name
    @db = db
    version = version_from_psql
    cluster = cluster_from_dir("/etc/postgresql/#{version}")
    @host = host
    @port = port || get_port(version, cluster)
  end

  def installed?
    return true if query('SELECT extname FROM pg_extension').include? @name
    false
  end

  def to_s
    "Extension #{@name}"
  end

  private

  def get_port(version, cluster)
    postmaster_content = inspec.command("cat /var/lib/postgresql/#{version}/#{cluster}/postmaster.pid").stdout.split
    postmaster_content[3].to_i
  end

  def query(query)
    psql_cmd = create_psql_cmd(query, @db)
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

  def create_psql_cmd(query, db = [])
    dbs = db.map { |x| "-d #{x}" }.join(' ')
    "su postgres -c \"psql #{dbs} -p #{@port} -q  -t -c #{escaped_query(query)}\""
  end

  def version_from_psql
    return unless inspec.command('psql').exist?
    inspec.command("psql --version | head -n 1 | awk '{ print $NF }' | awk -F. '{ print $1\".\"$2 }'").stdout.strip
  end

  def cluster_from_dir(dir)
    if inspec.directory("#{dir}/main").exist?
      'main'
    else
      dirs = inspec.command("ls -d #{dir}/*/").stdout.lines
      first = dirs.first.chomp.split('/').last
      if dirs.count > 1
        warn "Multiple postgresql clusters configured or incorrect base dir #{dir}"
        warn "Using the first directory found: #{first}"
      end
      first
    end
  end
end
