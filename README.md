# fluent-plugin-flatten

## Component

### FlattenOutput

Fluentd output plugin to flatten JSON-formatted string values in records to top level key/value-s.

## Synopsis

When you have a config as below:

```
<match test.**>
  type flatten
  key  foo
</match>
```

And you feed such a value into fluentd:

```
{
  "foo"  => '{"bar" : {"qux" : "quux", "hoe" : "poe" }, "baz" : "bazz" }',
  "hoge" => "fuga"
}
```

Then you'll get:

```
{
  "foo"  => '{"bar" : {"qux" : "quux", "hoe" : "poe" }, "baz" : "bazz" }',
  "hoge" => "fuga",

  "foo.bar.qux" => "quux",
  "foo.bar.hoe" => "poe",
  "foo.baz"     => "bazz"
}
```

That is, JSON-formatted string in the value of the key `foo` is flattened and now put into the top level of the hash.

## Configuration

### key

The `key` is used to point a key whose value contains JSON-formatted
string.

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
