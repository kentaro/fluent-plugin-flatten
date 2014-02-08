# fluent-plugin-flatten, a plugin for [Fluentd](http://fluentd.org)

## Component

### FlattenOutput

Fluentd plugin to extract values for nested key paths and re-emit them as flat tag/record pairs.

## Synopsis

Imagin you have a config as below:

```
<match test.**>
  type flatten

  key  foo
  add_tag_prefix    flattened.
  remove_tag_prefix test.
  inner_key         value_for_flat_key
</match>
```

And you feed such a value into fluentd:

```
"test" => {
  "foo"  => '{"bar" : {"qux" : "quux", "hoe" : "poe" }, "baz" : "bazz" }',
  "hoge" => "fuga"
}
```

Then you'll get re-emmited tag/record-s below:

```
"flattened.foo.bar.qux" => { "value_for_flat_key" => "quux" }
"flattened.foo.bar.hoe" => { "value_for_flat_key" => "poe"  }
"flattened.foo.baz"     => { "value_for_flat_key" => "bazz" }
```

That is to say:

  1. The JSON-formatted string in the value related to the key `foo` is inflated to a `Hash`.
  2. The values are extracted as to be related to the nested key paths (`foo.bar.baz`).
  3. This plugin re-emits them as new tag/record pairs.
  4. Key/value pairs whose keys don't match `foo` are ignored (`"hoge" => "fuga"`).

## Configuration

### key

The `key` is used to point a key whose value contains JSON-formatted
string.

### remove_tag_prefix, remove_tag_suffix, add_tag_prefix, add_tag_suffix

These params are included from `Fluent::HandleTagNameMixin`. See that code for details.

You must add at least one of these params.

### inner_key

This plugin sets `value` for this option as a default if it's not set.

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-flatten'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-flatten

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

### Copyright

Copyright (c) 2012- Kentaro Kuribayashi (@kentaro)

### License

Apache License, Version 2.0
