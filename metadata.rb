name             'postgresql_lwrp'
maintainer       'LLC Express 42'
maintainer_email 'cookbooks@express42.com'
license          'MIT'
description      'Installs and configures postgresql for clients or servers'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.4.2'
chef_version     '>= 12.5' if respond_to?(:chef_version)
source_url       'https://github.com/express42/postgresql_lwrp' if respond_to?(:source_url)
issues_url       'https://github.com/express42/postgresql_lwrp/issues' if respond_to?(:issues_url)

recipe           'postgresql_lwrp::default', 'Installs postgresql client packages'
recipe           'postgresql_lwrp::apt_official_repository', 'Setup official apt repository'
recipe           'postgresql_lwrp::cloud_backup', 'Setup cloud backup via wal-e utility'

depends          'apt'
depends          'poise-python', '>= 1.7.0'
depends          'cron'

supports         'debian'
supports         'ubuntu'
