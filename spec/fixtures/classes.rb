class Book
  extend FastAttributes

  attribute :title, :name, String
  attribute :pages,        Integer
  attribute :price,        BigDecimal
  attribute :authors,      Array
  attribute :published,    Date
  attribute :sold,         Time
  attribute :finished,     DateTime
  attribute :rate,         Float
end

class Author
  extend FastAttributes

  define_attributes initialize: true do
    attribute :name, String
    attribute :age,  Integer
  end
end

class Publisher
  extend FastAttributes

  define_attributes attributes: true do
    attribute :name,  String
    attribute :books, Integer
  end
end

class Reader
  extend FastAttributes

  define_attributes initialize: true, attributes: true do
    attribute :name, String
    attribute :age,  Integer
  end
end

class Toy
  extend FastAttributes

  attribute :name,  String
  attribute :price, Float

  def name
    "#{super} toy!"
  end

  def price=(value)
    super((value.to_f + 2).to_s)
  end
end

class Window
  extend FastAttributes

  define_attributes initialize: true, attributes: true do
    attribute :height, Integer
    attribute :width,  Integer
  end

  def initialize(attributes = {})
    self.height = 200
    self.width  = 80

    super(attributes)
  end

  def attributes
    super.merge('color' => 'white')
  end
end

class Placeholder < String
end

FastAttributes.type_cast Placeholder do
  from '"attribute name 1"', to: '"%a"'
  from '"attribute name 2"', to: %q("%a%%a%%%a%#{%a<<'!'}")
  otherwise '"%s %%s %%%s %%%%s #{5%%%s}"'
end

class PlaceholderClass
  extend FastAttributes
  attribute :value, Placeholder
  attribute :title, Placeholder
end

FastAttributes.type_cast :lenient_attribute do
  from '"yes"', to: 'true'
  from '"no"',  to: 'false'
  otherwise 'nil'
end

class LenientAttributes
  extend FastAttributes

  attribute :terms_of_service, :lenient_attribute
end

class DefaultLenientAttributes
  extend FastAttributes

  attribute :title,     :string
  attribute :pages,     :integer
  attribute :price,     :big_decimal
  attribute :authors,   :array
  attribute :published, :date
  attribute :sold,      :time
  attribute :finished,  :date_time
  attribute :rate,      :float
  attribute :active,    :boolean
end

class ClassWithDefaults
  extend FastAttributes

  define_attributes initialize: true, attributes: true do
    attribute :title, String, default: "a title"
    attribute :pages, Integer, default: 10
    attribute :authors, Array, default: [1, 2, 4]
    attribute :callable, String, default: lambda { "callable value" }
  end
end
