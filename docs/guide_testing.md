# Testing guide

## Setup

Install the versions in `.tool-versions` using `mise install`, then use `mise exec --` or activate mise in your shell. Ruby 4.0.7, Node 24.21.0, and libvips are required; browser tests also need Chrome.

```sh
corepack enable
bundle install
corepack yarn install --immutable
corepack yarn build
corepack yarn build:css
RAILS_ENV=test HOST=localhost bin/rails db:test:prepare
```

Yarn 4.8.1 is selected by `packageManager` in `package.json`. Do not generate a second npm lockfile.

## Commands

```sh
PARALLEL_WORKERS=1 bin/rails test
PARALLEL_WORKERS=1 bin/rails test:system
bin/rails test test/services/llm_http_contract_test.rb
bin/rails zeitwerk:check
bundle exec bundler-audit check --update
bin/brakeman --no-pager -w2
corepack yarn npm audit --all --recursive --no-deprecations
bin/rubocop
```

After explicitly building JS and CSS, set `SKIP_JS_BUILD=1 SKIP_CSS_BUILD=1` to avoid redundant test builds. CI uses SQLite, matching the application.

## Conventions and coverage

- Minitest, Mocha, Shoulda, and FactoryBot cover models, controllers, services, and integration flows.
- Use factories rather than fixtures. Use confirmed users for authenticated flows.
- WebMock blocks outgoing Ruby HTTP except localhost. Provider-contract tests exercise the actual RubyLLM serializers/parsers against stubbed Anthropic/Gemini responses, without paid requests.
- Authentication integration tests exercise real Devise sign-in, confirmation/reconfirmation, lock enforcement, and password-reset flows with test mail delivery.
- Pagination integration tests cover page sizes, query preservation, and out-of-range redirects.
- Capybara/Selenium cover catalog, collection, dashboard, and project CRUD with real assets and Turbo.
- `test/support/shoulda_context_reporter.rb` bridges shoulda-context 2.0.0 to the Rails 8.1 reporter. Without it, failed Shoulda tests can abort reporting; remove when upstream provides compatibility.
- Avoid wall-clock-dependent limits: freeze time and assert both sides of a period boundary.

## Remaining limits

Ruby HTTP stubs do not validate live provider credentials or current model access. Docker must validate native Linux dependencies separately. The repository has existing RuboCop offenses; do not interpret passing tests as a clean lint result. The dependency summary documents the explicit unpatched build-tool advisory exception.
