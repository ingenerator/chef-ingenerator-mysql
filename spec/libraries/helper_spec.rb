require 'spec_helper'
require_relative '../../libraries/helper.rb'

describe Chef::Recipe::IngeneratorMysqlHelper do

  describe '#root_connection_details' do    
    context 'when no root password is configured' do
      let (:node) { {} }
      
      it 'raises an exception' do
        expect {
          Chef::Recipe::IngeneratorMysqlHelper.root_connection(node)
        }.to raise_exception(ArgumentError)
      end
      
    end
    
    context 'when root password is configured' do
      let (:node) { {'mysql' => {'server_root_password' => 'foo'}} }

      it 'provides hash with connection details' do
        expect(Chef::Recipe::IngeneratorMysqlHelper.root_connection(node)).to eq({
          :host => '127.0.0.1',
          :username => 'root',
          :password => 'foo'
        })        
      end
    end
  end

end