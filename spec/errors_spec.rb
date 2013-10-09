require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "throwing errors" do
  it "should raise an error when no rows have been added to the encoder" do
    encoder = PgDataEncoder::EncodeForCopy.new
    expect { encoder.close }.to raise_error
  end
end
