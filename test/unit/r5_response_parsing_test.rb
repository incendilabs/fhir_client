require_relative '../test_helper'

class R5ResponseParsingTest < Test::Unit::TestCase
  def test_read_parses_r5_json_and_records_response_metadata
    stub_request(:get, 'http://r5/Patient/json').to_return(
      body: FHIR::R5::Patient.new('id' => 'json').to_json,
      headers: { 'Content-Type' => 'application/fhir+json; charset=utf-8' }
    )

    reply = r5_client(:json).read(FHIR::R5::Patient, 'json')

    assert_instance_of FHIR::R5::Patient, reply.resource
    assert_equal 'json', reply.resource.id
    assert_equal :r5, reply.fhir_version
    assert_equal 'application/fhir+json', reply.response_format
  end

  def test_read_parses_r5_xml_from_generic_response_media_type
    stub_request(:get, 'http://r5/Patient/xml').to_return(
      body: FHIR::R5::Patient.new('id' => 'xml').to_xml,
      headers: { 'Content-Type' => 'application/xml' }
    )

    reply = r5_client(:json).read(FHIR::R5::Patient, 'xml')

    assert_instance_of FHIR::R5::Patient, reply.resource
    assert_equal 'xml', reply.resource.id
    assert_equal 'application/xml', reply.response_format
  end

  def test_search_parses_r5_bundle_entries_and_contained_resources
    patient = FHIR::R5::Patient.new('id' => 'patient')
    patient.contained << FHIR::R5::Observation.new('id' => 'observation', 'status' => 'final')
    bundle = FHIR::R5::Bundle.new(
      'type' => 'searchset',
      'entry' => [{ 'resource' => patient }]
    )
    stub_request(:get, 'http://r5/Patient').to_return(
      body: bundle.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    reply = r5_client(:json).search(FHIR::R5::Patient)

    assert_instance_of FHIR::R5::Bundle, reply.resource
    assert_instance_of FHIR::R5::Patient, reply.resource.entry.first.resource
    assert_instance_of FHIR::R5::Observation, reply.resource.entry.first.resource.contained.first
  end

  def test_json_and_xml_error_operation_outcomes_use_r5_models
    json_outcome = FHIR::R5::OperationOutcome.new(
      'issue' => [{ 'severity' => 'error', 'code' => 'invalid' }]
    )
    xml_outcome = FHIR::R5::OperationOutcome.new(
      'issue' => [{ 'severity' => 'error', 'code' => 'invalid' }]
    )
    stub_request(:get, 'http://r5/Patient/json-error').to_return(
      status: 400,
      body: json_outcome.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:get, 'http://r5/Patient/xml-error').to_return(
      status: 400,
      body: xml_outcome.to_xml,
      headers: { 'Content-Type' => 'application/fhir+xml' }
    )
    client = r5_client(:json)

    json_reply = client.read(FHIR::R5::Patient, 'json-error')
    xml_reply = client.read(FHIR::R5::Patient, 'xml-error')

    assert_instance_of FHIR::R5::OperationOutcome, json_reply.resource
    assert_instance_of FHIR::R5::OperationOutcome, xml_reply.resource
  end

  def test_object_oriented_json_and_xml_reads_use_r5_models
    stub_request(:get, 'http://r5/Patient/object-json').to_return(
      body: FHIR::R5::Patient.new('id' => 'object-json').to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:get, 'http://r5/Patient/object-xml').to_return(
      body: FHIR::R5::Patient.new('id' => 'object-xml').to_xml,
      headers: { 'Content-Type' => 'application/fhir+xml' }
    )
    client = r5_client(:json)
    FHIR::R5::Model.client = client

    json_patient = FHIR::R5::Patient.read('object-json')
    client.default_xml
    xml_patient = FHIR::R5::Patient.read('object-xml')

    assert_instance_of FHIR::R5::Patient, json_patient
    assert_instance_of FHIR::R5::Patient, xml_patient
  ensure
    FHIR::R5::Model.client = nil
  end

  def test_create_and_update_responses_use_r5_models
    patient = FHIR::R5::Patient.new('id' => 'patient')
    created = FHIR::R5::Patient.new('id' => 'created')
    updated = FHIR::R5::Patient.new('id' => 'updated')
    stub_request(:post, 'http://r5/Patient').to_return(
      status: 201,
      body: created.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:put, 'http://r5/Patient/patient').to_return(
      status: 200,
      body: updated.to_xml,
      headers: { 'Content-Type' => 'application/fhir+xml' }
    )
    client = r5_client(:json)

    create_reply = client.create(patient)
    update_reply = client.update(patient, 'patient')

    assert_instance_of FHIR::R5::Patient, create_reply.resource
    assert_equal 'created', create_reply.resource.id
    assert_instance_of FHIR::R5::Patient, update_reply.resource
    assert_equal 'updated', update_reply.resource.id
  end

  def test_error_create_response_uses_r5_operation_outcome
    outcome = FHIR::R5::OperationOutcome.new(
      'issue' => [{ 'severity' => 'error', 'code' => 'invalid' }]
    )
    stub_request(:post, 'http://r5/Patient').to_return(
      status: 422,
      body: outcome.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )

    reply = r5_client(:json).create(FHIR::R5::Patient.new)

    assert_instance_of FHIR::R5::OperationOutcome, reply.resource
    assert_equal :r5, reply.resource.client.fhir_version
  end

  def test_next_bundle_remains_in_the_r5_namespace
    first_bundle = FHIR::R5::Bundle.new(
      'type' => 'searchset',
      'link' => [{ 'relation' => 'next', 'url' => 'http://r5/Patient?page=2' }]
    )
    second_bundle = FHIR::R5::Bundle.new(
      'type' => 'searchset',
      'entry' => [{ 'resource' => FHIR::R5::Patient.new('id' => 'second') }]
    )
    stub_request(:get, 'http://r5/Patient').to_return(
      body: first_bundle.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:get, 'http://r5/Patient?page=2').to_return(
      body: second_bundle.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )

    next_bundle = r5_client(:json).search(FHIR::R5::Patient).resource.next_bundle

    assert_instance_of FHIR::R5::Bundle, next_bundle
    assert_instance_of FHIR::R5::Patient, next_bundle.entry.first.resource
  end

  def test_format_parameter_and_generic_json_response_use_r5_parser
    client = r5_client(:json)
    client.use_format_param = true
    stub_request(:get, 'http://r5/Patient/format?_format=application%2Ffhir%2Bjson').to_return(
      body: FHIR::R5::Patient.new('id' => 'format').to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    reply = client.read(
      FHIR::R5::Patient,
      'format',
      FHIR::Formats::ResourceFormat::RESOURCE_JSON
    )

    assert_instance_of FHIR::R5::Patient, reply.resource
    assert_equal 'application/json', reply.response_format
  end

  def test_mismatched_resource_class_fails_instead_of_using_r4_parser
    client = r5_client(:json)
    reply = FHIR::ClientReply.new(
      {},
      {
        code: 200,
        headers: { 'Content-Type' => 'application/fhir+json' },
        body: FHIR::Patient.new('id' => 'r4').to_json
      },
      client
    )

    error = assert_raise(ClientException) do
      client.parse_reply(FHIR::Patient, client.default_format, reply)
    end

    assert_match(/does not match client FHIR version r5/, error.message)
  end

  def test_unknown_class_uses_active_r5_namespace_without_r4_fallback
    client = r5_client(:json)
    reply = FHIR::ClientReply.new(
      {},
      {
        code: 200,
        headers: { 'Content-Type' => 'application/fhir+json' },
        body: FHIR::R5::ActorDefinition.new('id' => 'actor').to_json
      },
      client
    )

    resource = client.parse_reply(Class.new, client.default_format, reply)

    assert_instance_of FHIR::R5::ActorDefinition, resource
  end

  private

  def r5_client(format)
    client = FHIR::Client.new('http://r5', fhir_version: :r5)
    format == :xml ? client.default_xml : client.default_json
    client
  end
end
