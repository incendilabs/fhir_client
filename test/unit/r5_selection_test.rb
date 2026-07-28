require_relative '../test_helper'

class R5SelectionTest < Test::Unit::TestCase
  def test_explicit_r5_selection_uses_the_r5_namespace
    client = FHIR::Client.new('http://r5', fhir_version: :r5)

    assert_equal :r5, client.fhir_version
    assert_same FHIR::R5, client.fhir_namespace
    assert_same FHIR::R5::Patient, client.versioned_resource_class(:Patient)
    assert_equal FHIR::Formats::ResourceFormat::RESOURCE_JSON, client.default_format
  end

  def test_use_r5_matches_generic_version_selection
    direct = FHIR::Client.new('http://r5-direct', fhir_version: :r4)
    generic = FHIR::Client.new('http://r5-generic', fhir_version: :r4)
    direct.default_xml
    generic.default_xml

    direct.use_r5
    generic.use_fhir_version(:r5)

    assert_equal :r5, direct.fhir_version
    assert_equal direct.fhir_version, generic.fhir_version
    assert_same FHIR::R5, direct.fhir_namespace
    assert_same direct.fhir_namespace, generic.fhir_namespace
    assert_equal FHIR::Formats::ResourceFormat::RESOURCE_XML, direct.default_format
    assert_equal direct.default_format, generic.default_format
  end

  def test_r5_class_detection_precedes_the_inherited_r4_model
    client = FHIR::Client.new('http://r4', fhir_version: :r4)

    assert_include FHIR::R5::Patient.ancestors, FHIR::R5::Model
    assert_include FHIR::R5::Patient.ancestors, FHIR::Model
    assert_same FHIR::R5, client.send(:resource_namespace_for, FHIR::R5::Patient)
  end

  def test_auto_rejects_resource_class_access_before_discovery
    client = FHIR::Client.new('http://auto', fhir_version: :auto)

    namespace_error = assert_raise(ClientException) { client.fhir_namespace }
    resource_error = assert_raise(ClientException) { client.versioned_resource_class(:Patient) }

    assert_equal 'FHIR version has not been detected', namespace_error.message
    assert_equal 'FHIR version has not been detected', resource_error.message
  end

  def test_unknown_versions_do_not_fall_back_to_r4
    constructor_error = assert_raise(ClientException) do
      FHIR::Client.new('http://unknown', fhir_version: :r6)
    end
    client = FHIR::Client.new('http://r4', fhir_version: :r4)
    switch_error = assert_raise(ClientException) { client.use_fhir_version(:r6) }

    assert_equal 'Unsupported FHIR version: r6', constructor_error.message
    assert_equal 'Unsupported FHIR version: r6', switch_error.message
    assert_equal :r4, client.fhir_version
  end

  def test_existing_version_selection_is_unchanged
    expectations = {
      r4: [FHIR, FHIR::Formats::ResourceFormat::RESOURCE_JSON],
      r4b: [FHIR::R4B, FHIR::Formats::ResourceFormat::RESOURCE_JSON],
      stu3: [FHIR::STU3, FHIR::Formats::ResourceFormat::RESOURCE_JSON],
      dstu2: [FHIR::DSTU2, FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2]
    }

    expectations.each do |version, (namespace, format)|
      client = FHIR::Client.new("http://#{version}", fhir_version: version)

      assert_equal version, client.fhir_version
      assert_same namespace, client.fhir_namespace
      assert_equal format, client.default_format
    end
  end
end
