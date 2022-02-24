require "rails_helper"

RSpec.describe FileUpload, type: :model do
  subject { described_class.new }

  describe "validations" do
    before do
      subject.file.attach(io: File.open(__FILE__), filename: "file_upload_spec.rb")
    end

    %w[uploaded scan_failed scanned quarantined].each do |valid_status|
      it "allows scan_status=#{valid_status}" do
        pending "#{described_class.name} cannot be valid without a record to belong_to"
        subject.scan_status = valid_status
        expect(subject).to be_valid
      end
    end

    it "is invalid with a bad scan_status" do
      subject.scan_status = "invalid"
      expect(subject).to_not be_valid
    end
  end

  describe "#clean?" do
    it "returns true when scan_status is scanned" do
      subject.scan_status = "scanned"
      expect(subject).to be_clean
    end

    it "returns false when scan_status is not scanned" do
      subject.scan_status = "uploaded"
      expect(subject).to_not be_clean
      subject.scan_status = "quarantined"
      expect(subject).to_not be_clean
    end
  end
end
