name             'postgresql_lwrp'
maintainer       'LLC Express 42'
maintainer_email 'cookbooks@express42.com'
license          'MIT'
description      'Installs and configures postgresql for clients or servers'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.2.1'

recipe           'postgresql_lwrp::default', 'Installs postgresql client packages'
recipe           'postgresql_lwrp::apt_official_repository', 'Setup official apt repository'
recipe           'postgresql_lwrp::cloud_backup', 'Setup cloud backup via wal-e utility'

depends          'apt'
depends          'python'
depends          'cron'

supports         'debian'
supports         'ubuntu'

conflicts        'database'
