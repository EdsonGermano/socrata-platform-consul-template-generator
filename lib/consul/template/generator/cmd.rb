require 'consul/template/generator'

module Consul
  module Template
    module Generator
      module CMD
        include Consul::Template::Generator

        def self.configure(consul_host, template, template_key, log_level, proxy = nil)
          Consul::Template::Generator.configure do |config|
            config.log_level = log_level
            config.template = template
            config.template_key = template_key
            config.consul_host = consul_host
          end
        end

        def self.run(cycle_sleep = nil, lock_sleep = nil)
          cycle_sleep ||= 0.5
          lock_sleep ||= 1.0
          config = Consul::Template::Generator.config
          uploaded_hash = nil
          begin
            runner = CTRunner.new
            runner.acquire_session_lock do
              config.logger.info "Session lock acquired..."
              begin
                uploaded_hash = runner.run(uploaded_hash) || uploaded_hash
                sleep cycle_sleep
              rescue Interrupt
                raise # Re-raise to break this rescue block
              rescue ConsulSessionExpired
                config.logger.error "The current consul session has expired."
                break
              rescue Exception => e
                config.logger.error "An error occurred while updating template: #{e.message}"
                config.logger.debug "Sleeping before attempting to update again..."
                sleep lock_sleep
                break
              end until false
            end
          rescue Interrupt
            config.logger.error "Received interrupt signal, exiting..."
            break
          rescue Exception => e
            config.logger.info "Unable to obtain session lock: #{e.message}"
            config.logger.debug "Sleeping before attempting lock session again..."
            begin
              sleep lock_sleep
            rescue Interrupt
              config.logger.error "Received interrupt signal, exiting..."
              break
            end
          ensure
            runner.destroy_session
          end until false
          0
        end

        def self.run_once
          config = Consul::Template::Generator.config
          begin
            runner = CTRunner.new
            result = runner.run
          rescue Exception => e
            config.logger.error "An unexpected error occurred, unable to process template: #{e.message}"
            1
          else
            0
          end 
        end 
      end
    end
  end
end
