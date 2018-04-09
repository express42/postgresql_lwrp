#
# Cookbook Name:: postgresql_lwrp
# Resource:: pgxn_extension
#
# Author::LLC Express 42 (info@express42.com)
#
# Copyright (C) 2016 LLC Express 42
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

include Chef::Postgresql::Helpers

provides :pgxn_extension
resource_name :pgxn_extension

default_action :install

property :in_version, String, required: true
property :in_cluster, String, required: true
property :db, String, required: true
property :schema, String
property :version, String, required: true
property :stage, String, required: true

action :install do
  options = {}
  options['--schema'] = new_resource.schema.to_s if new_resource.schema
  params = {}
  params[:name] = new_resource.name.to_s if new_resource.name
  params[:stage] = new_resource.stage.to_s if new_resource.stage
  params[:version] = new_resource.version.to_s if new_resource.version
  params[:db] = new_resource.db.to_s if new_resource.db
  converge_by 'install pgxn extension' do
    pgxn_install_extension(new_resource.in_version, new_resource.in_cluster, params, options)
  end
end
