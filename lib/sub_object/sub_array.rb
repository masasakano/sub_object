# -*- coding: utf-8 -*-

require 'sub_object'  # Gem: {SubObject}[http://rubygems.org/gems/sub_object]

class SubObject

  # Child class of SubObject for Array: SubObject::SubArray
  #
  # See for detail the full reference in the top page
  # {SubObject}[http://rubygems.org/gems/sub_object]
  # and in {Github}[https://github.com/masasakano/sub_object]
  #
  # @author Masa Sakano (Wise Babel Ltd)
  #
  class SubArray < SubObject
    # Symbol of the method that projects to (returns) the original-like instance;
    # e.g., :to_str for String. The value should be overwritten in the child class of {SubObject}.
    TO_SOURCE_METHOD = :to_ary
    alias_method TO_SOURCE_METHOD, :to_source

    ar = %w( append delete delete_at delete_if fill keep_if push pop shift unshift )
    # @note Add to the list of destructive method: append delete delete_at delete_if fill keep_if push pop shift unshift
    DESTRUCTIVE_METHODS.concat ar 
  end
end

