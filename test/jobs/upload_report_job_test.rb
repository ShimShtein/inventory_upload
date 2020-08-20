require 'test_plugin_helper'

class UploadReportJobTest < ActiveJob::TestCase
  include FolderIsolation

  test 'returns aborted state when disconnected' do
    organization = FactoryBot.create(:organization)
    Organization.any_instance.stubs(:owner_details).returns(
      'upstreamConsumer' => {
        'idCert' => 'TEST_CERT',
      }
    )
    FactoryBot.create(:setting, :name => 'content_disconnected', :value => true)

    ForemanInventoryUpload::Async::UploadReportJob.perform_now('', organization.id)

    label = ForemanInventoryUpload::Async::UploadReportJob.output_label(organization.id)
    progress_output = ForemanInventoryUpload::Async::ProgressOutput.get(label)
    assert_match(/Upload was stopped/, progress_output.full_output)
    assert_match(/exit 1/, progress_output.status)
  end

  test 'returns aborted state when no certificate defined on organization' do
    organization = FactoryBot.create(:organization)
    Organization.any_instance.expects(:owner_details).returns(nil)

    ForemanInventoryUpload::Async::UploadReportJob.perform_now('', organization.id)

    label = ForemanInventoryUpload::Async::UploadReportJob.output_label(organization.id)
    progress_output = ForemanInventoryUpload::Async::ProgressOutput.get(label)
    assert_match(/Skipping organization/, progress_output.full_output)
    assert_match(/exit 1/, progress_output.status)
  end
end
