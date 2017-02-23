require 'spec_helper'

describe 'ingenerator-mysql::custom_config' do
  let (:chef_run) { ChefSpec::SoloRunner.new }

  context 'by default' do
    it 'configures the default timezone to Europe/London and immediately restarts mysql' do
      expect(chef_run.converge(described_recipe)).to configure_mysql_default_timezone('Europe/London').with(
        credential_file: '/root/.my.cnf'
      )

      expect(chef_run.mysql_default_timezone('Europe/London')).to notify('mysql_service[default]').to(:restart).immediately
    end
  end

  context 'with no custom config attributes' do
    it 'provisions a custom config resource with no options' do
      # This is important, so that if the last custom_config option is removed the file actually gets removed
      chef_run.node.override['mysql']['custom_config'] = {}
      expect(chef_run.converge(described_recipe)).to create_mysql_config('custom').with(instance: 'default',
                                                                                        source: 'custom.cnf.erb',
                                                                                        variables: { options: [] })
    end
  end

  context 'with valid configuration attributes' do
    it 'provisions a custom config resource for the default mysql server' do
      expect(chef_run.converge(described_recipe)).to create_mysql_config('custom').with(instance: 'default',
                                                                                        source: 'custom.cnf.erb')
    end

    it 'sorts custom attributes to prevent unexpected file changes and passes them to the config resource' do
      chef_run.node.normal['mysql']['custom_config'] = {
        other_var: 5,
        custom_var: 'value'
      }
      expect(chef_run.converge(described_recipe)).to create_mysql_config('custom').with(variables: {
                                                                                          options: [
                                                                                            { key: 'custom_var', value: 'value' },
                                                                                            { key: 'other_var', value: 5 }
                                                                                          ]
                                                                                        })
    end

    it 'skips attributes with value set to nil' do
      chef_run.node.normal['mysql']['custom_config'] = {
        other_var: 5,
        custom_var: nil
      }

      expect(chef_run.converge(described_recipe)).to create_mysql_config('custom').with(variables: {
                                                                                          options: [
                                                                                            { key: 'other_var', value: 5 }
                                                                                          ]
                                                                                        })
    end
  end

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
