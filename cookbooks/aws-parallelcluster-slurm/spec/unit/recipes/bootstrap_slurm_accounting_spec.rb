# frozen_string_literal: true

require 'spec_helper'

describe 'aws-parallelcluster-slurm::bootstrap_slurm_accounting' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      %w(true false).each do |enable_service|
        context "when service enabled is #{enable_service}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['slurmdbd_service_enabled'] = enable_service
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          if enable_service == "true"
            it "waits for the Slurm database to respond" do
              is_expected.to run_execute("wait for slurm database").with(
                command: "#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr show clusters -Pn"
              )
            end

            it "bootstraps the Slurm database idempotently" do
              is_expected.to run_bash("bootstrap slurm database")
            end
          else
            it "does not wait for the Slurm database" do
              is_expected.not_to run_execute("wait for slurm database")
            end

            it "does not bootstrap the Slurm database" do
              is_expected.not_to run_bash("bootstrap slurm database")
            end
          end
        end
      end
    end
  end
end
