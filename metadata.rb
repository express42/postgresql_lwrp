name             'postgresql'
maintainer       'LLC Express 42'
maintainer_email 'cookbooks@express42.com'
license          'MIT'
description      'Installs and configures postgresql for clients or servers'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'
recipe           'postgresql::default', 'Installs postgresql client packages'

supports         'debian'
supports         'ubuntu'
