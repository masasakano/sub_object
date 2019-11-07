
# SubObject - Parent class for memory-efficient sub-Something

## Summary

This class [SubObject} is the parent class for {SubString](http://rubygems.org/gems/sub_string) and alike. This class
expresses Ruby sub-Object (like Sub-String), which are obtained with the
`self[i, j]` method, but taking up negligible memory space, as its instance
internally holds the (likely positional, though arbitrary) information `(i, j)` only.  This class provides the base interface so the instance behaves
exactly like the original class (String for SubString, for example) as
duck-typing, except destructive modification, which is prohibited.

If the original object (which an instance of this class refers to) is ever
destructively modified in a way it changes its hash value, warning will be
issued whenever this instance is accessed.

The entire package of SubObject is found in the [Ruby Gems page](http://rubygems.org/gems/sub_object) and in
[Github](https://github.com/masasakano/sub_object)

### Important note to the developers

To inherit this class, make sure to include the lines equivalent to the
following 2 lines, replacing the method name `:to_str` (which is for SubString
class) to suit your child class.

```ruby
TO_SOURCE_METHOD = :to_str
alias_method TO_SOURCE_METHOD, :to_source
```

## Cencept

This class takes three parameters in the initialization: **source**, **pos**
(position), and **size**.  **source** is the original object, and basically
the constructed instance of this class holds these three pieces of information
only (plus a hash value, strictly speaking). Then, whenever it is referred to,
it reconstructs

```ruby
source[pos, size]
```

and works exactly like `source[pos, size]` does
([duck-typing](https://en.wikipedia.org/wiki/Duck_typing)), whereas it uses
negligible internal memory space on its own.  Note the information it needs
for the `source` is basically `source.object_id` or equivalent, which is
nothing in terms of memory use. In other words, this class does not create the
copy of sub-Object from the original source object, as, for example, `String#[ i, j ]` does.

As an example, the child class
[SubString](http://rubygems.org/gems/sub_string) (provided as a different Gem)
works as:

```ruby
src = "abcdef"
ss = SubString.new(src, -4, 3)  # => Similar to "abcdef"[-4,3]
print ss     # => "cde" (STDOUT)
ss+'3p'      # => "cde3p"
ss.upcase    # => "CDE"
ss.sub(/^./, 'Q') # => "Qde"
ss.is_a?(String)  # => true
"xy_"+ss     # => "xy_cde"
"cde" == ss  # => true
```

Internally the instance holds the source object.  Therefore, as long as the
instance is alive, the source object is never garbage-collected (GC).

If the source object has been destructively altered, such as with the
destructive method `clear`, the corresponding object of this class is likely
not to make sense any more.  This class can detect such destructive
modification (using the method `Object#hash`) and issues a warning whenever it
is accessed after the source object has been destructively altered, unless the
appropriate global settings (see the next section) are set to suppress it.

Similarly, because this class supplies an object with the filter appropriate
for the class when it receives any message (i.e., method), it does not make
sense to apply a destructive change on the instance of this class. Therefore,
whenever a destructive method is applied, this class tries to raise
NoMethodError exception.  The routine to identify the destructive method
relies thoroughly on the method name. The methods ending with "!" are regarded
as destructive. Other standard distructive method names are defined in the
constant {SubObject::DESTRUCTIVE_METHODS}. Each child class may add entries or
modify it.

Note that if a (likely user-defined) desturctive method passes the check, the
result is most likely to be different from intended.  It certainly never
alters this instance destructively (unless `[]` method of the source object
returns self, which is against the Ruby convention), and the returned value
may be not like the expected value.

### Potential use

You can make a subclass of this class, corresponding to any class that has the
method of `[i, j]`.  For example, **SubArray** class is perfectly possible;
indeed it is defined as {SubObject::SubArray}. To be fair, I am afraid
**SubArray** class does not have much practical value (apart from the
demonstration of the concept!), because the only advantage of this class is to
use the minimum memory, whereas the original sub-array as in `Array#[ i, j ]`
does not take much memory in the first place, given Array is by definition
just a container.

By stark contrast, each sub-String in Ruby default takes up memory according
to the length of the sub-String.  Consider an example:

```ruby
src = "Some very extremely lengthy string.... (snipped)".
sub = src[1..-1]
```

The variable `sub` uses up about the same memory of `src`. If a great number
of `sub` is created and held alive, the total memory used by the process can
become quicly multifold, even by orders of magnitude.

This is where this class comes in handy.  For example, a parsing program
applied to a huge text document with a complex grammar may hold a number of
such String variables.  By using this class instead of String, it can save
some valuable memory.

That is precisely why [SubString](http://rubygems.org/gems/sub_string), which
is a child class of this class and for String, is registered as an official
Gem. (In practice, this class is a generalised version of **SubString**, which
Ruby allows as a flexible programming language!)

## Description

### Initialization

Initialize as follows:

```ruby
SubObject.new( source, index1, index2 )
```

Usually, `index1` is the starting index and `index2` is the size, though how
they should be recognized depends on the definition of the method `[i,j]` of
`source`.

### Constant

<dl>
<dt>{SubObject::DESTRUCTIVE_METHODS}</dt>
<dd>   This public constant is the array holding the list of the names (as
    String) of the methods that should be recognized as destructive (other
    than those ending with &quot;!&quot;).</dd>
<dt>{SubObject::TO_SOURCE_METHOD}</dt>
<dd>   This public constant specifies the method that projects to (returns) the
    original-like instance; e.g., :to_str for String</dd>
</dl>



The class variable `TO_SOURCE_METHOD` is meant to be set by each child class
(and child classes only).  For example, if it is the subclass for String, it
should be `:to_str`.  Specifically, the registered method must respond to
`[source](i,j)`. Nott that in this class (parent class), it is **left unset**,
but the (private) method of the same name `to_original_method` returns
`:itself` instead.

**WARNING**: Do not set this class variable in this class, as it could result
in unexpected behaviours if a child class and the parent class are used
simultaneously.

### Class-global settings and class methods

When this class is accessed after any alteration of the original source object
has been detected, it may issue warning (as the insntace does not make sense
any more). The warning is suppressed when the Ruby global variable `$VERBOSE`
is nil (it is false in Ruby default).  Or, if the following setting is made
(internaly, it sets/reads a class instance variable) and set non-nil, its
value precedes `$VERBOSE`:

```ruby
SubObject.verbose       # => getter
SubObject.verbose=true  # => setter
```

where SubObject should be replaced with the name of your child class that
inherits {SubObject}. If this value is true or false, such a warning is issued
or suppresed, respectively, regardless of the value of the global variable
`$VERBOSE`.

### Instance methods

The following is the instance methods of {SubObject} unique to this class.

<dl>
<dt>#source()</dt>
<dd>   Returns the first argument given in initialization. The returned value is
    dup-ped and &lt;strong&gt;frozen&lt;/strong&gt;.</dd>
<dt>#pos()</dt>
<dd>   Returns the second argument given in initialization (usually meaning the
    starting index).</dd>
<dt>#subsize()</dt>
<dd>   Returns the third argument given in initialization (usually meaning the
    size of the sub-&quot;source&quot;).  Usually this is equivalent to the method
    &lt;tt&gt;#size&lt;/tt&gt;; this method is introduced in case the class of the &lt;tt&gt;source&lt;/tt&gt;
    somehow does not have the &lt;tt&gt;#size&lt;/tt&gt; method.</dd>
<dt>#pos_size()</dt>
<dd>   Returns the two-component array of &lt;tt&gt;[pos, subsize]&lt;/tt&gt;</dd>
<dt>#to_source()</dt>
<dd>   Returns the instance as close as the original &lt;tt&gt;source&lt;/tt&gt; (the class of it,
    etc)</dd>
</dl>



In addition, [#inspect](SubObject#inspect) is redefined.

Any public methods but destructive ones that are defined for the `source` can
be applied to the instance of this class.

## Algorithm

A child class of this class should redefine the constant `TO_SOURCE_METHOD` in
the child class, as well as setting alias to the appropriate method like,

```ruby
TO_SOURCE_METHOD = :to_str
alias_method TO_SOURCE_METHOD, :to_source
```

(which is an example for SubString class) so the method would project to
(return) the corresponding instance as close as the original `source` (the
class of it, etc). For example, it should be `:to_str` for
[SubString](http://rubygems.org/gems/sub_string) and `:to_ary` for
{SubObject::SubArray}.  Providing they are appropriately set, even the equal
operator works *regardless of the directions* (as long as the methods in the
other classes are designed, considering duck-typing appropriately - which
should be fine for the built-in classes).

Internally, almost any method that the instance receives, except for those
specific to this class, is processed in the following order:

1.  [#method_missing](SubObject#method_missing) (almost any methods except
    those defined in Object should be processed here)
    1.  `super` if destuctive (usually NoMethodError, because Object class
        does not have "destructive" methods, though you may argue `taint` etc
        is "destructive")
    2.  Else, `send` to [#to_source](SubObject#to_source)

2.  [#to_source](SubObject#to_source)
    1.  check whether the original [#source](SubObject#source) has been
        altered and issues a warning if the conditions are met.
    2.  `#source`[`#pos`, `#subsize`]
    3.  `send` to `TO_SOURCE_METHOD` (`:to_str` etc; `:itself` in default)

3.  Back to the method received
    1.  `send` the method with the arguments and block to it.



Note [#respond_to_missing?](SubObject#respond_to_missing?) is redefined so
those instance methods are recognized appropriately by `#respond_to?` and Ruby
built-in `#default?` sentence.

(See [this post](https://stackoverflow.com/questions/44107544/respond-to-versus-defined/58673436#58673436) for how Ruby handles in `#respond_to?` etc.)

## Example

An example of `SubObject` with a test class `MyC`, which

1.  takes the given single argument in initialization, and keeps it as its
    instance variable (`@x`),
2.  returns an own instance having the sum of `@x`, `a` and `b` for the method
    `[a,b]`
3.  has the method `plus1`, which returns its instance variable plus 1,
4.  has the method `dest!`


**Code sample**:

```ruby
class MyC
  def initialize(a); @x = a; end
  def [](a, b); MyC.new(a+b); end
  def plus1; @x+1; end
  def to_s; @x.to_s; end
  def dest!; end
end

# How MyC behaves.
myo = MyC.new(8)
myo.is_a?(MyC)   # => true
myo.to_s         # => "1"
myo.plus1        # =>  2   # (= 8+1) (self is unmodified)

# How "Sub"-MyC behaves.
obj = SubObject.new(myo, 2, 3)
obj.respond_to?(:plus1)  # => true
obj.to_s         # => "6"  # (= 1+(2+3))
obj.plus1        # =>  7   # (= 6+1)
obj.dest!        # => raise NoMethodError (destructive method)

(SubObject === obj)         # => true
obj.instance_of?(SubObject) # => true
obj.is_a?(       SubObject) # => false
(MyC       === obj)    # => false
obj.instance_of?(MyC)  # => false
obj.is_a?(       MyC)  # => true
```

## Install

This script requires [Ruby](http://www.ruby-lang.org) Version 2.0 or above.

You can install it from the usual Ruby gem command. Or, alternatively,
download it and put the library file in one of your Ruby library search paths.

## Developer's note

The master of this README file is found in
[RubyGems/sub_object](https://rubygems.org/gems/sub_object)

### Tests

Ruby codes under the directory `test/` are the test scripts. You can run them
from the top directory as `ruby test/test_****.rb` or simply run `make test`.

## Known bugs and Todo items

*   This class ignores any optional (keyword) parameters for the methods.  It
    is due to the fact Ruby
    [BasicObject#method_missing](https://ruby-doc.org/core-2.6.5/BasicObject.html#method-i-method_missing) does not take them into account as of
    Ruby-2.6.5.  It may change in future versions of Ruby.


## Copyright

<dl>
<dt>Author</dt>
<dd>   Masa Sakano &lt; info a_t wisebabel dot com &gt;</dd>
<dt>Versions</dt>
<dd>   The versions of this package follow Semantic Versioning (2.0.0)
    http://semver.org/</dd>
<dt>License</dt>
<dd>   MI</dd>
</dl>



