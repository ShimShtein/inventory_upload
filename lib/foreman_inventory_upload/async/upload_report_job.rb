require 'tempfile'

module ForemanInventoryUpload
  module Async
    class UploadReportJob < ShellProcess
      def self.output_label(label)
        "upload_for_#{label}"
      end

      def perform(filename, organization_id)
        @filename = filename
        @organization = Organization.find(organization_id)

        Tempfile.create([@organization.name, '.pem']) do |cer_file|
          cer_file.write(rh_credentials[:cert])
          cer_file.write(rh_credentials[:key])
          cer_file.flush
          @cer_path = cer_file.path
          super(UploadReportJob.output_label(organization_id))
        end
      end

      def command
        File.join(File.dirname(@filename), ForemanInventoryUpload.upload_script_file)
      end

      def env
        super.merge(
          'FILES' => @filename,
          'CER_PATH' => @cer_path
        )
      end

      def rh_credentials
        @rh_credentials ||= begin
          candlepin_id_certificate = @organization.owner_details['upstreamConsumer']['idCert']
          {
            cert: candlepin_id_certificate['cert'],
            key: candlepin_id_certificate['key']
          }
        end
      end
    end
  end
end
