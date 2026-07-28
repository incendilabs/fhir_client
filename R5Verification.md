# FHIR R5 Client Verification

Verification date: 2026-07-28

## Source Revisions

- `fhir_client`: `43dbd0addf95036b72408bc87a896c770a6f96ca`
  (`add-r5-support`)
- `fhir_models`: `695ea76f0078465d2da8225cbb82be8ba2eec7fd`
  (`add-r5-support`)
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
- `fhir_models`: `4.1.0`
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

The test runs loaded the model libraries from the recorded sibling repository
revisions through `RUBYLIB`.

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
`tmp/task-4f/` during verification.

## Test Commands

All test commands used this environment:

```sh
export RBENV_VERSION=3.4.9
export PATH=/Users/kennethmyhra/.rbenv/shims:/opt/homebrew/bin:/usr/bin:/bin
export RUBYLIB=/Users/kennethmyhra/src/fhir_models/lib:/Users/kennethmyhra/src/fhir_dstu2_models/lib:/Users/kennethmyhra/src/fhir_stu3_models/lib
export RUBYOPT=-W0
```

Complete unit suite:

```sh
ruby -Ilib -Itest -e \
  'Dir["test/**/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
```

Focused R5 selection, response parsing, workflows, and autodetection:

```sh
ruby -Ilib -Itest -e \
  'files = ARGV.dup; ARGV.clear; files.each { |file| require File.expand_path(file) }' \
  test/unit/r5_selection_test.rb \
  test/unit/r5_response_parsing_test.rb \
  test/unit/r5_workflows_test.rb \
  test/unit/r5_autodetection_test.rb
```

Focused R4B, R4, STU3, and DSTU2 regressions:

```sh
ruby -Ilib -Itest -e \
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
and installed with locally built model gems into
`tmp/task-4f/final/gems`.

The isolated load pre-activated the minimum supported `fhir_models 4.1.0`,
then verified:

- `FHIR::Client::VERSION` is `5.1.0`.
- `FHIR::Models::VERSION` is `4.1.0`.
- `FHIR::R5::Patient` loads and inherits from `FHIR::R5::Model`.
- The packaged FHIR API validation JSON parses with JSON `2.21.1`.
- The gem contains 40 files, including the expected runtime and documentation
  files.
- Test files are excluded from the gem.

The package check used:

```sh
gem build fhir_client.gemspec \
  --output tmp/task-4f/final/fhir_client-5.1.0.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-4f/final/gems \
  tmp/task-4e/fhir_models-4.1.0.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-4f/final/gems \
  tmp/task-4e/fhir_stu3_models-3.0.1.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-4f/final/gems \
  tmp/task-4e/fhir_dstu2_models-1.0.10.gem

gem install --local --ignore-dependencies \
  --install-dir tmp/task-4f/final/gems \
  tmp/task-4f/final/fhir_client-5.1.0.gem

GEM_HOME="$PWD/tmp/task-4f/final/gems" \
GEM_PATH="$PWD/tmp/task-4f/final/gems:$HOME/.rbenv/versions/3.4.9/lib/ruby/gems/3.4.0" \
ruby -e \
  'gem "fhir_models", "= 4.1.0"; gem "fhir_client", "= 5.1.0"; require "fhir_client"; abort unless FHIR::R5::Patient.new.is_a?(FHIR::R5::Model)'
```
