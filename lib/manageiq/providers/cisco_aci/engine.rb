module ManageIQ
  module Providers
    module CiscoAci
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::CiscoAci

        config.autoload_paths << root.join('lib').to_s

        initializer :append_secrets do |app|
          app.config.paths["config/secrets"] << root.join("config", "secrets.defaults.yml").to_s
          app.config.paths["config/secrets"] << root.join("config", "secrets.yml").to_s
        end

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Cisco Aci Provider')
        end

        def self.init_loggers
          $cisco_aci_log ||= Vmdb::Loggers.create_logger("cisco_aci.log")
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $cisco_aci_log, :level_cisco_aci)
        end
      end
    end
  end
end
