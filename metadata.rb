name 'ingenerator-mysql'
maintainer 'Andrew Coulton'
maintainer_email 'andrew@ingenerator.com'
license 'Apache-2.0'
chef_version '>=13.12.1'
description 'Standard mySQL installation for our applications, including relevant PHP and application config'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url 'https://github.com/ingenerator/chef-ingenerator-mysql/issues'
source_url 'https://github.com/ingenerator/chef-ingenerator-mysql'
version '0.6.0'

%w(ubuntu).each do |os|
  supports os
end

depends 'apt', '~> 6.0'
depends 'database', '~> 6.0'
depends 'ingenerator-helpers', '~> 1.0'

# Not really, but database requires postgres and newer postgres doesn't support older chef
depends 'postgresql', '~> 6.1'
# Not really, but postgresql requires build-essential and build-essential requires seven_zip and that requires new chef :(
depends 'seven_zip', '~> 3.0'
