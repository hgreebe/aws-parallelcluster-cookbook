# frozen_string_literal: true

# Copyright:: 2026 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'aws-parallelcluster-slurm::config_health_check' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      {
        nil => { wait_exec: 'true', skip_busy_gpus: 'true' },
        'false' => { wait_exec: 'true', skip_busy_gpus: 'true' },
        'true' => { wait_exec: 'false', skip_busy_gpus: 'false' },
      }.each do |legacy_behavior, expected|
        context "when gpu_health_check legacy_behavior is #{legacy_behavior.inspect}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['gpu_health_check']['legacy_behavior'] = legacy_behavior unless legacy_behavior.nil?
            end
            runner.converge(described_recipe)
          end
          cached(:prolog_path) do
            "#{chef_run.node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/prolog.d/90_pcluster_health_check_manager"
          end

          it 'creates the health check manager prolog' do
            is_expected.to create_template(prolog_path).with(
              source: 'slurm/head_node/health_check/90_pcluster_health_check_manager.erb',
              owner: 'root',
              group: 'root',
              mode: '0755'
            )
          end

          it "renders WAIT_EXEC=#{expected[:wait_exec]}" do
            is_expected.to render_file(prolog_path).with_content("WAIT_EXEC=#{expected[:wait_exec]}")
          end

          it "renders PCLUSTER_GPU_HEALTH_CHECK_SKIP_BUSY_GPUS=#{expected[:skip_busy_gpus]}" do
            is_expected.to render_file(prolog_path)
              .with_content("export PCLUSTER_GPU_HEALTH_CHECK_SKIP_BUSY_GPUS=#{expected[:skip_busy_gpus]}")
          end
        end
      end
    end
  end
end
