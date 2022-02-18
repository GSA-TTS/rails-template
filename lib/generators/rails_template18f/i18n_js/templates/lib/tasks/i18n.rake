# export translations as part of asset precompile

Rake::Task["assets:precompile"].enhance(["i18n:js:export"])

if Rake::Task.task_defined?("test:prepare")
  Rake::Task["test:prepare"].enhance(["i18n:js:export"])
elsif Rake::Task.task_defined?("db:test:prepare")
  Rake::Task["db:test:prepare"].enhance(["i18n:js:export"])
end
