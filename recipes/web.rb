#
# Cookbook Name:: aws-lamp
# Recipe:: web
#
# Copyright 2013, Hello Future Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'aws'

###########################################################################
# Set up web virtual hosts
###########################################################################

sites = data_bag('sites')
 
sites.each do |site|
  opts = data_bag_item('sites', site)

  # Setup paths

  if opts.has_key?('path')
    path = node['aws-lamp']['docroot-dir'] + '/' + opts['path']
  else
    path = node['aws-lamp']['docroot-dir'] + '/' + opts['host']
  end

  docroot = path + '/' + node['aws-lamp']['web-dir']

  directory path do
    owner opts['user']
    group opts['group']
    mode "0775"
    action :create
    recursive true
  end

  directory docroot do
    owner opts['user']
    group opts['group']
    mode "0775"
    action :create
  end

  # Any virtual host aliases?

  if opts.has_key?('aliases')
    aliases = opts['aliases'] 
  else
    aliases = []
  end

  # Any redirects?

  if opts.has_key?('redirects')
    redirects = opts['redirects'] 
  else
    redirects = {}
  end

  web_app opts['host'] do
    template "site.conf.erb"
    server_name opts['host']
    path path
    docroot docroot
    log_dir node['aws-lamp']['log-dir']
    server_aliases aliases
    url_redirects redirects
  end

  cookbook_file docroot + "/test.html" do
    source "test.html"
    mode 00644
  end
end

###########################################################################
# Register instance with ELB
###########################################################################

# Get AWS credentials from the aws data_bag

aws = data_bag_item('aws', 'main')

aws_elastic_lb 'elb-' + node['aws-lamp']['elb-name'] do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  name node['aws-lamp']['elb-name'] 
  action :register
end