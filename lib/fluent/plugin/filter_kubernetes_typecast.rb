require 'fluent/filter'
require 'oj'

module Fluent
  class KubernetesTypecastFilter < Filter
    Fluent::Plugin.register_filter('kubernetes_typecast', self)

    # kubernetes_metadata filter by default replaces dots with underscores in metadata keys, 
    # hence fluentd.ukfast.io/field-types becoming fluentd_ukfast_io/field-types
    FIELD_TYPES_ANNOTATION_KEY = 'fluentd_ukfast_io/field-types'
    MERGE_NAMESPACE_FIELD_TYPES_ANNOTATION_KEY = 'fluentd_ukfast_io/merge-namespace-field-types'
    
    Converters = {
      'string' => lambda { |v| v.to_s },
      'integer' => lambda { |v| v.to_i },
      'float' => lambda { |v| v.to_f },
    }

    def configure(conf)
      super
    end

    def filter(tag, time, record)
      if !record.key?("kubernetes")
        return record
      end

      annotation = nil

      # Check for namespace annotation first
      if record["kubernetes"].key?("namespace_annotations") and record["kubernetes"]["namespace_annotations"].key?(FIELD_TYPES_ANNOTATION_KEY)
        annotation = Oj.load(record["kubernetes"]["namespace_annotations"][FIELD_TYPES_ANNOTATION_KEY])
      end

      # Then check for pod annotation, overriding (or merging with) namespace annotation (if any)
      if record["kubernetes"].key?("annotations") and record["kubernetes"]["annotations"].key?(FIELD_TYPES_ANNOTATION_KEY)
        if record["kubernetes"]["annotations"].key?(MERGE_NAMESPACE_FIELD_TYPES_ANNOTATION_KEY) and record["kubernetes"]["annotations"][MERGE_NAMESPACE_FIELD_TYPES_ANNOTATION_KEY] == "true"
          annotation = annotation.merge(Oj.load(record["kubernetes"]["annotations"][FIELD_TYPES_ANNOTATION_KEY]))
        else
          annotation = Oj.load(record["kubernetes"]["annotations"][FIELD_TYPES_ANNOTATION_KEY])
        end
      end

      if !annotation
        return record
      end
        
      begin
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