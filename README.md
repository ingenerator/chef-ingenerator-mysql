inGenerator MySQL cookbook
=================================
[![Build Status](https://travis-ci.org/ingenerator/chef-ingenerator-mysql.png?branch=0.x)](https://travis-ci.org/ingenerator/chef-ingenerator-mysql)

The `ingenerator-mysql` cookbook supports standard installation of mySQL for our applications
that use it, and also defines attributes and recipes that support applications that depend on
it. For example, if used with our `ingenerator-php` cookbook, the php mysql extension will be
installed as part of the php install.

Requirements
------------
- Chef 12.18 or higher
- **Ruby 2.3 or higher**

Installation
------------
We recommend adding to your `Berksfile` and using [Berkshelf](http://berkshelf.com/):

```ruby
source 'https://chef-supermarket.ingenerator.com'
cookbook 'ingenerator-mysql', '~>0.4.0'
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
the standard `ingenerator-mysql::server` recipe above). It provisions an `application_database`
resource for the default primary schema defined in `node['project']['services']['db']['schema']`.

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

## `ingenerator-mysql::local_admins`

This recipe is not included by default. If included it will generate a `mysql_local_admin` for
each user defined in the `node['mysql']['local_admins']` hash of `username => options`.
Users are only created if they have a `create` attribute set to true. Use this when you
want to define system users before mysql is installed but keep their access definition
in one place.

If run in the `:localdev` environment then by default this will also create a user with
root privileges for the `vagrant` local system user.

For example:

```ruby
# your/project/cookbook/recipes/users.rb
user 'phil'
sudo 'phil'

node.default['mysql']['local_admins']['phil']['create'] = true
# Optionally, you can also set a custom default_database and privileges in these
# attributes.

# And then add ingenerator-mysql::local_admins to your runlist somewhere after
# mysql is installed and configured.
```


Attributes
----------

The cookbook provides and is controlled by a number of default attributes:

* [default](attributes/default.rb) - customisation of mysql config and generic mysql attributes
* [app_db](attributes/app_db.rb) - attributes related to the application database, including tweaks to related cookbooks


Resources
---------

### application_database

This resource will:

* create a schema for the application to use
* create / update a restricted-privilege database user for use by general
  application code - named with the project name by default
* optionally, if the database is empty, seed it from a file in /tmp/database-seeds/{schema.sql}

If a database seed file is provided, it will be piped to the schema and then
deleted. If it is present on a subsequent run and the database is not empty,
an exception will be thrown and provisioning aborted.

The resouce currently has limited direct options, most behaviour is governed by the
`node['project']['services']['db']` attributes.

The application database user, by default, can only connect from localhost but
you can configure this by setting the
`node['project']['services']['db']['connect_anywhere']` attribute to true. It
has limited permissions which can be customised by setting the appropriate key
in `node['project']['services']['db']['privileges'][{mysql permission name}]`
to true.

> **Security Considerations!**
> Granting granting elevated privileges to a user that runs in the context of a web
> application is a likely security hole. Before activating additional privileges for
> the application user you should consider whether you can either use a separate
> database user (for example, for command line admin tasks that run outside the web
> context) or implement a message queue or similar so that the web process can only
> trigger a set of whitelisted application use cases which are executed by a
> privileged user in a separate process.

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

### mysql_local_admin

Provisions a database user for a system user, and drops a `.my.cnf` in the user's
home directory. By default users can do most data manipulation but not modify the
schema. You can customise the privileges by passing your own array to the resource.

The user password will come from:

* A `password` option passed to the resource
* A `node['mysql']['local_admins'][username]['password']` attribute
* A random secure password that will be persisted into the above node attribute
  for reuse.

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
