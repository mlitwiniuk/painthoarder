# Testing Guide

## Stack

- Minitest 6 + minitest-spec-rails
- Mocha (mocking/stubbing)
- Shoulda (context + matchers)
- Factory Bot
- Capybara + Selenium (system tests)

## Running Tests

```bash
bin/rails test                    # all tests
bin/rails test test/models/       # model tests
bin/rails test test/services/     # service tests
bin/rails test:system             # system tests (browser)
bin/rails test test/models/paint_test.rb:42  # single test by line
```

## Test Structure

```
test/
├── models/          # 9 model tests (paint, user_paint, project, etc.)
├── controllers/     # empty (use integration tests)
├── services/        # paint_photo_analyzer_test
├── system/          # 3 system tests (paints, projects, dashboard)
├── integration/     # empty
├── fixtures/        # not used (factory_bot instead)
├── factories/       # 8 factories
└── test_helper.rb   # setup: mocha, shoulda, devise helpers, parallel
```

## Conventions

- Use `factory_bot` (not fixtures): `create(:paint)`, `build(:user)`
- Mocha for stubs: `RubyLLM.stubs(:chat).returns(fake_chat)`
- Shoulda matchers for model validations: `should validate_presence_of(:name)`
- Tests run in parallel (workers: :number_of_processors)
- Devise test helpers included in controller/integration tests

## Known Issues

- `shoulda-context` 2.0.0 has noisy `format_rerun_snippet` error with Rails 8.1 — cosmetic only, doesn't affect test results
- Devise deprecation warnings in routes — upstream issue
