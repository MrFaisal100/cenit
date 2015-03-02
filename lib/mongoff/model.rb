module Mongoff
  class Model

    EMPTY_SCHEMA = {}.freeze

    attr_reader :data_type

    def initialize(data_type, schema=nil)
      @data_type = data_type
      @persistable = (@schema = schema).nil?
    end

    def new
      Record.new(self)
    end

    def persistable?
      @persistable
    end

    def schema
      @schema ||= data_type.merged_schema
    end

    def for_property(property)
      #TODO Create a model space to optimize memory usage
      model = nil
      if schema['type'] == 'object' && schema['properties'] && property_schema = schema['properties'][property.to_s]
        property_schema = property_schema['items'] if property_schema['type'] == 'array' && property_schema['items']
        if (ref = property_schema['$ref'])&& property_dt = data_type.find_data_type(ref)
          model = Model.new(property_dt)
        else
          model = Model.new(data_type, property_schema)
        end
      end
      model || Model.new(data_type, EMPTY_SCHEMA)
    end

    def for_each_association(&block)
      #TODO ALL
    end

    def collection_name
      persistable? ? data_type.data_type_name.collectionize.to_sym : :empty_collection
    end

    def count
      persistable? ? Mongoid::Sessions.default[collection_name].find.count : 0
    end

    def collection_size(scale=1024)
      Mongoid::Sessions.default.command(collstats: collection_name, scale: scale)['size'] rescue 0
    end

    def method_missing(symbol, *args)
      if (query = Mongoid::Sessions.default[collection_name].find.try(symbol, *args)).is_a?(Moped::Query)
        Criteria.new(self, query)
      else
        super
      end
    end

    def eql?(obj)
      if obj.is_a?(Mongoff::Model)
        data_type == obj.data_type && schema == obj.schema
      else
        super
      end
    end
  end
end