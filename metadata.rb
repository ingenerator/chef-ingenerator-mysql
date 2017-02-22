name 'ingenerator-mysql'
maintainer 'Andrew Coulton'
maintainer_email 'andrew@ingenerator.com'
license 'Apache 2.0'
description 'Standard mySQL installation for our applications, including relevant PHP and application config'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url 'https://github.com/ingenerator/chef-ingenerator-mysql/issues'
source_url 'https://github.com/ingenerator/chef-ingenerator-mysql'
version '0.2.0'

%w(ubuntu).each do |os|
  supports os
end

depends 'apt', '~> 6.0'
depends 'database', '~> 6.0'
depends 'ingenerator-helpers', '~> 1.0'
depends 'mysql', '~> 8.0'
depends 'mysql2_chef_gem', '~> 1.0'
