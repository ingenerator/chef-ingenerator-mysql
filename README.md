inGenerator MySQL cookbook
=================================
[![Build Status](https://travis-ci.org/ingenerator/chef-ingenerator-mysql.png?branch=master)](https://travis-ci.org/ingenerator/chef-ingenerator-mysql)

The `ingenerator-mysql` cookbook supports standard installation of mySQL for our applications
that use it, and also defines attributes and recipes that support applications that depend on
it. For example, if used with our `ingenerator-php` cookbook, the php mysql extension will be
installed as part of the php install.

Requirements
------------
- Chef 11 or higher
- **Ruby 1.9.3 or higher**

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
* wipe and reinstate the development database if configured or if the dump files have changed

Attributes
----------

The cookbook provides and is controlled by a number of default attributes:

* [default](attributes/default.rb) - customisation of mysql config and generic mysql attributes
* [app_db](attributes/app_db.rb) - attributes related to the application database, including tweaks to related cookbooks

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
