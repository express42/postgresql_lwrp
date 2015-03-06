#
# Cookbook Name:: postgresql_lwrp
# Recipe:: cloud_backup
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) 2012-2014 LLC Express 42
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

include_recipe 'python'

# Install packages and pips
node['postgresql']['cloud_backup']['packages'].each do |pkg|
  package pkg
end

python_virtualenv node['postgresql']['cloud_backup']['wal_e_path']

case node['postgresql']['cloud_backup']['install_source']
when 'github'
  archive_url = "#{node['postgresql']['cloud_backup']['github_repo']}/archive/#{node['postgresql']['cloud_backup']['version']}.zip"
  python_pip 'wal-e' do
    package_name archive_url
    virtualenv node['postgresql']['cloud_backup']['wal_e_path']
  end
when 'pypi'
  python_pip 'wal-e' do
    version node['postgresql']['cloud_backup']['version']
    virtualenv node['postgresql']['cloud_backup']['wal_e_path']
  end
end

template 'postgresql cloud backup' do
  path "#{node['postgresql']['cloud_backup']['wal_e_path']}/bin/postgresql_cloud_backup_helper.sh"
  source 'postgresql_cloud_backup_helper.sh.erb'
  mode '0755'
  variables(
    wal_e_bin: node['postgresql']['cloud_backup']['wal_e_bin']
  )
end
