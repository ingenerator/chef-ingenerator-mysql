require 'spec_helper'

describe_resource 'resources::user_mysql_config' do
  let (:resource) { 'user_mysql_config' }

  describe 'create' do
    context 'with invalid options' do
      let (:node_attributes) do
        { test: { filepath: '/foo/bad.cnf' } }
      end

      it 'raises a validation exception if no connection' do
        chef_runner.node.normal['test']['no_connection'] = true
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /connection is required/)
      end

      it 'raises a validation exception if connection has no password' do
        chef_runner.node.normal['test']['my_user'] = 'jimmy'
        chef_runner.node.normal['test']['my_password'] = nil
        chef_runner.node.normal['test']['my_host'] = '127.0.0.1'
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /connection.password is required/)
      end

      it 'raises a validation exception if connection has no username' do
        chef_runner.node.normal['test']['my_user'] = nil
        chef_runner.node.normal['test']['my_password'] = 'silly'
        chef_runner.node.normal['test']['my_host'] = '127.0.0.1'
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /connection.username is required/)
      end

      it 'raises a validation exception if connection has no host' do
        chef_runner.node.normal['test']['my_user'] = 'nobody'
        chef_runner.node.normal['test']['my_password'] = 'silly'
        chef_runner.node.normal['test']['my_host'] = nil
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /connection.host is required/)
      end
    end

    context 'with valid options' do
      let (:test_file) { '/root/.my.cnf' }
      let (:test_user) { nil }
      let (:test_mode) { nil }
      let (:test_my_user) { 'penguin' }
      let (:test_my_password) { 'boulders' }
      let (:test_my_host) { '127.0.0.1' }
      let (:test_my_db) { nil }
      let (:test_safe_updates) { nil }
      let (:test_default_charset) { nil }

      let (:node_attributes) do
        cfg = {
          test: {
            filepath: test_file,
            user: test_user,
            mode: test_mode,
            my_user: test_my_user,
            my_password: test_my_password,
            my_host: test_my_host,
            my_db: test_my_db
          }
        }

        cfg[:test][:safe_updates] = test_safe_updates unless test_safe_updates.nil?
        cfg[:test][:default_charset] = test_default_charset unless test_default_charset.nil?
        cfg
      end

      context 'by default' do
        it 'creates a private config file owned by root' do
          expect(chef_run).to create_file(test_file).with(
            user: 'root',
            mode: 0o600
          )
        end
      end
      context 'with custom ownership options' do
        let (:test_user) { 'oh_jonny' }
        let (:test_mode) { 0o755 }

        it 'it creates the file with specified permissions' do
          expect(chef_run).to create_file(test_file).with(
            user: 'oh_jonny',
            mode: 0o755
          )
        end
      end

      it 'renders mysql client config with host and credentials' do
        expect(chef_run).to render_file(test_file).with_content(
          "# Provisioned by chef - do not edit locally\n" \
          "[client]\n" \
          "user='penguin'\n" \
          "password='boulders'\n" \
          "host='127.0.0.1'\n"
        )
      end

      context 'with secure password' do
        let (:test_my_password) { "my#'pass" }

        it 'escapes and properly quotes the password' do
          expect(chef_run).to render_config_line('/root/.my.cnf', "password='my#\\'pass'")
        end
      end

      context 'when set to enforce safe updates' do
        let (:test_safe_updates) { true }

        it 'configures safe updates' do
          expect(chef_run).to render_config_line('/root/.my.cnf', 'safe-updates=1')
        end
      end

      context 'when a default character set is configured' do
        let (:test_default_charset) { 'utf16' }

        it 'configures the default character set' do
          expect(chef_run).to render_config_line('/root/.my.cnf', "default-character-set='utf16'")
        end
      end

      context 'when a default database is configured' do
        let (:test_my_db) { 'peoples' }

        it 'configures the default database' do
          expect(chef_run).to render_config_line('/root/.my.cnf', "database='peoples'")
        end
      end
    end
    def render_config_line(file, line)
      pattern = Regexp.new("\n" + Regexp.quote(line) + "\n")
      render_file(file).with_content(pattern)
    end
  end
end
