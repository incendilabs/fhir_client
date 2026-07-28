require_relative '../test_helper'

class R5WorkflowsTest < Test::Unit::TestCase
  def test_create_and_update_serialize_and_parse_r5_resources
    created = FHIR::R5::Patient.new('id' => 'created')
    updated = FHIR::R5::Patient.new('id' => 'updated')
    stub_request(:post, 'http://r5-workflows/Patient').to_return(
      status: 201,
      body: created.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:put, 'http://r5-workflows/Patient/patient').to_return(
      body: updated.to_xml,
      headers: { 'Content-Type' => 'application/fhir+xml' }
    )
    client = r5_client(:json)
    patient = FHIR::R5::Patient.new('id' => 'patient')

    create_reply = client.create(patient)
    client.default_xml
    update_reply = client.update(patient, 'patient')

    assert_instance_of FHIR::R5::Patient, FHIR::R5::Json.from_json(create_reply.request[:payload])
    assert_instance_of FHIR::R5::Patient, create_reply.resource
    assert_instance_of FHIR::R5::Patient, FHIR::R5::Xml.from_xml(update_reply.request[:payload])
    assert_instance_of FHIR::R5::Patient, update_reply.resource
  end

  def test_transaction_and_batch_build_r5_bundles
    response_bundle = FHIR::R5::Bundle.new('type' => 'transaction-response')
    stub_request(:post, 'http://r5-workflows').to_return(
      body: response_bundle.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    client = r5_client(:json)

    transaction = client.begin_transaction
    entry = client.add_transaction_request(
      'POST',
      nil,
      FHIR::R5::Observation.new('id' => 'observation', 'status' => 'final')
    )
    reply = client.end_transaction
    serialized = FHIR::R5::Json.from_json(reply.request[:payload])
    batch = client.begin_batch

    assert_instance_of FHIR::R5::Bundle, transaction
    assert_instance_of FHIR::R5::Bundle::Entry, entry
    assert_instance_of FHIR::R5::Observation, entry.resource
    assert_instance_of FHIR::R5::Bundle, serialized
    assert_instance_of FHIR::R5::Observation, serialized.entry.first.resource
    assert_instance_of FHIR::R5::Bundle, reply.resource
    assert_equal :r5, reply.fhir_version
    assert_instance_of FHIR::R5::Bundle, batch
    assert_equal 'batch', batch.type
  end

  def test_match_and_terminology_operations_use_r5_parameters_and_responses
    match_bundle = FHIR::R5::Bundle.new(
      'type' => 'searchset',
      'entry' => [{ 'resource' => FHIR::R5::Patient.new('id' => 'match') }]
    )
    lookup_result = FHIR::R5::Parameters.new('id' => 'lookup')
    stub_request(:post, 'http://r5-workflows/Patient/$match').to_return(
      body: match_bundle.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:post, 'http://r5-workflows/CodeSystem/$lookup').to_return(
      body: lookup_result.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    client = r5_client(:json)

    match_reply = client.match(
      FHIR::R5::Patient.new,
      { matchCount: 1, onlyCertainMatches: true },
      FHIR::Formats::ResourceFormat::RESOURCE_JSON
    )
    lookup_reply = client.code_system_lookup(
      operation: {
        method: 'POST',
        parameters: {
          'code' => { type: 'Code', value: 'example' },
          'system' => { type: 'Uri', value: 'http://example.test/system' }
        }
      }
    )

    assert_instance_of FHIR::R5::Parameters, FHIR::R5::Json.from_json(match_reply.request[:payload])
    assert_instance_of FHIR::R5::Bundle, match_reply.resource
    assert_instance_of FHIR::R5::Patient, match_reply.resource.entry.first.resource
    assert_instance_of FHIR::R5::Parameters, FHIR::R5::Json.from_json(lookup_reply.request[:payload])
    assert_instance_of FHIR::R5::Parameters, lookup_reply.resource
  end

  def test_validate_and_validate_existing_parse_r5_operation_outcomes
    outcome = FHIR::R5::OperationOutcome.new(
      'issue' => [{ 'severity' => 'information', 'code' => 'informational' }]
    )
    stub_request(:post, 'http://r5-workflows/Patient/$validate').to_return(
      body: outcome.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:post, 'http://r5-workflows/Patient/patient/$validate').to_return(
      body: outcome.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    client = r5_client(:json)
    patient = FHIR::R5::Patient.new('id' => 'patient')

    validate_reply = client.validate(patient)
    existing_reply = client.validate_existing(patient, 'patient')

    assert_instance_of FHIR::R5::OperationOutcome, validate_reply.resource
    assert_instance_of FHIR::R5::OperationOutcome, existing_reply.resource
    assert_instance_of FHIR::R5::Parameters, FHIR::R5::Json.from_json(validate_reply.request[:payload])
  end

  def test_relative_absolute_contained_and_versioned_references_use_r5
    patient = FHIR::R5::Patient.new('id' => 'patient')
    observation = FHIR::R5::Observation.new('id' => 'contained', 'status' => 'final')
    patient.contained << observation
    stub_request(:get, 'http://r5-workflows/Patient/relative').to_return(
      body: FHIR::R5::Patient.new('id' => 'relative').to_json
    )
    stub_request(:get, 'http://r5-workflows/Patient/same-base').to_return(
      body: FHIR::R5::Patient.new('id' => 'same-base').to_json
    )
    stub_request(:get, 'http://external-r5/Patient/external').to_return(
      body: FHIR::R5::Patient.new('id' => 'external').to_json
    )
    stub_request(:get, 'http://r5-workflows/Patient/versioned/_history/2').to_return(
      body: FHIR::R5::Patient.new('id' => 'versioned').to_json
    )
    client = r5_client(:json)
    FHIR::R5::Model.client = client

    contained = patient.resolve(FHIR::R5::Reference.new('reference' => '#contained'))
    relative = FHIR::R5::Reference.new('reference' => 'Patient/relative').read
    same_base = FHIR::R5::Reference.new(
      'reference' => 'http://r5-workflows/Patient/same-base'
    ).read
    external = FHIR::R5::Reference.new(
      'reference' => 'http://external-r5/Patient/external'
    ).read
    versioned = FHIR::R5::Reference.new(
      'reference' => 'Patient/versioned/_history/2'
    ).vread

    assert_same observation, contained
    assert_instance_of FHIR::R5::Patient, relative
    assert_instance_of FHIR::R5::Patient, same_base
    assert_same client, same_base.client
    assert_instance_of FHIR::R5::Patient, external
    assert_not_same client, external.client
    assert_equal :r5, external.client.fhir_version
    assert_same client, FHIR::R5::Model.client
    assert_instance_of FHIR::R5::Patient, versioned
  ensure
    FHIR::R5::Model.client = nil
  end

  def test_patient_and_encounter_record_helpers_return_r5_bundles
    patient_bundle = FHIR::R5::Bundle.new(
      'type' => 'searchset',
      'entry' => [{ 'resource' => FHIR::R5::Patient.new('id' => 'patient') }]
    )
    encounter_bundle = FHIR::R5::Bundle.new(
      'type' => 'searchset',
      'entry' => [{ 'resource' => FHIR::R5::Encounter.new('id' => 'encounter') }]
    )
    stub_request(:get, 'http://r5-workflows/Patient/patient/$everything').to_return(
      body: patient_bundle.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:get, 'http://r5-workflows/Encounter/encounter/$everything').to_return(
      body: encounter_bundle.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    client = r5_client(:json)

    patient_reply = client.fetch_patient_record('patient')
    encounter_reply = client.fetch_encounter_record('encounter')

    assert_instance_of FHIR::R5::Bundle, patient_reply.resource
    assert_instance_of FHIR::R5::Patient, patient_reply.resource.entry.first.resource
    assert_instance_of FHIR::R5::Bundle, encounter_reply.resource
    assert_instance_of FHIR::R5::Encounter, encounter_reply.resource.entry.first.resource
  end

  def test_json_and_xml_patch_responses_remain_r5
    json_outcome = FHIR::R5::OperationOutcome.new(
      'issue' => [{ 'severity' => 'information', 'code' => 'informational' }]
    )
    xml_outcome = FHIR::R5::OperationOutcome.new(
      'issue' => [{ 'severity' => 'information', 'code' => 'informational' }]
    )
    stub_request(:patch, 'http://r5-workflows/Patient/json').to_return(
      body: json_outcome.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    stub_request(:patch, 'http://r5-workflows/Patient/xml').to_return(
      body: xml_outcome.to_xml,
      headers: { 'Content-Type' => 'application/fhir+xml' }
    )
    client = r5_client(:json)

    json_reply = client.partial_update(
      FHIR::R5::Patient,
      'json',
      [{ op: 'replace', path: '/Patient/active', value: false }],
      {},
      FHIR::Formats::ResourceFormat::RESOURCE_JSON
    )
    xml_reply = client.partial_update(
      FHIR::R5::Patient,
      'xml',
      [{ op: 'replace', path: '/Patient/active', value: false }],
      {},
      FHIR::Formats::ResourceFormat::RESOURCE_XML
    )

    assert_instance_of FHIR::R5::OperationOutcome, json_reply.resource
    assert_instance_of FHIR::R5::OperationOutcome, xml_reply.resource
  end

  def test_r5_model_history_returns_r5_bundle
    bundle = FHIR::R5::Bundle.new(
      'type' => 'history',
      'entry' => [{ 'resource' => FHIR::R5::Patient.new('id' => 'history') }]
    )
    stub_request(:get, 'http://r5-workflows/Patient/_history').to_return(
      body: bundle.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    client = r5_client(:json)
    FHIR::R5::Model.client = client

    result = FHIR::R5::Patient.resource_history

    assert_instance_of FHIR::R5::Bundle, result
    assert_instance_of FHIR::R5::Patient, result.entry.first.resource
  ensure
    FHIR::R5::Model.client = nil
  end

  def test_reissued_request_retains_r5_version_and_payload_namespace
    response = FHIR::R5::Patient.new('id' => 'reissued')
    stub_request(:post, 'http://r5-workflows/Patient').to_return(
      status: 201,
      body: response.to_json,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
    client = r5_client(:json)
    original = client.create(FHIR::R5::Patient.new('id' => 'request'))
    string_keyed_request = original.request.transform_keys(&:to_s)

    reissued = client.reissue_request(string_keyed_request)
    parsed = client.parse_reply(FHIR::R5::Patient, client.default_format, reissued)

    assert_equal :r5, reissued.fhir_version
    assert_instance_of FHIR::R5::Patient, FHIR::R5::Json.from_json(reissued.request[:payload])
    assert_instance_of FHIR::R5::Patient, parsed
  end

  private

  def r5_client(format)
    client = FHIR::Client.new('http://r5-workflows', fhir_version: :r5)
    format == :xml ? client.default_xml : client.default_json
    client
  end
end
