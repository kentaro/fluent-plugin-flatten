require 'json'

module Fluent
  class FlattenOutput < Output
    class Error < StandardError; end

    Fluent::Plugin.register_output('flatten', self)

    include Fluent::HandleTagNameMixin
    config_param :key, :string

    def configure(conf)
      super

      if !@remove_tag_prefix and !@remove_tag_suffix and !@add_tag_prefix and !@add_tag_suffix
        raise ConfigError, "out_flatten: Set remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix."
      end
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        _tag    = tag.clone
        flatten = flatten(record)
        filter_record(_tag, time, flatten)
        if tag != _tag
          Engine.emit(tag, time, flatten)
        else
          $log.warn "Drop record #{record} tag '#{tag}' was not replaced. Can't emit record, cause infinity looping. Set remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix correctly."
        end
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
