# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_compute
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

cookbook_file '/etc/systemd/system/check-update.service' do
  source 'check_update/check-update.service'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

cookbook_file '/etc/systemd/system/check-update.timer' do
  source 'check_update/check-update.timer'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

service 'check-update.timer' do
  action [:enable, :start]
end
