module FHIR
  module VersionManagement

    def versioned_resource_class(klass = nil)
      mod = fhir_namespace
      return mod if klass.nil?
      mod.const_get(klass)
    end

    def fhir_namespace
      case @fhir_version
      when :r4
        FHIR
      when :r4b
        FHIR::R4B
      when :stu3
        FHIR::STU3
      when :dstu2
        FHIR::DSTU2
      else
        raise ClientException, "Unsupported FHIR version: #{@fhir_version}"
      end
    end

    def versioned_format_class(format = nil)
      if @fhir_version == :dstu2
        case format
        when nil
          @default_format.include?('xml') ?
              FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2 :
              FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
        when :xml
          FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2
        else
          FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
        end
      else
        case format
        when nil
          @default_format.include?('xml') ?
              FHIR::Formats::ResourceFormat::RESOURCE_XML :
              FHIR::Formats::ResourceFormat::RESOURCE_JSON
        when :xml
          FHIR::Formats::ResourceFormat::RESOURCE_XML
        else
          FHIR::Formats::ResourceFormat::RESOURCE_JSON
        end
      end
    end

    private

    def resource_namespace_for(klass = nil)
      return fhir_namespace if klass.nil?

      ancestors = klass.ancestors
      return FHIR::R4B if defined?(FHIR::R4B::Model) && ancestors.include?(FHIR::R4B::Model)
      return FHIR::DSTU2 if ancestors.include?(FHIR::DSTU2::Model)
      return FHIR::STU3 if ancestors.include?(FHIR::STU3::Model)
      return FHIR if ancestors.include?(FHIR::Model)

      fhir_namespace
    end

  end
end
