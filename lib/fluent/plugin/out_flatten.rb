require 'json'

module Fluent
  class FlattenOutput < Output
    include Fluent::HandleTagNameMixin
    class Error < StandardError; end
    Fluent::Plugin.register_output('flatten', self)

    config_param :key, :string

    def configure(conf)
      super

      if !self.remove_tag_prefix && !self.remove_tag_suffix && !self.add_tag_prefix && !self.add_tag_suffix
        raise ConfigError, "out_flatten: Set remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix."
      end
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        _tag      = tag.clone
        flattened = flatten(record)
        filter_record(_tag, time, flattened)
        if tag != _tag
          Engine.emit(_tag, time, flattened)
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
