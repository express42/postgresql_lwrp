maintainer        "LLC Express 42"
maintainer_email  "info@express42.com"
license           "MIT"
description       "Installs and configures postgresql for clients or servers"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.1.3"
recipe            "postgresql::default", "Includes client recipe"
recipe            "postgresql::client", "Installs postgresql client packages"
recipe            "postgresql::server", "Installs postgresql server packages, configures postgresql"

supports          "debian"
