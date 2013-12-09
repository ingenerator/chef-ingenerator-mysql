name 'ingenerator-mysql'
maintainer 'Andrew Coulton'
maintainer_email 'andrew@ingenerator.com'
license 'Apache 2.0'
description 'Standard mySQL installation for our applications, including relevant PHP and application config'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

%w(ubuntu).each do |os|
  supports os
end
