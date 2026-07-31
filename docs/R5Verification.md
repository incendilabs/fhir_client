# FHIR R5 Client Verification

Verification date: 2026-07-31

## Source Revisions

- `fhir_client`: `4273d633730df70bdd58c3f5b14cd595edc04e95`
  (`add-r5-support`)
- `fhir_models`: `e19f0ea2709c367f441c31ad01892275645bbe92`
  (`master`)
- `fhir_stu3_models`: `71db01196b6cafe2310498135849cae356fe6f44`
  (`master`)
- `fhir_dstu2_models`: `66c58438d323f634116dc937446d42d9b4356687`
  (`master`)

## Environment

- Platform: macOS arm64
- Ruby: `3.4.9`
- RubyGems: `3.6.9`
- Bundler: `4.0.10`
- `fhir_client`: `5.1.0`
- `fhir_models`: `5.0.0`
- `fhir_stu3_models`: `3.0.1`
- `fhir_dstu2_models`: `1.0.10`
- JSON: `2.21.1`
- WebMock: `3.26.2`
- test-unit: `3.7.7`
- SimpleCov: `0.22.0`
- ActiveSupport: `8.1.3`
- Addressable: `2.9.0`
- rest-client: `2.1.0`
- Nokogiri: `1.19.4`
- OAuth2: `1.4.11`
- Rack: `3.2.6`

The test runs used the repository-local `tmp/task-8c/Gemfile.lock`. Bundler
resolved `fhir_models` from
`https://github.com/incendilabs/fhir_models.git` on `master` at the recorded
merged SHA; no local model path override was used.

## Results

| Check | Tests | Assertions | Failures | Errors | Skips | Exit |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Complete unit suite | 146 | 413 | 0 | 0 | 0 | 0 |
| Focused R5 suite | 32 | 139 | 0 | 0 | 0 | 0 |
| R4B/R4/STU3/DSTU2 regression suite | 106 | 250 | 0 | 0 | 0 | 0 |
| Gem build, install, load, and contents | - | - | 0 | 0 | 0 | 0 |

The suite logs contain expected error-level messages from tests that exercise
network failures, parser fallback, and invalid response bodies. The
test-framework totals and process exit statuses above are authoritative.

Raw logs and separate numeric exit-status files were written under
`tmp/task-8c/` during verification.

## Test Commands

All test commands used this environment:

```sh
export RBENV_VERSION=3.4.9
export PATH=/Users/kennethmyhra/.rbenv/shims:/opt/homebrew/bin:/usr/bin:/bin
export RUBYOPT=-W0
export BUNDLE_GEMFILE="$PWD/tmp/task-8c/Gemfile"
export BUNDLE_APP_CONFIG="$PWD/tmp/task-8c/.bundle"
export BUNDLE_PATH="$PWD/tmp/task-8c/gems"
```

Complete unit suite:

```sh
bundle _2.7.2_ exec ruby -Ilib -Itest -e \
  'Dir["test/**/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
```

Focused R5 selection, response parsing, workflows, and autodetection:

```sh
bundle _2.7.2_ exec ruby -Ilib -Itest -e \
  'files = ARGV.dup; ARGV.clear; files.each { |file| require File.expand_path(file) }' \
  test/unit/r5_selection_test.rb \
  test/unit/r5_response_parsing_test.rb \
  test/unit/r5_workflows_test.rb \
  test/unit/r5_autodetection_test.rb
```

Focused R4B, R4, STU3, and DSTU2 regressions:

```sh
bundle _2.7.2_ exec ruby -Ilib -Itest -e \
  'files = ARGV.dup; ARGV.clear; files.each { |file| require File.expand_path(file) }' \
  test/unit/basic_test.rb \
  test/unit/multiversion_test.rb \
  test/unit/r4b_support_test.rb \
  test/unit/model_test.rb \
  test/unit/model_extension_test.rb \
  test/unit/bundle_test.rb \
  test/unit/reference_extras_test.rb \
  test/unit/client_interface_sections/create_test.rb \
  test/unit/client_interface_sections/read_test.rb \
  test/unit/client_interface_sections/update_test.rb \
  test/unit/client_interface_sections/history_test.rb \
  test/unit/client_interface_sections/operation_test.rb
```

## Package Verification

The final `fhir_client-5.1.0.gem` was built from the recorded client revision
and installed with the merged `fhir_models 5.0.0` gem into
`tmp/task-8c/isolated-gems`.

The isolated load pre-activated the minimum supported `fhir_models 5.0.0`,
then verified:

- `FHIR::Client::VERSION` is `5.1.0`.
- `FHIR::Models::VERSION` is `5.0.0`.
- `FHIR::R5::Patient` loads and inherits from `FHIR::R5::Model`.
- The packaged FHIR API validation JSON parses with JSON `2.21.1`.
- The gem contains 41 files, including the expected runtime and documentation
  files.
- Test files are excluded from the gem.

The package check used:

```sh
gem build fhir_client.gemspec \
  --output tmp/task-8c/fhir_client-5.1.0.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-8c/isolated-gems \
  ../fhir_models/tmp/task-8b/merged-master-e19f0ea2/fhir_models-5.0.0.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-8c/isolated-gems \
  tmp/task-4e/fhir_stu3_models-3.0.1.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-8c/isolated-gems \
  tmp/task-4e/fhir_dstu2_models-1.0.10.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-8c/isolated-gems \
  tmp/task-8c/fhir_client-5.1.0.gem

GEM_HOME="$PWD/tmp/task-8c/isolated-gems" \
GEM_PATH="$PWD/tmp/task-8c/isolated-gems:$PWD/../fhir_models/tmp/test-gems" \
ruby -e \
  'gem "fhir_models", "= 5.0.0"; gem "fhir_client", "= 5.1.0"; require "fhir_client"; client = FHIR::Client.new("http://example.test", fhir_version: :r5); patient = FHIR::R5::Json.from_json(%({"resourceType":"Patient","id":"example"})); abort unless client.fhir_version == :r5 && patient.is_a?(FHIR::R5::Patient)'
```
