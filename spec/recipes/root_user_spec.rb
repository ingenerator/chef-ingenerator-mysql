require 'spec_helper'

describe 'ingenerator-mysql::root_user' do
  let (:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  context "when running under vagrant" do
    let (:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.automatic['etc']['passwd']['vagrant'] = {}
      end.converge(described_recipe)
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
      allow(Chef::Log).to receive(:warn)
    end

    it "emits a warning if the root password is 'mysql'" do
      expect(Chef::Log).to receive(:warn).at_least(:once).with(
        'Your root db password is not secure and you are not running under vagrant - check your configuration'
      )
      chef_run.node.normal['mysql']['server_root_password'] = 'mysql'
      chef_run.converge(described_recipe)
    end
  end


end
