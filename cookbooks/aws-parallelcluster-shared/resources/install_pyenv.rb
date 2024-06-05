# frozen_string_literal: true

provides :install_pyenv
unified_mode true

# Resource:: to create a Python virtual environment for a given user

property :python_version, String
property :prefix, String
property :user_only, [true, false], default: false
property :user, String

default_action :run

action :run do
  python_version = new_resource.python_version || node['cluster']['python-version']

  if new_resource.user_only
    raise "user property is required for resource install_pyenv when user_only is set to true" unless new_resource.user

    pyenv_install 'user' do
      user new_resource.user
      prefix new_resource.prefix if new_resource.prefix
    end
  else
    prefix = new_resource.prefix || node['cluster']['system_pyenv_root']

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

    bash "install python #{python_version}" do
      user 'root'
      group 'root'
      cwd "#{prefix}"
      code <<-VENV
      set -e
      cd Python-#{python_version}
      ./configure --prefix=#{prefix}/versions/#{python_version}
      make
      make install
      VENV
    end

  end

end
