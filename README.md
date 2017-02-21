inGenerator MySQL cookbook
=================================
[![Build Status](https://travis-ci.org/ingenerator/chef-ingenerator-mysql.png?branch=master)](https://travis-ci.org/ingenerator/chef-ingenerator-mysql)

The `ingenerator-mysql` cookbook supports standard installation of mySQL for our applications
that use it, and also defines attributes and recipes that support applications that depend on
it. For example, if used with our `ingenerator-php` cookbook, the php mysql extension will be
installed as part of the php install.

Requirements
------------
- Chef 12.13 or higher
- **Ruby 2.3 or higher**

Installation
------------
We recommend adding to your `Berksfile` and using [Berkshelf](http://berkshelf.com/):

```ruby
cookbook 'ingenerator-mysql', git: 'git://github.com/ingenerator/chef-ingenerator-mysql', branch: 'master'
```

Have your main project cookbook *depend* on ingenerator-mysql by editing the `metadata.rb` for your cookbook.

```ruby
# metadata.rb
depends 'ingenerator-mysql'
```

User passwords
--------------
> By default, the root password is set to 'mysql' and the app user password to the project name. This is valid for
> development environments (which should not have secure credentials for anything) but you **MUST** ensure you define
> secure passwords for a any production server. Generally available QA and similar hosts that could be compromised
> should also have secure passwords, different to the ones used in production.
> The recipes will emit a warning log if you deploy outside Vagrant with an insecure password.

Recipes
-------

### No default recipe
As this cookbook provides both server and client related mysql things, there is no default recipe.

### `ingenerator-mysql::server`
This recipe will:

* install a mysql server
* manage the mysql root password
* install the mysql client, ruby mysql gem and database bindings for use in chef
* provision a default mysql client options file at /root/.my.cnf with credentials for root database access
* create a schema for the application
* create a non-root user account for the application - by default only with permissions on the app schema
* if running on vagrant, bind mysql to any interface and allow remote root access so workbench etc work from the host

### `ingenerator-mysql::app_db_server`
This is intended to be run on the database server instance for an application (and is included with
the standard `ingenerator-mysql::server` recipe above). It handles two main tasks:

* create a schema for the application - named with the project name by default
* create a restricted-privilege database user for use by general application code - again with the project name by default

The application database user, by default, can only connect from localhost but you can configure this by setting the
`node['project']['services']['db']['connect_anywhere']` attribute to true. It has limited permissions which can be
customised by setting the appropriate key in `node['project']['services']['db']['privileges'][{mysql permission name}]`
to true.

> **Security Considerations!**
> Granting granting elevated privileges to a user that runs in the context of a web application is a likely security
> hole. Before activating additional privileges for the application user you should consider whether you can either
> use a separate database user (for example, for command line admin tasks that run outside the web context) or implement
> a message queue or similar so that the web process can only trigger a set of whitelisted application use cases which
> executed by a privileged user in a separate process.

### `ingenerator-mysql::dev-db`
This recipe will:

* provision a standard basic development database if missing
* run SQL files against the development database if configured or if the dump files have changed

To use it, add SQL files that take the desired action - generally, drop an entire table and recreate it - as
cookbook files in your project.

```sql
/* application-cookbook/files/default/dev_db/users.sql */
CREATE SCHEMA myapplication IF NOT EXIST;
DROP TABLE IF EXISTS users;
CREATE TABLE users /*....
```

Add each file to the `node['mysql']['dev_db']['sql_files']` hash - for example:

```ruby
node.default['mysql']['dev_db']['sql_files']['application-coobook::dev_db/users.sql'] = true
```

By default, the files will be copied to a local path on your machine in order to detect if they
have changed since the last deploy. Any changed files will be passed to mysql as root during
deployment.

You can force a reprovision by setting `node['mysql']['dev_db']['recreate_always']` to true -
for example, you'd probably do so in a build slave role to ensure the test db was always clean.

Alternatively you can force a one-off reprovision with an environment variable - eg
`$ RECREATE_DEV_DB=1 architecture/provision dev-server`.

You should consider setting the attribute from an environment variable in your Vagrantfile to
allow the same workflow on your host machine.

> **DANGER!**
> If included, this recipe will without warning run your SQL scripts, probably wiping your entire
> database. To reduce the risk you accidentally run it on a production box, it will fail if the
> root password is anything other than "mysql". It should be obvious that inclusion of this recipe
> should be treated with care.

Attributes
----------

The cookbook provides and is controlled by a number of default attributes:

* [default](attributes/default.rb) - customisation of mysql config and generic mysql attributes
* [app_db](attributes/app_db.rb) - attributes related to the application database, including tweaks to related cookbooks


Resources
---------

### user_mysql_config

Provisions a `.my.cnf` options file for the mysql client with the specified connection
details. Optionally, you can enforce safe queries, a default character set and a default
database.

```ruby
user_mysql_config '/home/me/.my.cnf' do
  user            'me'
  mode            0600
  connection      { username: 'me', password: 'secret', host: '127.0.0.1'}
  # or use node.mysql_root_connection() for the current root credentials
  database        'my-schema'

  # enforce the safe-updates mode of mysql where a PK is required to update or delete
  safe_updates    true

  default_charset 'utf8'
end
```

### mysql_default_timezone

Uses `mysql_tzinfo_to_sql` to populate mysql timezones from `/usr/share/zoneinfo`
then sets a custom configuration file for the default timezone. See the
custom_config recipe for usage details. The default timezone is Europe/London -
override this with the node.mysql.default-time-zone attribute if required.

[!!] Note that this does not schedule any future updates of the timezone data -
if you're not routinely building fresh boxes you will need to schedule this.

### Testing
See the [.travis.yml](.travis.yml) file for the current test scripts.

Contributing
------------
1. Fork the project
2. Create a feature branch corresponding to your change
3. Create specs for your change
4. Create your changes
4. Create a Pull Request on github

License & Authors
-----------------
- Author:: Andrew Coulton (andrew@ingenerator.com)

```text
Copyright 2012-2013, inGenerator Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
