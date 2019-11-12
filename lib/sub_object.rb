# -*- coding: utf-8 -*-

# Parent class for SubString and SubObject::SubArray or similar.
#
# == Summary
#
# This class SubObject is the parent class for
# {SubString}[http://rubygems.org/gems/sub_string] and alike.
# This class expresses Ruby sub-Object (like Sub-String),
# which are obtained with the +self[i, j]+ method,
# but taking up negligible memory space, as its instance internally holds
# the (likely positional, though arbitrary) information +(i, j)+ only.  It provides the basic
# interface so the instance behaves exactly like the original
# class (String for SubString, for example) as duck-typing, except
# destructive modification, which is prohibited.
#
# If the original object is destructively modified in a way it changes
# its hash value, warning is issued whenever this instance is accessed.
#
# == Important note to the developers
#
# To inherit this class, make sure to include the lines equivalent to
# the following 2 lines, replacing the method name +:to_str+ (which is for
# SubString class) to suit your child class.
#
#   TO_SOURCE_METHOD = :to_str
#   alias_method TO_SOURCE_METHOD, :to_source
#
# The full reference is found in the top page
# {SubObject}[http://rubygems.org/gems/sub_object]
# and in {Github}[https://github.com/masasakano/sub_object]
#
# @author Masa Sakano (Wise Babel Ltd)
#
class SubObject
  # The verbosity flag specific to this class, which has a priority
  # over the global $VERBOSE if set non-nil. If this is true or false,
  # the warning is always issued or suppressed, respectively, when
  # an instance is accessed after the source object is destructively modified.
  # NOTE this class instance variable is specific to this class and
  # is NOT shared with or inherited to its children!
  @verbosity = nil

  # Symbol of the method that projects to (returns) the original-like instance;
  # e.g., :to_str for String. The value should be overwritten in the child class of {SubObject}.
  TO_SOURCE_METHOD = :itself

  # Symbol of the method to get the original-like instance; e.g., :to_str for String.
  # The value should be set in the child class, along with the crucial alias, e.g.,
  #
  #   TO_SOURCE_METHOD = :to_str
  #   alias_method TO_SOURCE_METHOD, :to_source
  #
  # @return [Symbol] Method name like :to_str
  def to_source_method
    self.class::TO_SOURCE_METHOD
  end
  private :to_source_method

  # Getter of the class instance variable @verbosity
  def self.verbose
    (defined? @verbosity) ? @verbosity : nil
  end

  # Setter of the class instance variable @@verbosity
  def self.verbose=(obj)
    @verbosity=obj
  end

  # Warning/Error messages.
  ERR_MSGS = {
    no_method_error: 'source does not accept #[] method',
    argument_error:  'source does not accept #[i, j]-type method',
    type_error:      'wrong type for (pos, size)=(%s, %s)',  # Specify (pos,size) as the argument.
  }
  private_constant :ERR_MSGS  # since Ruby 1.9.3

  # List of the names (String) of destructive methods (other than those ending with "!").
  DESTRUCTIVE_METHODS = %w( []= << clear concat force_encoding insert prepend replace )

  # Starting (character) position
  attr_reader :pos

  # Setter/Getter of the attribute. nil in default.
  attr_accessor :attr

  # Returns a new instance of SubObject equivalent to source[ pos, size ]
  #
  # @param source [Object] source Object
  # @param pos [Integer, Object] The first index for the method +#[]+, usually the starting index position.
  # @param size [Integer, Object] The second index for the method +#[]+, usually the size.
  # @param attr: [Object] user-specified arbitrary object
  def initialize(source, pos, size, attr: nil)
    @source, @pos, @isize = source, pos, size
    @attr = attr

    # Sanity check
    begin
      _ = @source[@pos, @isize]
    rescue NoMethodError
      raise TypeError, ERR_MSGS[:no_method_error]
    rescue ArgumentError
      raise TypeError, ERR_MSGS[:argument_error]
    rescue TypeError
      raise TypeError, ERR_MSGS[:type_error]%[pos.inspect, size.inspect]
    end

    if !source.respond_to? self.class::TO_SOURCE_METHOD
      raise TypeError, "Wrong source class #{source.class.name} for this class #{self.class.name}"
    end

    # Hash value retained to check its potential destructive change
    @hash = @source.hash
  end

  # @return [Aray]
  def pos_size
    [@pos, @isize]
  end

  # @return usually the size (Integer)
  def subsize
    @isize
  end

  # Frozen String returned.
  def source
    warn_hash
    src = @source.dup
    src.freeze
    src
  end

  # Returns the original representation of the instance as in the source
  #
  # Each child class should set the constant TO_SOURCE_METHOD
  # appropriately and should alias this method to the method registered
  # to TO_SOURCE_METHOD . For example, for SubString,
  #
  #   TO_SOURCE_METHOD = :to_str
  #   alias_method TO_SOURCE_METHOD, :to_source
  #
  # Warning: DO NOT OVERWRITE THIS METHOD.
  #
  # @return [Object]
  def to_source
    warn_hash
    @source[@pos, @isize].send(to_source_method)
  end

  # Method aliases to back up the Object default originals
  %i(== === is_a? :kind_of? =~ <=> to_s).each do |ec|
    begin
      alias_method :to_s_before_sub_object, ec if !method_defined? :to_s_before_sub_object
    rescue NameError
      warn "The method {#ec.inspect} is disabled in Object(!!), hence for #{name}" if !$VERBOSE.nil?
    end
  end

  # Redefining some methods in Object
  #
  # Statements repeated, because Module#define_method uses instance_eval
  # at run-time, which is inefficient.

  # Redefining a method in Object to evaluate via {#to_source}
  def ==(       *rest); to_source.send(__method__, *rest); end
  # Redefining a method in Object to evaluate via {#to_source}
  def ===(      *rest); to_source.send(__method__, *rest); end
  # Redefining a method in Object to evaluate via {#to_source}
  def is_a?(    *rest); to_source.send(__method__, *rest); end
  # Redefining a method in Object to evaluate via {#to_source}
  def kind_of?(*rest); to_source.send(__method__, *rest); end
  # Redefining a method in Object to evaluate via {#to_source}
  def =~(       *rest); to_source.send(__method__, *rest); end
  # Redefining a method in Object to evaluate via {#to_source}
  def <=>(      *rest); to_source.send(__method__, *rest); end
  # Redefining a method in Object to evaluate via {#to_source}
  def to_s(     *rest); to_source.send(__method__, *rest); end

  alias_method :inspect_before_sub_object, :inspect

  # @return [String]
  def inspect
    warn_hash
    sprintf('%s[%d,%d]%s', self.class.name.split(/::/)[-1], @pos, @isize, @source[@pos, @isize].inspect)
  end

  # method_missing for any but destructive methods
  #
  # @return [Object]
  # @see #respond_to_missing?
  def method_missing(method_name, *rest, &block)
    destructive_method?(method_name) ? super : to_source.send(method_name, *rest, &block)
  end

  # Obligatory redefinition, following redefined {#method_missing}
  def respond_to_missing?(method_name, *rest)
    destructive_method?(method_name) ? super : to_source.send(:respond_to?, method_name, *rest)
  end

  ##################
  private
  ##################

  def destructive_method?(method_name)
    met = method_name.to_s
    (/!$/ =~ met) || DESTRUCTIVE_METHODS.include?(met)
  end
  private :destructive_method?

  def warn_hash
    klass = self.class
    verbosity_loc = (klass.instance_variable_defined?(:@verbosity) ? klass.instance_variable_get(:@verbosity) : nil)
    if ((verbosity_loc.nil? && !$VERBOSE.nil?) || verbosity_loc) && @hash != @source.hash
      str = @source[@pos, @isize].inspect
      # Suppresses the length only for warning (not the standard inspect), which would be printed repeatedly.
      str = str[0,60]+'..."' if str.size > 64
      # warn() would not run if $VERBOSE.nil? (in this case it should run if @verbosity is true).
      $stderr.printf("WARNING: source string has destructively changed: %s[%d,%d]%s\n", self.class.name, @pos, @isize, str)
    end
  end
  private :warn_hash
end

