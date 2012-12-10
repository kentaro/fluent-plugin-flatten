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

    # when empty value is passed
    flattened = d.instance.flatten({ 'foo' => '' })
    assert_equal({}, flattened)

    # when invalid json value is passed
    flattened = d.instance.flatten({ 'foo' => '-' })
    assert_equal({}, flattened)
  end

  def test_emit
    d = create_driver

    d.run do
      d.emit( 'foo' => '{"bar" : "baz"}', 'hoge' => 'fuga' )
      d.emit( 'foo' => '{"bar" : {"qux" : "quux", "hoe" : "poe" }, "baz" : "bazz" }', 'hoge' => 'fuga' )
    end
    emits = d.emits

    assert_equal 4, emits.count

    # ["flattened.foo.bar", 1354689632, {"value"=>"baz"}]
    assert_equal     'flattened.foo.bar', emits[0][0]
    assert_equal                   'baz', emits[0][2]['value']

    # ["flattened.foo.bar.qux", 1354689632, {"value"=>"quux"}]
    assert_equal 'flattened.foo.bar.qux', emits[1][0]
    assert_equal                  'quux', emits[1][2]['value']

    # ["flattened.foo.bar.hoe", 1354689632, {"value"=>"poe"}]
    assert_equal 'flattened.foo.bar.hoe', emits[2][0]
    assert_equal                   'poe', emits[2][2]['value']

    # ["flattened.foo.bar.baz", 1354689632, {"value"=>"bazz"}]
    assert_equal     'flattened.foo.baz', emits[3][0]
    assert_equal                  'bazz', emits[3][2]['value']
  end
end
