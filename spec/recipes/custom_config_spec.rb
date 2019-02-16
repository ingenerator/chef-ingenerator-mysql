require 'spec_helper'

describe 'ingenerator-mysql::custom_config' do
  let (:chef_run) { ChefSpec::SoloRunner.new }

  context 'with invalid custom configuration attributes' do
    it 'raises error if the node still defines old-style tunable attributes' do
      chef_run.node.normal['mysql']['tunable']['someconfig']
      expect do
        chef_run.converge described_recipe
      end.to raise_error(Ingenerator::Helpers::Attributes::LegacyAttributeDefinitionError)
    end

    it 'raises error if the node still defines bind_address as custom_config attributes' do
      chef_run.node.normal['mysql']['custom_config']['bind_address'] = '0.0.0.0'
      expect do
        chef_run.converge described_recipe
      end.to raise_error(Ingenerator::Helpers::Attributes::LegacyAttributeDefinitionError)
    end

    it 'throws if a custom_config.default-time-zone attribute value is still defined' do
      chef_run.node.normal['mysql']['custom_config']['default-time-zone'] = 'Europe/London'
      expect { chef_run.converge described_recipe }.to raise_error(Ingenerator::Helpers::Attributes::LegacyAttributeDefinitionError)
    end
  end
end
