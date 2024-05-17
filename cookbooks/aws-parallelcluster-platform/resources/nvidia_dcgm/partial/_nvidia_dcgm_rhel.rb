# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

action :install_package do

  bash "Install #{dcgm_package}" do
    user 'root'
    code <<-DCGM_INSTALL
    set -e
    aws s3 cp #{dcgm_url} #{dcgm_package}-#{package_version}.rpm --region #{node['cluster']['region']}
    yum install -y #{dcgm_package}-#{package_version}.rpm
    DCGM_INSTALL
    retries 3
    retry_delay 5
  end

end

def dcgm_url
  "#{node['cluster']['artifacts_build_url']}/nvidia_dcgm/#{platform}/#{dcgm_package}-#{package_version}-1-#{arch_suffix}.rpm"
end

def dcgm_package
  'datacenter-gpu-manager'
end

def arch_suffix
  arm_instance? ? 'aarch64' : 'x86_64'
end

def package_version
  node['cluster']['nvidia']['dcgm_version']
end
