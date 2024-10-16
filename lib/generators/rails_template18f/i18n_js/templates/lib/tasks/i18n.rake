# export translations as part of asset precompile
namespace "i18n:js" do
  desc "Call the i18n-js export method"
  task :export do
    require "i18n-js"
    I18nJS.call(config_file: "config/i18n-js.yml")
  end
end

Rake::Task["javascript:build"].enhance(["i18n:js:export"])
