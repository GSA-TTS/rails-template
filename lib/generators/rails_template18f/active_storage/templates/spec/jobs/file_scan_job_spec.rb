require "rails_helper"

RSpec.describe FileScanJob, type: :job do
  subject { described_class.new }
  let(:scanned_file) { double(clean?: true) }
  let(:unscanned_file) { double(id: 1, clean?: false, content_type: "text/plain", filename: "test.txt") }
  let(:success_response) { double(success?: true) }
  let(:error_response) { double(success?: false, body: "Error response body") }

  it "deals with a nil argument" do
    expect { subject.perform nil }.to_not raise_error
  end

  it "returns quickly if the file is already scanned" do
    expect { subject.perform scanned_file }.to_not raise_error
  end

  it "updates the scan_status after scanning the file" do
    now = Time.now
    allow(Time).to receive(:now).and_return now
    allow(unscanned_file).to receive(:open).and_yield __FILE__
    expect(unscanned_file).to receive(:update_columns).with scan_status: "scanned", updated_at: Time.now
    allow(subject).to receive(:connection).and_return double(post: success_response)
    subject.perform unscanned_file
  end

  it "marks the file as quarantined when dirty" do
    now = Time.now
    allow(Time).to receive(:now).and_return now
    allow(unscanned_file).to receive(:open).and_yield __FILE__
    expect(unscanned_file).to receive(:update_columns).with scan_status: "quarantined", updated_at: Time.now
    allow(subject).to receive(:connection).and_return double(post: error_response)
    subject.perform unscanned_file
  end
end
