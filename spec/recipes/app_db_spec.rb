require 'spec_helper'

describe 'ingenerator-mysql::app_db' do
  let (:chef_run) { ChefSpec::SoloRunner.new.converge described_recipe }

  it 'does nothing in the recipe' do
    expect(chef_run.resource_collection).to be_empty
  end

  context 'with its attributes' do
    it 'adds php7.2-mysql to the list of extensions the php cookbook should install' do
      expect(chef_run.node['php']['module_packages']['php7.2-mysql']).to be true
    end
  end
end
