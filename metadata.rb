name 'ingenerator-mysql'
maintainer 'Andrew Coulton'
maintainer_email 'andrew@ingenerator.com'
license 'Apache 2.0'
description 'Standard mySQL installation for our applications, including relevant PHP and application config'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url 'https://github.com/ingenerator/chef-ingenerator-mysql/issues'
source_url 'https://github.com/ingenerator/chef-ingenerator-mysql'
version '0.1.0'

%w(ubuntu).each do |os|
  supports os
end

depends "apt", "~> 2.4"
depends 'database', '~> 2.3.1'
depends "mysql", "~> 5.3"
