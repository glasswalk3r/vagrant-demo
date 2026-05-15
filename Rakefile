# frozen_string_literal: true

desc 'Update Choria modules'
task :update do
  module_path = File.expand_path('environments/production/modules')

  modules = [
    'choria/choria',
    'choria/mcollective_data_sysctl',
    'choria/mcollective_agent_shell',
    'choria/mcollective_agent_process',
    'choria/mcollective_agent_nettest',
    'choria/mcollective_agent_bolt_tasks',
    'choria/mcollective_data_sysctl',
    'puppetlabs/apply',
    'puppetlabs/package',
    'herculesteam/augeasproviders_core',
    'camptocamp/augeas',
    'puppetlabs/puppetdb',
    'camptocamp/systemd',
    'puppet/archive',
    'puppet/prometheus',
    'theforeman/puppet',
    'puppetlabs/puppet_authorization'
  ]

  rm_rf module_path
  mkdir_p module_path

  sh "puppet module install --modulepath #{module_path} puppetlabs/concat --version 7.3.3"

  modules.each do |mod|
    sh "puppet module install --modulepath #{module_path} #{mod}"
  end
end
