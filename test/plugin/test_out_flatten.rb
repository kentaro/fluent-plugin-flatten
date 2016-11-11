require 'test_helper'

class FlattenOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  DEFAULT_CONFIG = %[
    key               foo
    add_tag_prefix    flattened.
    remove_tag_prefix test.
  ]

  def create_driver(conf = DEFAULT_CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::FlattenOutput).configure(conf)
  end

  sub_test_case "configure" do
    test "when `inner_key` option is not set" do
      d = create_driver

      assert_equal 'foo',                d.instance.key
      assert_equal 'flattened.',         d.instance.add_tag_prefix
      assert_equal /^test\./,            d.instance.remove_tag_prefix
      assert_equal 'value',              d.instance.inner_key          # default value
    end

    test "when `inner_key` is set" do
      d = create_driver(%[
        key               foo
        add_tag_prefix    flattened.
        remove_tag_prefix test.
        inner_key         value_for_flat_key
      ])

      assert_equal 'foo',                d.instance.key
      assert_equal 'flattened.',         d.instance.add_tag_prefix
      assert_equal /^test\./,            d.instance.remove_tag_prefix
      assert_equal 'value_for_flat_key', d.instance.inner_key
    end

    test "when `parse_json` is false" do
      d = create_driver(%[
        key               foo
        add_tag_prefix    flattened.
        remove_tag_prefix test.
        inner_key         value_for_flat_key
        parse_json        false
      ])

      assert_equal 'foo',                d.instance.key
      assert_equal 'flattened.',         d.instance.add_tag_prefix
      assert_equal /^test\./,            d.instance.remove_tag_prefix
      assert_equal 'value_for_flat_key', d.instance.inner_key
      assert_equal false,         d.instance.parse_json
    end

    test "mandatory parameters are missing" do
      assert_raise(Fluent::ConfigError) do
        create_driver(%[
          key        foo
          inner_key  value_for_keypath
        ])
      end
    end
  end

  sub_test_case "flatten" do
    test "plain" do
      d = create_driver

      flattened = d.instance.flatten({ 'foo' => '{"bar" : "baz"}', 'hoge' => 'fuga' })
      assert_equal({ 'foo.bar' => { 'value' => 'baz' } }, flattened)
    end

    test "excessively escaped json value" do
      d = create_driver

      # XXX work-around
      # fluentd seems to escape json value excessively
      flattened = d.instance.flatten({ 'foo' => '{\"bar\" : \"baz\"}' })
      assert_equal({ 'foo.bar' => { 'value' => 'baz' } }, flattened)
    end

    test "empty" do
      d = create_driver
      flattened = d.instance.flatten({ 'foo' => '' })
      assert_equal({}, flattened)
    end

    test "invalid json" do
      d = create_driver
      flattened = d.instance.flatten({ 'foo' => '-' })
      assert_equal({}, flattened)
    end
  end

  sub_test_case "emit" do
    test "default config" do
      # test1 default config
      d = create_driver

      d.run(default_tag: "test") do
        d.feed( 'foo' => '{"bar" : "baz"}', 'hoge' => 'fuga' )
        d.feed( 'foo' => '{"bar" : {"qux" : "quux", "hoe" : "poe" }, "baz" : "bazz" }', 'hoge' => 'fuga' )
      end
      events = d.events

      assert_equal 4, events.count

      # ["flattened.foo.bar", 1354689632, {"value"=>"baz"}]
      assert_equal     'flattened.foo.bar', events[0][0]
      assert_equal                   'baz', events[0][2]['value']

      # ["flattened.foo.bar.qux", 1354689632, {"value"=>"quux"}]
      assert_equal 'flattened.foo.bar.qux', events[1][0]
      assert_equal                  'quux', events[1][2]['value']

      # ["flattened.foo.bar.hoe", 1354689632, {"value"=>"poe"}]
      assert_equal 'flattened.foo.bar.hoe', events[2][0]
      assert_equal                   'poe', events[2][2]['value']

      # ["flattened.foo.bar.baz", 1354689632, {"value"=>"bazz"}]
      assert_equal     'flattened.foo.baz', events[3][0]
      assert_equal                  'bazz', events[3][2]['value']
    end

    test "parse_json is set false" do
      d = create_driver(%[
        key                  foo
        add_tag_prefix       flattened.
        remove_tag_prefix    test.
        parse_json           false
        replace_space_in_tag _
      ])

      d.run(default_tag: "test") do
        d.feed( 'foo' => {'bar' => 'baz'}, 'hoge' => 'fuga' )
        d.feed( 'foo' => {'bar' => {'qux' => 'quux', 'hoe' => 'poe' }, 'baz' => 'bazz' }, 'hoge' => 'fuga' )
        d.feed( 'foo' => {'bar hoge' => 'baz', 'hoe baz' => 'poe'}, 'hoge' => 'fuga' )
      end
      events = d.events

      assert_equal 6, events.count

      # ["flattened.foo.bar", 1354689632, {"value"=>"baz"}]
      assert_equal          'flattened.foo.bar', events[0][0]
      assert_equal                        'baz', events[0][2]['value']

      # ["flattened.foo.bar.qux_qux", 1354689632, {"value"=>"quux"}]
      assert_equal      'flattened.foo.bar.qux', events[1][0]
      assert_equal                       'quux', events[1][2]['value']

      # ["flattened.foo.bar.hoe", 1354689632, {"value"=>"poe"}]
      assert_equal      'flattened.foo.bar.hoe', events[2][0]
      assert_equal                        'poe', events[2][2]['value']

      # ["flattened.foo.bar.baz", 1354689632, {"value"=>"bazz"}]
      assert_equal          'flattened.foo.baz', events[3][0]
      assert_equal                       'bazz', events[3][2]['value']

      # ["flattened.foo.bar_hoge", 1354689632, {"value"=>"baz"}]
      assert_equal     'flattened.foo.bar_hoge', events[4][0]
      assert_equal                        'baz', events[4][2]['value']

      # ["flattened.foo.hoe_baz", 1354689632, {"value"=>"baz"}]
      assert_equal      'flattened.foo.hoe_baz', events[5][0]
      assert_equal                        'poe', events[5][2]['value']
    end
  end
end
