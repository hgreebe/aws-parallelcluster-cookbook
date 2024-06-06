# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

action :install do
  package new_resource.packages do
    case node[:platform]
    when 'amazon'
      options('--disablerepo="epel"')
    end
    retries 10
    retry_delay 5
    flush_cache({ before: true })
  end

  bash 'yum install missing deps' do
    user 'root'
    group 'root'
    code <<-REQ
    set -e
    aws s3 cp #{node['cluster']['artifacts_build_url']}/epel/rhel7/#{node['kernel']['machine']}/epel_deps.tar.gz epel_deps.tar.gz --region #{node['cluster']['region']}
    tar xzf epel_deps.tar.gz
    cd epel
    yum install -y * >/dev/null 2>&1
    REQ
  end

end

def kernel_source_package
  'kernel-devel'
end

def kernel_source_package_version
  node['kernel']['release'].chomp('.x86_64').chomp('.aarch64')
end
