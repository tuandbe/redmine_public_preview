Rails.logger.info "[PublicPreviewPatchLOAD] START OF attachments_controller_patch.rb"
require_dependency 'attachments_controller'

module RedminePublicPreview
  module Patches
    module AttachmentsControllerPatch
      Rails.logger.info "[PublicPreviewPatchLOAD] Defining RedminePublicPreview::Patches::AttachmentsControllerPatch module"
      extend ActiveSupport::Concern

      # Prepended methods for the AttachmentsController
      prepended do
        Rails.logger.info "[PublicPreviewPatchLOAD] Inside prepended block of AttachmentsControllerPatch"
      end

      # Instance methods to prepend
      private # read_authorize is a private method in AttachmentsController

      def read_authorize
        Rails.logger.info "[PublicPreviewPatchEXEC] Entered patched read_authorize for attachment: #{@attachment&.id}"
        token_value = params[:public_preview_token]
        Rails.logger.info "[PublicPreviewPatchEXEC] Token from params: #{token_value}"

        if token_value.present? && @attachment
          Rails.logger.info "[PublicPreviewPatchEXEC] Attachment details: ID=#{@attachment.id}, Type=#{@attachment.container_type}, ContainerID=#{@attachment.container_id}"
          
          if @attachment.container_type == 'Issue' && @attachment.container_id.present?
            Rails.logger.info "[PublicPreviewPatchEXEC] Attempting to find PublicPreviewToken for issue_id: #{@attachment.container_id}, token_value: #{token_value}"
            public_token = ::PublicPreviewToken.find_by(value: token_value, issue_id: @attachment.container_id)
            
            if public_token
              Rails.logger.info "[PublicPreviewPatchEXEC] Found public_token: ID=#{public_token.id}, ExpiresAt=#{public_token.expires_at}, CurrentTime=#{Time.current}"
              if public_token.expires_at > Time.current
                Rails.logger.info "[PublicPreviewPatchEXEC] Token is valid and not expired. Allowing access."
                return true # Token is valid, allow access
              else
                Rails.logger.info "[PublicPreviewPatchEXEC] Token has expired."
              end
            else
              Rails.logger.info "[PublicPreviewPatchEXEC] No PublicPreviewToken found for given criteria."
            end
          else
            Rails.logger.info "[PublicPreviewPatchEXEC] Attachment is not for an Issue or container_id is missing."
          end
        else
          Rails.logger.info "[PublicPreviewPatchEXEC] No token_value or @attachment is nil. Token: #{token_value.present?}, Attachment: #{@attachment.present?}"
        end
        
        Rails.logger.info "[PublicPreviewPatchEXEC] Falling back to original read_authorize (super)."
        super # Fallback to original Redmine authorization
      end
    end
  end
end

# Prepend the patch to the AttachmentsController
# This ensures our read_authorize is checked first.
Rails.configuration.to_prepare do
  Rails.logger.info "[PublicPreviewPatchLOAD] In to_prepare block for AttachmentsControllerPatch (attachments_controller_patch.rb)"
  unless AttachmentsController.included_modules.include?(RedminePublicPreview::Patches::AttachmentsControllerPatch)
    AttachmentsController.prepend(RedminePublicPreview::Patches::AttachmentsControllerPatch)
    Rails.logger.info "[PublicPreviewPatchLOAD] AttachmentsControllerPatch prepended to AttachmentsController."
  else
    Rails.logger.info "[PublicPreviewPatchLOAD] AttachmentsControllerPatch already included in AttachmentsController."
  end
end
Rails.logger.info "[PublicPreviewPatchLOAD] END OF attachments_controller_patch.rb (to_prepare block removed)" 
