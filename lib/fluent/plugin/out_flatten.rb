require 'json'

module Fluent
  class FlattenOutput < Output
    class Error < StandardError; end

    Fluent::Plugin.register_output('flatten', self)
    config_param :key, :string

    def emit(tag, es, chain)
      es.each do |time, record|
        Engine.emit(tag, time, flatten(record))
      end

      chain.next
    end

    def flatten(record)
      if record.has_key?(@key)
        hash   = JSON.parse(record[@key])
        record = record.merge(_flatten(@key, hash))
      end

      record
    end

    def _flatten(root, hash)
      unless hash.is_a?(Hash)
        raise Error.new('The value to be flattened must be a Hash: #{hash}')
      end

      flattened = {}
      hash.each do |path, value|
        key = [root, path].join('.')

        if value.is_a?(String)
          flattened[key] = value
        else
          flattened = flattened.merge(_flatten(key, value))
        end
      end

      flattened
    end
  end
end
