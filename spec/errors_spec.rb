require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'throwing errors' do
  it 'raises an error when no rows have been added to the encoder' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    expect { encoder.close }.to raise_error(ActiveRecordCopy::Exception)
  end
end
