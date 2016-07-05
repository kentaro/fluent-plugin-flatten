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

  def create_driver(conf = DEFAULT_CONFIG, tag = 'test')
    Fluent::Test::OutputTestDriver.new(Fluent::FlattenOutput, tag).configure(conf)
  end

  def test_configure
    # when `inner_key` option is not set
    d1 = create_driver

    assert_equal 'foo',                d1.instance.key
    assert_equal 'flattened.',         d1.instance.add_tag_prefix
    assert_equal /^test\./,            d1.instance.remove_tag_prefix
    assert_equal 'value',              d1.instance.inner_key          # default value

    # when `inner_key` is set
    d2 = create_driver(%[
      key               foo
      add_tag_prefix    flattened.
      remove_tag_prefix test.
      inner_key         value_for_flat_key
    ])

    assert_equal 'foo',                d2.instance.key
    assert_equal 'flattened.',         d2.instance.add_tag_prefix
    assert_equal /^test\./,            d2.instance.remove_tag_prefix
    assert_equal 'value_for_flat_key', d2.instance.inner_key

    # when `parse_json` is false
    d3 = create_driver(%[
      key               foo
      add_tag_prefix    flattened.
      remove_tag_prefix test.
      inner_key         value_for_flat_key
      parse_json        false
    ])

    assert_equal 'foo',                d3.instance.key
    assert_equal 'flattened.',         d3.instance.add_tag_prefix
    assert_equal /^test\./,            d3.instance.remove_tag_prefix
    assert_equal 'value_for_flat_key', d3.instance.inner_key
    assert_equal false,         d3.instance.parse_json

    # when mandatory keys not set
    assert_raise(Fluent::ConfigError) do
      create_driver(%[
        key        foo
        inner_key  value_for_keypath
      ])
    end
  end

  def test_flatten
    d = create_driver

    flattened = d.instance.flatten({ 'foo' => '{"bar" : "baz"}', 'hoge' => 'fuga' })
    assert_equal({ 'foo.bar' => { 'value' => 'baz' } }, flattened)

    # XXX work-around
    # fluentd seems to escape json value excessively
    flattened = d.instance.flatten({ 'foo' => '{\"bar\" : \"baz\"}' })
    assert_equal({ 'foo.bar' => { 'value' => 'baz' } }, flattened)

    # when empty value is passed
    flattened = d.instance.flatten({ 'foo' => '' })
    assert_equal({}, flattened)

    # when invalid json value is passed
    flattened = d.instance.flatten({ 'foo' => '-' })
    assert_equal({}, flattened)
  end

  def test_emit
    # test1 default config
    d1 = create_driver

    d1.run do
      d1.emit( 'foo' => '{"bar" : "baz"}', 'hoge' => 'fuga' )
      d1.emit( 'foo' => '{"bar" : {"qux" : "quux", "hoe" : "poe" }, "baz" : "bazz" }', 'hoge' => 'fuga' )
    end
    emits1 = d1.emits

    assert_equal 4, emits1.count

    # ["flattened.foo.bar", 1354689632, {"value"=>"baz"}]
    assert_equal     'flattened.foo.bar', emits1[0][0]
    assert_equal                   'baz', emits1[0][2]['value']

    # ["flattened.foo.bar.qux", 1354689632, {"value"=>"quux"}]
    assert_equal 'flattened.foo.bar.qux', emits1[1][0]
    assert_equal                  'quux', emits1[1][2]['value']

    # ["flattened.foo.bar.hoe", 1354689632, {"value"=>"poe"}]
    assert_equal 'flattened.foo.bar.hoe', emits1[2][0]
    assert_equal                   'poe', emits1[2][2]['value']

    # ["flattened.foo.bar.baz", 1354689632, {"value"=>"bazz"}]
    assert_equal     'flattened.foo.baz', emits1[3][0]
    assert_equal                  'bazz', emits1[3][2]['value']

    # test2 parse_json is set false 
    d2 = create_driver(%[
      key                  foo 
      add_tag_prefix       flattened.
      remove_tag_prefix    test.
      parse_json           false
      replace_space_in_tag _
    ])

    d2.run do
      d2.emit( 'foo' => {'bar' => 'baz'}, 'hoge' => 'fuga' )
      d2.emit( 'foo' => {'bar' => {'qux' => 'quux', 'hoe' => 'poe' }, 'baz' => 'bazz' }, 'hoge' => 'fuga' )
      d2.emit( 'foo' => {'bar hoge' => 'baz', 'hoe baz' => 'poe'}, 'hoge' => 'fuga' )
    end
    emits2 = d2.emits

    assert_equal 6, emits2.count

    # ["flattened.foo.bar", 1354689632, {"value"=>"baz"}]
    assert_equal          'flattened.foo.bar', emits2[0][0]
    assert_equal                        'baz', emits2[0][2]['value']

    # ["flattened.foo.bar.qux_qux", 1354689632, {"value"=>"quux"}]
    assert_equal      'flattened.foo.bar.qux', emits2[1][0]
    assert_equal                       'quux', emits2[1][2]['value']

    # ["flattened.foo.bar.hoe", 1354689632, {"value"=>"poe"}]
    assert_equal      'flattened.foo.bar.hoe', emits2[2][0]
    assert_equal                        'poe', emits2[2][2]['value']

    # ["flattened.foo.bar.baz", 1354689632, {"value"=>"bazz"}]
    assert_equal          'flattened.foo.baz', emits2[3][0]
    assert_equal                       'bazz', emits2[3][2]['value']

    # ["flattened.foo.bar_hoge", 1354689632, {"value"=>"baz"}]
    assert_equal     'flattened.foo.bar_hoge', emits2[4][0]
    assert_equal                        'baz', emits2[4][2]['value']

    # ["flattened.foo.hoe_baz", 1354689632, {"value"=>"baz"}]
    assert_equal      'flattened.foo.hoe_baz', emits2[5][0]
    assert_equal                        'poe', emits2[5][2]['value']
  end
end
