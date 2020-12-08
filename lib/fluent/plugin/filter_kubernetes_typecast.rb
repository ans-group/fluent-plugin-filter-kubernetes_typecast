require 'fluent/filter'
require 'oj'

module Fluent
  class KubernetesTypecastFilter < Filter
    Fluent::Plugin.register_filter('kubernetes_typecast', self)

    # kubernetes_metadata filter by default replaces dots with underscores in metadata keys, 
    # hence fluentd.ukfast.io/field-types becoming fluentd_ukfast_io/field-types
    ANNOTATION_KEY = 'fluentd_ukfast_io/field-types'
    
    Converters = {
      'string' => lambda { |v| v.to_s },
      'integer' => lambda { |v| v.to_i },
      'float' => lambda { |v| v.to_f },
    }

    def configure(conf)
      super
    end

    def filter(tag, time, record)
      if !record.key?("kubernetes") or !record["kubernetes"].key?("annotations") or !record["kubernetes"]["annotations"].key?(ANNOTATION_KEY)
        return record
      end
        
      begin
        annotation = Oj.load(record["kubernetes"]["annotations"][ANNOTATION_KEY])
        record.each do |key, value|
          if !annotation.key?(key)
            next
          end

          type = annotation[key]

          if !Converters.key?(type)
            log.warn "Unknown type '#{type}' for casting. Valid values: #{Converters.keys.join(', ')}"
            next
          end

          record[key] = Converters[type].call(value)
        end
      rescue EncodingError => parse_exception
        log.error "Exception parsing annotation: #{parse_exception}"
      end

      record
    end
  end
end