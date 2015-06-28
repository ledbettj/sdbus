module Sdbus
  module Types
    BASIC_MAPPING = {
      Symbol     => 's',
      String     => 's',
      TrueClass  => 'b',
      FalseClass => 'b',
      Fixnum     => 'i',
      Float      => 'd'
    }

    def self.type_string(params)
      params.map{ |p| type_for(p) }.join('')
    end

    def self.type_for(item)
      code = if BASIC_MAPPING.key?(item.class)
               BASIC_MAPPING[item.class]
             elsif item.is_a?(Array)
               "a#{type_for(item.first)}"
             elsif item.is_a?(Hash)
               "a{#{type_for(item.first.first)}#{type_for(item.first.last)}}"
             else
               raise ArgumentError, "Don't know how to map type of #{item} (#{item.class})"
             end

      code
    end
  end
end
