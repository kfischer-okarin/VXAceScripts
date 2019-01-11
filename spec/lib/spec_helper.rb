RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  begin
    # This allows you to limit a spec run to individual examples or groups
    # you care about by tagging them with `:focus` metadata. When nothing
    # is tagged with `:focus`, all examples get run. RSpec also provides
    # aliases for `it`, `describe`, and `context` that include `:focus`
    # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
    config.filter_run_when_matching :focus

    # Limits the available syntax to the non-monkey patched syntax that is
    # recommended. For more details, see:
    #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
    #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
    #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
    config.disable_monkey_patching!

    # This setting enables warnings. It's recommended, but in some cases may
    # be too noisy due to issues in dependencies.
    config.warnings = true

    # Many RSpec users commonly either run the entire suite or an individual
    # file, and it's useful to allow more verbose output when running an
    # individual spec file.
    if config.files_to_run.one?
      config.default_formatter = "doc"
    end

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = :random

    # Seed global randomization in this process using the `--seed` CLI option.
    # Setting this allows you to use `--seed` to deterministically reproduce
    # test failures related to randomization by passing the same `--seed` value
    # as the one that triggered the failure.
    Kernel.srand config.seed
  end
end
