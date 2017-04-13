require 'bigdecimal'
require 'date'
require 'time'
require 'fast_attributes/version'
require 'fast_attributes/builder'
require 'fast_attributes/type_cast'
require 'fast_attributes/default_attributes'
require 'active_support/core_ext/hash'

module FastAttributes
  TRUE_VALUES  = {true => nil, 1 => nil, '1' => nil, 't' => nil, 'T' => nil, 'true' => nil, 'TRUE' => nil, 'on' => nil, 'ON' => nil}
  FALSE_VALUES = {false => nil, 0 => nil, '0' => nil, 'f' => nil, 'F' => nil, 'false' => nil, 'FALSE' => nil, 'off' => nil, 'OFF' => nil}

  class << self
    def type_casting
      @type_casting ||= {}
    end

    def get_type_casting(klass)
      type_casting[klass]
    end

    def set_type_casting(klass, casting)
      symbol = klass.name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym  # DateTime => :date_time
      type_cast symbol, klass do
        from 'nil',      to: 'nil'
        from klass.name, to: '%s'
        otherwise casting
      end
    end

    def remove_type_casting(klass)
      type_casting.delete(klass)
    end

    def type_exists?(klass)
      type_casting.has_key?(klass)
    end

    def type_cast(*types_or_classes, &block)
      types_or_classes.each do |type_or_class|
        type_cast = TypeCast.new(type_or_class)
        type_cast.instance_eval(&block)
        type_casting[type_or_class] = type_cast
      end
    end
  end

  def define_attributes(options = {}, &block)
    builder = Builder.new(self, options)
    builder.instance_eval(&block)
    builder.compile!
  end

  def attribute(*attributes, type)
    builder = Builder.new(self)
    builder.attribute *attributes, type
    builder.compile!
  end

  set_type_casting String,     'String(%s)'
  set_type_casting Integer,    'Integer(%s)'
  set_type_casting Float,      'Float(%s)'
  set_type_casting Array,      'Array(%s)'
  set_type_casting Date,       'Date.parse(%s)'
  set_type_casting Time,       'Time.parse(%s)'
  set_type_casting DateTime,   'DateTime.parse(%s)'
  set_type_casting BigDecimal, 'Float(%s);BigDecimal(%s.to_s)'

  type_cast :boolean do
    otherwise <<-EOS
      if FastAttributes::TRUE_VALUES.has_key?(%s)
        true
      elsif FastAttributes::FALSE_VALUES.has_key?(%s)
        false
      elsif %s.nil?
        nil
      else
        raise FastAttributes::TypeCast::InvalidValueError, %(Invalid value "\#{%s}" for attribute "%a" of type ":boolean")
      end
    EOS
  end
end
