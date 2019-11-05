# -*- encoding: utf-8 -*-

# @author Masa Sakano (Wise Babel Ltd)

#require 'open3'
require 'sub_object'
require 'sub_object/sub_array'

$stdout.sync=true
$stderr.sync=true
# print '$LOAD_PATH=';p $LOAD_PATH

#################################################
# Unit Test
#################################################

gem "minitest"
# require 'minitest/unit'
require 'minitest/autorun'

class TestUnitSubObject < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  EXE = "%s/../bin/%s" % [File.dirname(__FILE__), File.basename(__FILE__).sub(/^test_(.+)\.rb/, '\1')]

  class MyA
  end

  class MyB
    def [](a)
    end
  end

  class MyC
    attr_reader :x
    def initialize(a)
      @x = a
    end

    def [](a, b)
      raise TypeError if a.respond_to? :to_hash
      MyC.new(@x+a+b)
    end

    def plus1
      @x+1
    end
    def to_s
      @x.to_s
    end

    def dest!
    end

    # Without this you could not compare (once it is frozen)
    def ==(other)
      @x == other.x
    end
      
    # Test of hash values
    def hash
      @x
    end
    def modify_self!
      @x = @x * 9
    end
    def reverse_self!
      @x = @x / 9
    end
  end

  def setup
  end

  def teardown
  end

  def test_sub_object01
    err = assert_raises(TypeError){ SubObject.new MyA.new, 2, 3 }
    assert_match( /\] method/, err.message )
    err = assert_raises(TypeError){ SubObject.new MyB.new, 2, 3 }
    assert_match( /type method/, err.message )
    err = assert_raises(TypeError){ SubObject.new MyC.new(8), 2, Hash.new[3] }
    assert_match( /type for/, err.message )

    myo = MyC.new(1)
    assert            myo.is_a?(MyC)
    assert_equal "1", myo.to_s
    assert_equal  2,  myo.plus1
    assert_nil        myo.dest!
    assert_equal  1,  myo.hash

    obj = SubObject.new myo, 2, 3
    assert_equal myo,           obj.source
    refute_equal myo.object_id, obj.source.object_id  # b/c the latter is frozen
    assert_equal myo.object_id, obj.instance_variable_get(:@source).object_id
    assert_equal   2,           obj.pos
    assert_equal   3,           obj.subsize
    assert_equal [2, 3],        obj.pos_size
    assert_equal MyC.new(myo.x+2+3), obj.to_source
    assert_equal "SubObject", obj.class.name
    assert_equal "6", obj.to_s
    assert            myo.respond_to?(:to_s)
    assert            obj.respond_to?(:to_s)
    assert            myo.respond_to?(:plus1)
    assert            obj.respond_to?(:plus1)
    refute            myo.respond_to?(:naiyo)
    refute            obj.respond_to?(:naiyo)
    assert_equal  7,  obj.plus1
    assert            (SubObject === obj)
    assert_instance_of(SubObject, obj)
    refute            obj.kind_of?(SubObject)
    refute            obj.is_a?(   SubObject)
    refute            (MyC       === obj)
    refute_instance_of(MyC, obj)
    assert            obj.kind_of?(MyC)
    assert            obj.is_a?(   MyC)
    err = assert_raises(NoMethodError){ obj.to_str }
    err = assert_raises(NoMethodError){ obj.dest! }

    assert_equal   1,  myo.hash
    assert_equal   1,  obj.instance_variable_get(:@hash)
    myo.modify_self!
    assert_equal   1,  obj.instance_variable_get(:@hash)
    assert_equal   9,  myo.hash
    assert_equal myo.object_id, obj.instance_variable_get(:@source).object_id
    assert_equal myo.hash, obj.instance_variable_get(:@source).hash
    assert_equal 9, obj.instance_variable_get(:@source).hash
    assert_output('', /destructively/){ obj.source }
    assert_output('', /destructively/){ obj.plus1 }
    assert_output('', /destructively/){ obj.to_s }
    ## The following is true and it is as expected,
    #  However, you do not care what it returns once the source
    #  has been destructively modified... Hence taken out of this test.
    # assert_equal "14", obj.to_s

    mutex = Mutex.new
    exclu = Thread.new {
      mutex.synchronize {
      org_verbose = $VERBOSE
      assert_output('', ''){ _ = SubObject.verbose }
      begin
        $VERBOSE = true
        assert_nil          SubObject.verbose
        SubObject.verbose=nil;
        assert_nil          SubObject.verbose
        assert_output('', /destructively/){ obj.source }
        $VERBOSE = false
        assert_output('', /destructively/){ obj.source }
        $VERBOSE = nil
        assert_output('', ''){ obj.source }

        SubObject.verbose = true
        assert_equal true,  SubObject.verbose
        assert_equal true,  SubObject.instance_variable_get(:@verbosity)
        assert_output('', /destructively/){ obj.source }
        SubObject.verbose = false
        assert_equal false, SubObject.verbose
        assert_output('', ''){ obj.source }
        $VERBOSE = true
        assert_output('', ''){ obj.source }
        SubObject.verbose=nil;
        assert_output('', /destructively/){ obj.source }

        # Original String recovered, hence its hash value.
        myo.reverse_self!
        assert_output('', ''){ obj.source }
      ensure
        $VERBOSE = org_verbose
        SubObject.verbose=nil;
      end
      }
    }
    exclu.join
  end

  def test_sub_array01
    assert_raises(TypeError){ SubObject::SubArray.new "bad", -3, 2 }

    ary = [2,4,6,8,10]
    obj = SubObject::SubArray.new ary, -3, 2
    assert_equal( -3,           obj.pos)
    assert_equal   2,           obj.subsize
    assert_equal [-3, 2],       obj.pos_size
    assert_equal ary[-3, 2],    obj.to_source
    assert_equal :to_ary, SubObject::SubArray::TO_SOURCE_METHOD
    assert_equal :itself, SubObject::TO_SOURCE_METHOD
    assert_raises(TypeError){ SubObject::SubArray.new ary, -3, :a }
    assert            (SubObject === obj)
    assert            (SubObject::SubArray === obj)
    assert            obj.instance_of?(SubObject::SubArray)
    refute            obj.instance_of?(SubObject)
    refute            obj.kind_of?(SubObject)
    refute            obj.is_a?(   SubObject)
    refute            obj.kind_of?(SubObject::SubArray)
    refute            obj.is_a?(   SubObject::SubArray)
    assert_equal [6,8], obj.to_ary
    assert_equal obj, [6,8]
    assert_equal [6,8], obj
    assert_equal [6,8,9], obj+[9]
    assert            obj.respond_to?(:to_ary)
    assert            obj.respond_to?(:map)
    refute            obj.respond_to?(:map!)
    refute            obj.respond_to?(:naiyo)
    assert_raises(NoMethodError){ obj.push 5 }
    assert_raises(NoMethodError){ obj.keep_if{} }
  end

end # class TestUnitSubObject < MiniTest::Test

