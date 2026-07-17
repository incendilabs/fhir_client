require_relative '../test_helper'

class R4BSupportTest < Test::Unit::TestCase
  def test_explicit_r4b_selection_uses_the_r4b_namespace
    client = FHIR::Client.new('http://r4b')
    client.use_r4b

    assert_equal :r4b, client.fhir_version
    assert_same FHIR::R4B, client.fhir_namespace
    assert_same FHIR::R4B::Patient, client.versioned_resource_class('Patient')
  end

  def test_r4b_json_read
    stub_request(:get, 'http://r4b/Patient/foo').to_return(
      body: FHIR::R4B::Patient.new('id' => 'foo').to_json
    )
    client = r4b_client(:json)
    reply = client.read(FHIR::R4B::Patient, 'foo')

    assert_instance_of FHIR::R4B::Patient, reply.resource
    assert_equal :r4b, reply.fhir_version
  end

  def test_r4b_class_selects_r4b_parser_before_inherited_r4_parser
    stub_request(:get, 'http://r4b/Patient/foo').to_return(
      body: FHIR::R4B::Patient.new('id' => 'foo').to_json
    )
    client = FHIR::Client.new('http://r4b')
    client.default_json

    reply = client.read(FHIR::R4B::Patient, 'foo')

    assert_instance_of FHIR::R4B::Patient, reply.resource
  end

  def test_r4b_xml_read
    stub_request(:get, 'http://r4b/Patient/foo').to_return(
      body: FHIR::R4B::Patient.new('id' => 'foo').to_xml
    )
    client = r4b_client(:xml)

    assert_instance_of FHIR::R4B::Patient, client.read(FHIR::R4B::Patient, 'foo').resource
  end

  def test_r4b_models_inherit_client_extensions
    stub_request(:get, 'http://r4b/Patient/foo').to_return(
      body: FHIR::R4B::Patient.new('id' => 'foo').to_json
    )
    client = r4b_client(:json)
    FHIR::R4B::Model.client = client

    assert_instance_of FHIR::R4B::Patient, FHIR::R4B::Patient.read('foo')
  end

  def test_r4b_transaction_uses_r4b_bundles
    response_bundle = FHIR::R4B::Bundle.new('type' => 'transaction-response')
    stub_request(:post, 'http://r4b').to_return(body: response_bundle.to_xml)
    client = r4b_client(:xml)

    request_bundle = client.begin_transaction
    client.add_transaction_request('GET', 'Patient/foo')
    reply = client.end_transaction

    assert_instance_of FHIR::R4B::Bundle, request_bundle
    assert_instance_of FHIR::R4B::Bundle, reply.resource
    assert_equal :r4b, reply.fhir_version
  end

  def test_r4b_bundle_and_reference_extensions
    bundle = FHIR::R4B::Bundle.new
    bundle.link << FHIR::R4B::Bundle::Link.new('relation' => 'next', 'url' => 'http://r4b/page/2')
    reference = FHIR::R4B::Reference.new('reference' => 'Patient/foo')

    assert_equal 'http://r4b/page/2', bundle.next_link.url
    assert_same FHIR::R4B::Patient, reference.resource_class
  end

  def test_external_r4b_reference_preserves_client_version
    stub_request(:get, 'http://external/Patient/foo').to_return(
      body: FHIR::R4B::Patient.new('id' => 'foo').to_json
    )
    client = r4b_client(:json)
    FHIR::R4B::Model.client = client
    reference = FHIR::R4B::Reference.new('reference' => 'http://external/Patient/foo')

    resource = reference.read

    assert_instance_of FHIR::R4B::Patient, resource
    assert_equal :r4b, resource.client.fhir_version
  end

  def test_autodetect_r4b_json
    capability = FHIR::R4B::CapabilityStatement.new('fhirVersion' => '4.3.0')
    stub_request(:get, 'http://autodetect/metadata').to_return(body: capability.to_json)
    client = FHIR::Client.new('http://autodetect')
    client.default_json

    assert_equal :r4b, client.detect_version
    assert_instance_of FHIR::R4B::CapabilityStatement, client.cached_capability_statement
  end

  def test_autodetect_r4b_xml
    capability = FHIR::R4B::CapabilityStatement.new('fhirVersion' => '4.3.0')
    stub_request(:get, 'http://autodetect/metadata').to_return(body: capability.to_xml)
    client = FHIR::Client.new('http://autodetect')
    client.default_xml

    assert_equal :r4b, client.detect_version
    assert_instance_of FHIR::R4B::CapabilityStatement, client.cached_capability_statement
  end

  def test_autodetect_rejects_unsupported_fhir_4_version
    capability = JSON.generate('resourceType' => 'CapabilityStatement', 'fhirVersion' => '4.1.0')
    stub_request(:get, 'http://autodetect/metadata').to_return(body: capability)
    client = FHIR::Client.new('http://autodetect')
    client.default_json

    error = assert_raise(ClientException) { client.detect_version }
    assert_match(/Unsupported FHIR version.*4\.1\.0/, error.message)
  end

  private

  def r4b_client(format)
    client = FHIR::Client.new('http://r4b')
    format == :xml ? client.default_xml : client.default_json
    client.use_r4b
    client
  end
end
