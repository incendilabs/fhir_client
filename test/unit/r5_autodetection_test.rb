require_relative '../test_helper'

class R5AutodetectionTest < Test::Unit::TestCase
  def test_detects_r5_json_and_caches_r5_capability_statement
    capability = FHIR::R5::CapabilityStatement.new('fhirVersion' => '5.0.0')
    stub_request(:get, 'http://r5-autodetect/metadata').to_return(
      body: capability.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    client = auto_client(:json)

    assert_equal :r5, client.detect_version
    assert_instance_of FHIR::R5::CapabilityStatement, client.cached_capability_statement
    assert_equal :r5, client.cached_capability_statement.client.fhir_version
  end

  def test_detects_r5_xml_and_caches_r5_capability_statement
    capability = FHIR::R5::CapabilityStatement.new('fhirVersion' => '5.0.0')
    stub_request(:get, 'http://r5-autodetect/metadata').to_return(
      body: capability.to_xml,
      headers: { 'Content-Type' => 'application/fhir+xml' }
    )
    client = auto_client(:xml)

    assert_equal :r5, client.detect_version
    assert_instance_of FHIR::R5::CapabilityStatement, client.cached_capability_statement
  end

  def test_accepts_only_stable_versions_in_the_r5_technical_correction_line
    client = auto_client(:json)

    %w[5.0.0 5.0.1 5.0.2 5.0.99].each do |version|
      assert_equal :r5, client.send(:fhir_version_for, version)
    end
  end

  def test_rejects_r5_prerelease_and_unsupported_version_lines
    client = auto_client(:json)
    unsupported_versions = %w[
      5.0.0-ballot
      5.0.0-ballot2
      5.0.0-snapshot
      5.0.0-snapshot1
      5.0.0-cibuild
      5.1.0
      5.2.0
      6.0.0
    ]

    unsupported_versions.each do |version|
      error = assert_raise(ClientException) do
        client.send(:fhir_version_for, version)
      end
      assert_match(/Unsupported FHIR version.*#{Regexp.escape(version)}/, error.message)
    end
  end

  def test_failed_discovery_leaves_client_in_auto_and_blocks_operations
    capability = JSON.generate(
      'resourceType' => 'CapabilityStatement',
      'fhirVersion' => '5.0.0-ballot2'
    )
    stub_request(:get, 'http://r5-autodetect/metadata').to_return(body: capability)
    client = auto_client(:json)

    assert_raise(ClientException) { client.detect_version }
    assert_equal :auto, client.fhir_version
    assert_nil client.cached_capability_statement

    error = assert_raise(ClientException) do
      client.read(FHIR::R5::Patient, 'blocked')
    end
    assert_equal 'FHIR version has not been detected', error.message
  end

  def test_preserves_r4_r4b_stu3_and_dstu2_version_mappings
    client = auto_client(:json)

    assert_equal :r4, client.send(:fhir_version_for, '4.0.1')
    assert_equal :r4b, client.send(:fhir_version_for, '4.3.0')
    assert_equal :stu3, client.send(:fhir_version_for, '3.0.2')
    assert_equal :dstu2, client.send(:fhir_version_for, '1.0.2')
  end

  private

  def auto_client(format)
    client = FHIR::Client.new('http://r5-autodetect', fhir_version: :auto)
    format == :xml ? client.default_xml : client.default_json
    client
  end
end
