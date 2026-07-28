# Changelog

## 5.1.0

- Add explicit FHIR R5 client selection and `FHIR::R5` model routing.
- Parse R5 JSON, XML, error responses, Bundles, operations, transactions, and
  references without falling back to R4.
- Add metadata-based discovery for stable FHIR R5 `5.0.x` endpoints.
- Keep parsed resource clients instance-local so external references do not
  redirect later requests.

## 5.0.0

- Require `fhir_version:` when constructing `FHIR::Client`.
- Add explicit `fhir_version: :auto` metadata-based version detection.
- Add FHIR R4B client routing and parsing support.
