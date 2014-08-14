require 'spec_helper'

describe 'ingenerator-mysql::custom_config' do
  let (:chef_run) { ChefSpec::Runner.new }
  
  it "installs the custom config file" do
    expect(chef_run.converge(described_recipe)).to create_template('/etc/mysql/conf.d/custom.cnf').with(
      mode:  0600,
      owner: 'mysql',
      group: 'mysql'      
    )
  end
  
  it "renders each custom attribute to the config file" do
    chef_run.node.set['mysql']['custom_config'] = {
      :custom_var => 'value'
    }
    chef_run.converge(described_recipe)
    
    expect(chef_run).to render_file('/etc/mysql/conf.d/custom.cnf')
       .with_content(/(^|\n)\[mysqld\][^\[]*?\ncustom_var=value\n/)
  end
  
  it "sorts custom attributes to prevent unexpected file changes" do
    chef_run.node.set['mysql']['custom_config'] = {
      :other_var   => 5,
      :custom_var => 'value'
    }
    chef_run.converge(described_recipe)

    expect(chef_run).to render_file('/etc/mysql/conf.d/custom.cnf')
       .with_content(/(^|\n)\[mysqld\][^\[]*?\ncustom_var=value\n[^\[]*?\n?other_var=5\n/)
  end
  
  it "skips config attributes where the option is nil" do
    chef_run.node.set['mysql']['custom_config']['nilvar'] = nil
    chef_run.converge(described_recipe)

    expect(chef_run).to_not render_file('/etc/mysql/conf.d/custom.cnf')
       .with_content(/nilvar/)
  end
  
  it "triggers restart on the mysql service if the config file changes" do
    chef_run.converge described_recipe
    template = chef_run.template('/etc/mysql/conf.d/custom.cnf')
    expect(template).to notify('service[mysql]').to(:restart)    
  end
  
  it "raises error if the node still defines old-style tunable attributes" do
    chef_run.node.set['mysql']['tunable']['someconfig']
    expect { 
      chef_run.converge described_recipe 
    }.to raise_error(ArgumentError)
  end

  it "raises error if the node still defines old-style bind_address attributes" do
    chef_run.node.set['mysql']['bind_address'] = '0.0.0.0'
    expect { 
      chef_run.converge described_recipe 
    }.to raise_error(ArgumentError)
  end

end
