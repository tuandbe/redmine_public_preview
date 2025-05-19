Rails.logger.info "[PublicPreviewPatchLOAD] START OF attachments_controller_patch.rb"
require_dependency 'attachments_controller'

module RedminePublicPreview
  module Patches
    module AttachmentsControllerPatch
      # Rails.logger.info "[PublicPreviewPatchLOAD] Defining RedminePublicPreview::Patches::AttachmentsControllerPatch module"
      extend ActiveSupport::Concern

      # Prepended methods for the AttachmentsController
      prepended do
        # Rails.logger.info "[PublicPreviewPatchLOAD] Inside prepended block of AttachmentsControllerPatch"
      end

      # Instance methods to prepend
      private # read_authorize is a private method in AttachmentsController

      def read_authorize
        # Rails.logger.info "[PublicPreviewPatchEXEC] Entered patched read_authorize for attachment_id: #{@attachment&.id}"
        # Rails.logger.info "[PublicPreviewPatchEXEC] Params: #{params.inspect}"

        token_value = params[:public_preview_token]

        if token_value.present? && @attachment # Ensure attachment is loaded
          # Rails.logger.info "[PublicPreviewPatchEXEC] Token found: #{token_value} for attachment #{@attachment.id}"
          # Find the token in the database. Ensure it's active and matches the issue.
          token_record = PublicPreviewToken.find_by(value: token_value, object_type: 'Issue', object_id: @attachment.container_id)

          if token_record && token_record.active? && token_record.object_id == @attachment.container_id && token_record.object_type == @attachment.container_type
            # Rails.logger.info "[PublicPreviewPatchEXEC] Valid token found for attachment. Granting access."
            return true # Access granted by token
          else
            # Rails.logger.info "[PublicPreviewPatchEXEC] Invalid or inactive token: #{token_value}. Falling back to super."
          end
        # else
          # Rails.logger.info "[PublicPreviewPatchEXEC] No token or no attachment. Falling back to super."
        end
        super # Fallback to original Redmine authorization
      end
    end
  end
end

# Restore the to_prepare block to apply the patch
Rails.configuration.to_prepare do
  Rails.logger.info "[PublicPreviewPatchLOAD] In to_prepare block for RedminePublicPreview::Patches::AttachmentsControllerPatch (attachments_controller_patch.rb)"
  
  target_controller = AttachmentsController
  patch_module = RedminePublicPreview::Patches::AttachmentsControllerPatch

  # Check if already prepended to avoid multiple prepends if to_prepare runs multiple times
  # This check might not be foolproof for all scenarios but is a common approach.
  unless target_controller.ancestors.include?(patch_module)
    target_controller.prepend(patch_module)
    Rails.logger.info "[PublicPreviewPatchLOAD] #{patch_module} prepended to #{target_controller}."
  else
    Rails.logger.info "[PublicPreviewPatchLOAD] #{patch_module} already prepended to #{target_controller}."
  end
end

Rails.logger.info "[PublicPreviewPatchLOAD] END OF attachments_controller_patch.rb (to_prepare block for PublicPreview is now restored)" 
