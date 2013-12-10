require 'spec_helper'

describe 'ingenerator-mysql::root_user' do
  let (:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  context "when running under vagrant" do
    let (:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['vagrant'] = {}
      end.converge(described_recipe)
    end

    it "allows the root user to connect from any address" do
      chef_run.node['mysql']['allow_remote_root'].should be_true
    end

    it "does not emit a root password security warning" do
      expect(Chef::Log).not_to receive(:warn).with(
        'Your root db password is not secure and you are not running under vagrant - check your configuration'
      )
      chef_run.converge(described_recipe)
    end

  end

  context "when not under vagrant" do
    before (:each) do
      Chef::Log.stub(:warn)
    end

    it "does not allow root to connect remotely" do
      chef_run.node['mysql']['allow_remote_root'].should be_false
    end

    it "emits a warning if the root password is 'mysql'" do
      expect(Chef::Log).to receive(:warn).at_least(:once).with(
        'Your root db password is not secure and you are not running under vagrant - check your configuration'
      )
      chef_run.node.set['mysql']['server_root_password'] = 'mysql'
      chef_run.converge(described_recipe)
    end
  end


end
