# Provisions database users and config files for local admins based on node attributes
#
# Often you'll want to define any system login users very early in the chef run
# to be sure they can access even if initial provisioning fails. However this is
# too early to define database users as mysql won't be installed.
#
# So instead you can optionally define those users as node attributes and trigger
# this recipe to provision them into the node.
#
# Note also by default this recipe provisions a `vagrant` rooty user on a
# :localdev box - disable this in the attributes if required.
#
# You have to explicitly include this recipe if you want it to be used.
(node['mysql']['local_admins'] || []).each do |username, user_options|
  # Only provision if they have ['create'] = true
  next unless user_options['create']

  mysql_local_admin username do
    default_database (user_options['default_database'] || node['project']['services']['db']['schema'])
    privileges user_options['privileges'] if user_options['privileges']
  end
end
