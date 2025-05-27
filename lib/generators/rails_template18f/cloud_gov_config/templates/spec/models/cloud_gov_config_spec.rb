# frozen_string_literal: true

require "rails_helper"

RSpec.describe CloudGovConfig, type: :model do
  describe "#dig" do
    [nil, "", "{}"].each do |blank|
      context "VCAP_SERVICES is #{blank.inspect}" do
        subject { described_class.new blank }
        it "returns nil" do
          expect(subject.dig(:s3, :credentials, :bucket)).to be_nil
        end
      end
    end

    context "VCAP_SERVICES is set" do
      subject { described_class.new vcap }
      let(:bucket_name) { "bucket-name" }
      let(:vcap) {
        {
          s3: [{
            credentials: {
              bucket: bucket_name
            }
          }]
        }.to_json
      }

      it "can find a path" do
        expect(subject.dig(:s3, :credentials, :bucket)).to eq bucket_name
      end

      it "returns nil for a missing path" do
        expect(subject.dig(:s3, :missing)).to be_nil
      end

      it "returns nil for a missing service" do
        expect(subject.dig(:rds, :credentials)).to be_nil
      end
    end
  end
end
