# frozen_string_literal: true

provides :install_pyenv
unified_mode true

# Resource:: to create a Python virtual environment for a given user
property :home_dir,
         String,
         default: lazy { ::File.expand_path("~#{user}") }
property :user_only, [true, false], default: false
property :user, String
property :prefix,
         String,
         default: lazy {
           if user_only
             ::File.join(home_dir, '.pyenv')
           else
             '/usr/local/pyenv'
           end
         },
         description: 'Path to install pyenv to'
property :python_version, String
property :prefix, String
default_action :run

action :run do
  python_version = new_resource.python_version || node['cluster']['python-version']

  if new_resource.user_only
    raise "user property is required for resource install_pyenv when user_only is set to true" unless new_resource.user

  else
    prefix = new_resource.prefix || node['cluster']['system_pyenv_root']
  end

  directory prefix do
    recursive true
  end

  remote_file "#{prefix}/Python-#{python_version}.tgz" do
    source "#{node['cluster']['artifacts_s3_url']}/dependencies/python/Python-#{python_version}.tgz"
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  user = new_resource.user || 'root'

  bash "install python #{python_version}" do
    user user
    group 'root'
    cwd "#{prefix}"
    code <<-VENV
    set -e
    tar -xzf Python-#{python_version}.tgz 
    cd Python-#{python_version}
    ./configure --prefix=#{prefix}/versions/#{python_version}
    make
    make install
    VENV
  end

end
