node.default['postgresql']['defaults']['server']['version'] = '9.0'
node.override['postgresql']['defaults']['server']['hba_configuration'] = [
    { type: 'local', database: 'all', user: 'postgres', address: '',        method: 'ident' },
    { type: 'local', database: 'all', user: 'all', address: '',             method: 'ident' },
    { type: 'host',  database: 'all', user: 'all', address: '127.0.0.1/32', method: 'md5'  },
    { type: 'host',  database: 'all', user: 'all', address: '::1/128',      method: 'md5'  }
]
include_recipe 'pgtest::master'
