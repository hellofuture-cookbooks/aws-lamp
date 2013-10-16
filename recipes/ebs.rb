#
# Cookbook Name:: aws-lamp
# Recipe:: ebs
#
# Set up EBS storage for this server
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

###########################################################################
# Set up a ELB drive for this server
###########################################################################

# Hat tip to http://clarkdave.net/2013/04/managing-ebs-volumes-with-chef/

elb_drive_name = node.name + '_elb'

# Get an unused device ID for the EBS volume

devices = Dir.glob('/dev/xvd?')
devices = ['/dev/xvdf'] if devices.empty?
devid = devices.sort.last[-1,1].succ

# Save the device used for data_volume on this node -- this volume will
# now always be attached to this device

node.set_unless['aws']['ebs_volume']['data_volume']['device'] = "/dev/xvd#{devid}"
device_id = node['aws']['ebs_volume']['data_volume']['device']

# Create and attach the volume to the device determined above

aws_ebs_volume elb_drive_name do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  size node['aws-lamp']['ebs_size']
  device device_id.gsub('xvd', 'sd') # aws uses sdx instead of xvdx
  action [:create, :attach]
end

# wait for the drive to attach, before making a filesystem
ruby_block "sleeping_data_volume" do
  loop do
    if File.blockdev?(device_id)
      break
    else
      Chef::Log.info("device #{device_id} not ready - sleeping 10s")
      sleep 10
    end
  end
end

mount_point = node['aws-lamp']['ebs_path'] 

directory mount_point do
  owner "root"
  group "root"
  mode "0775"
  action :create
end

# create a filesystem
execute 'mkfs' do
  command "mkfs -t ext4 #{device_id}"
  # only if it's not mounted already
  not_if "grep -qs #{mount_point} /proc/mounts"
end

# now we can enable and mount it and we're done!
mount "#{mount_point}" do
  device device_id
  fstype 'ext4'
  options 'noatime,nobootwait'
  action [:enable, :mount]
end