require 'json'

module Fluent::Plugin
  class FlattenOutput < Fluent::Plugin::Output
    include Fluent::HandleTagNameMixin
    class Error < StandardError; end

    Fluent::Plugin.register_output('flatten', self)

    helpers :event_emitter

    desc "The key is used to point a key whose value contains JSON-formatted string."
    config_param :key, :string
    desc "This plugin sets `value` for this option as a default if it's not set."
    config_param :inner_key, :string, default: 'value'
    desc "Parse json record."
    config_param :parse_json, :bool, default: true
    desc "Replaces spaces in the resulting tag with the key passed"
    config_param :replace_space_in_tag, :string, default: nil

    def configure(conf)
      super

      if (
          !remove_tag_prefix &&
          !remove_tag_suffix &&
          !add_tag_prefix    &&
          !add_tag_suffix
      )
        raise Fluent::ConfigError, "out_flatten: At least one of remove_tag_prefix/remove_tag_suffix/add_tag_prefix/add_tag_suffix is required to be set"
      end
    end

    def multi_workers_ready?
      true
    end

    def process(tag, es)
      es.each do |time, record|
        flattened = flatten(record)

        flattened.each do |keypath, value|
          tag_with_keypath = [tag.clone, keypath].join('.')
          filter_record(tag_with_keypath, time, value)
          if @replace_space_in_tag
            router.emit(tag_with_keypath.gsub(/\s+/, @replace_space_in_tag), time, value)
          else
            router.emit(tag_with_keypath, time, value)
          end
        end
      end
    end

    def flatten(record)
      flattened = {}

      if record.has_key?(key) && !record[key].empty?
        hash = nil

        begin
          if parse_json
            # XXX work-around
            # fluentd seems to escape json value excessively
            json = record[key].gsub(/\\"/, '"')
            hash = JSON.parse(json)
          else
            hash = record[key]
          end
        rescue JSON::ParserError
          return flattened
        end

        processor = lambda do |root, hash|
          flattened = {}
          return flattened unless hash.is_a?(Hash)

          hash.each do |path, value|
            keypath = [root, path].join('.')

            if value.is_a?(Hash)
              flattened = flattened.merge(processor.call(keypath, value))
            else
              flattened[keypath] = { inner_key => value }
            end
          end

          flattened
        end

        flattened  = processor.call(key, hash)
      end

      flattened
    end
  end
end
