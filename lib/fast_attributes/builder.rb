module FastAttributes
  class UnsupportedTypeError < TypeError
  end

  class Builder
    def initialize(klass, options = {})
      @klass      = klass
      @options    = options
      @attributes = []
      @methods    = Module.new
    end

    def attribute(*attributes, type, options)
      unless options.is_a?(Hash)
        (attributes ||= []) << type
        type = options
        options = {}
      end

      unless FastAttributes.type_exists?(type)
        raise UnsupportedTypeError, %(Unsupported attribute type "#{type.inspect}")
      end

      @attributes << [attributes, type, options || {}]
    end

    def compile!
      compile_getter
      compile_setter
      set_defaults

      if @options[:initialize]
        compile_initialize
      end

      if @options[:attributes]
        compile_attributes(@options[:attributes])
      end

      include_methods
    end

    private

    def compile_getter
      each_attribute do |attribute, *|
        @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{attribute} # def name
            @#{attribute}  #   @name
          end              # end
        EOS
      end
    end

    def compile_setter
      each_attribute do |attribute, type, *|
        type_cast   = FastAttributes.get_type_casting(type)
        method_body = type_cast.compile_method_body(attribute, 'value')

        @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{attribute}=(value)
            @#{attribute} = #{method_body}
          end
        EOS
      end
    end

    def compile_initialize
      attribute_string = if FastAttributes.default_attributes(@klass).empty?
                           "attributes"
                         else
                           "FastAttributes.default_attributes(self.class).merge(attributes)"
                         end

      @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
        def initialize(attributes = {})
          #{attribute_string}.each do |name, value|
            public_send("\#{name}=", value) if respond_to?("\#{name}=".to_sym)
          end
        end
      EOS
    end

    def compile_attributes(mode)
      attributes = @attributes.flat_map(&:first)
      prefix = case mode
               when :accessors then ''
               else '@'
               end

      attributes = attributes.map do |attribute|
        "'#{attribute}' => #{prefix}#{attribute}"
      end

      @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
        def attributes                			                 # def attributes
          {#{attributes.join(', ')}}.with_indifferent_access #   {'name' => @name, ...}
        end                           			                 # end
      EOS
    end

    def include_methods
      @methods.instance_eval <<-EOS, __FILE__, __LINE__ + 1
        def inspect
          'FastAttributes(#{@attributes.flat_map(&:first).join(', ')})'
        end
      EOS
      @klass.send(:include, @methods)
    end

    def set_defaults
      each_attribute do |attribute, type, options|
        FastAttributes.add_default_attribute(@klass, attribute, options[:default]) if options[:default]
      end
    end

    def each_attribute
      @attributes.each do |attributes, type, options = {}|
        attributes.each do |attribute|
          yield attribute, type, options
        end
      end
    end
  end
end
