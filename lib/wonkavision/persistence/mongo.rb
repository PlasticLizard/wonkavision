# encoding: UTF-8
# Taken almost verbatim from https://github.com/jnunemaker/mongomapper/blob/master/lib/mongo_mapper/connection.rb
require 'uri'
require 'mongo'

module Wonkavision
  module Mongo

    class << self

      # @api public
      def connection
        @@connection ||= ::Mongo::Connection.new
      end

      # @api public
      def connection=(new_connection)
        @@connection = new_connection
      end

      # @api public
      def logger
        connection.logger
      end

      # @api public
      def database=(name)
        @@database = nil
        @@database_name = name
      end

      # @api public
      def database
        if @@database_name.blank?
          raise 'You forgot to set the default database name: database = "foobar"'
        end

        @@database ||= connection.db(@@database_name)
      end

      def config=(hash)
        @@config = hash
      end

      def config
        raise 'Set config before connecting. config = {...}' unless defined?(@@config)
        @@config
      end

      # @api private
      def config_for_environment(environment)
        env = config[environment]
        return env if env['uri'].blank?

        uri = URI.parse(env['uri'])
        raise InvalidScheme.new('must be mongodb') unless uri.scheme == 'mongodb'
        {
          'host'     => uri.host,
          'port'     => uri.port,
          'database' => uri.path.gsub(/^\//, ''),
          'username' => uri.user,
          'password' => uri.password,
        }
      end

      def connect(environment, options={})
        raise 'Set config before connecting. config = {...}' if config.blank?
        env = config_for_environment(environment)
        self.connection = ::Mongo::Connection.new(env['host'], env['port'], options)
        self.database = env['database']
        database.authenticate(env['username'], env['password']) if env['username'] && env['password']
      end

      def setup(config, environment, options={})
        handle_passenger_forking
        self.config = config
        connect(environment, options)
      end

      def handle_passenger_forking
        if defined?(PhusionPassenger)
          PhusionPassenger.on_event(:starting_worker_process) do |forked|
            connection.connect if forked
          end
        end
      end

    end

  end
end
