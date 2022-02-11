# frozen_string_literal: true

RSpec.describe RailsTemplate18f do
  it "has a version number" do
    expect(RailsTemplate18f::VERSION).not_to be nil
  end

  it "includes a Railtie class" do
    expect(RailsTemplate18f::Railtie).to be
    expect(RailsTemplate18f::Railtie.ancestors.include?(::Rails::Railtie)).to be true
  end
end
