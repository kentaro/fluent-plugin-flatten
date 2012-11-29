require 'test_helper'

class FlattenOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    key foo
    add_tag_prefix flattened.
  ]

  def create_driver(conf = CONFIG, tag = 'test')
    Fluent::Test::OutputTestDriver.new(Fluent::FlattenOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'foo', d.instance.key
    assert_equal 'flattened.', d.instance.add_tag_prefix
  end

  def test_emit
    d = create_driver

    d.run do
      d.emit( 'foo' => '{"bar" : "baz"}', 'hoge' => 'fuga' )
      d.emit( 'foo' => '{"bar" : {"qux" : "quux", "hoe" : "poe" }, "baz" : "bazz" }', 'hoge' => 'fuga' )
    end
    emits = d.emits

    assert_equal      3, emits[0][2].count
    assert_equal  'baz', emits[0][2]['foo.bar']

    assert_equal      5, emits[1][2].count
    assert_equal 'quux', emits[1][2]['foo.bar.qux']
    assert_equal  'poe', emits[1][2]['foo.bar.hoe']
    assert_equal 'bazz', emits[1][2]['foo.baz']

    assert_equal 'flattened.test', emits[0][0]
    assert_equal 'flattened.test', emits[1][0]
  end
end
