# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: bootstrap_slurm_accounting
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# This recipe bootstraps the Slurm accounting database with cluster, accounts, and users.
# It must run AFTER slurmctld has started and registered with slurmdbd.
#
# In Slurm 25.11+, slurmctld maintains a cluster_id in its state files. When slurmctld
# registers with slurmdbd, the cluster is created in the database using slurmctld's
# cluster_id. If we use `sacctmgr add cluster` before slurmctld registers, the DBD
# assigns a different cluster_id, causing a "CLUSTER ID MISMATCH" error.
#
# This recipe is used during cluster updates when adding accounting to an existing cluster.
# For cluster creation, the bootstrap is done in config_slurm_accounting.rb before slurmctld
# starts (which works because there's no pre-existing cluster_id in the state files).

if node['cluster']['slurmdbd_service_enabled'] == "true"
  execute "wait for slurm database" do
    command "#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr show clusters -Pn"
    retries node['cluster']['slurmdbd_response_retries']
    retry_delay 10
  end unless kitchen_test? || (node['cluster']['node_type'] == "ExternalSlurmDbd")

  bash "bootstrap slurm database" do
    user 'root'
    group 'root'
    code <<-BOOTSTRAP
      SACCTMGR_CMD=#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr
      CLUSTER_NAME=#{node['cluster']['stack_name']}
      DEF_ACCOUNT=pcdefault
      SLURM_USER=#{node['cluster']['slurm']['user']}
      DEF_USER=#{node['cluster']['cluster_user']}

      # Add cluster to database if it is not present yet
      [[ $($SACCTMGR_CMD show clusters -Pn cluster=$CLUSTER_NAME | grep $CLUSTER_NAME) ]] || \
          $SACCTMGR_CMD -iQ add cluster $CLUSTER_NAME

      # Add account-cluster association to database if it is not present yet
      [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT format=account | grep $DEF_ACCOUNT) ]] || \
          $SACCTMGR_CMD -iQ add account $DEF_ACCOUNT Cluster=$CLUSTER_NAME \
              Description="ParallelCluster default account" Organization="none"

      # Add user-account associations to database if they are not present yet
      [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT user=$SLURM_USER format=user | grep $SLURM_USER) ]] || \
          $SACCTMGR_CMD -iQ add user $SLURM_USER Account=$DEF_ACCOUNT AdminLevel=Admin
      [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT user=$DEF_USER format=user | grep $DEF_USER) ]] || \
          $SACCTMGR_CMD -iQ add user $DEF_USER Account=$DEF_ACCOUNT AdminLevel=Admin

      # sacctmgr might throw errors if the DEF_ACCOUNT is not associated to a cluster already defined on the database.
      # This is not important for the scope of this script, so we return 0.
      exit 0
    BOOTSTRAP
  end unless kitchen_test? || (node['cluster']['node_type'] == "ExternalSlurmDbd")
end
