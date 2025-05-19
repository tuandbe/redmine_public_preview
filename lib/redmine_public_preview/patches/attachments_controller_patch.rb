require_dependency 'attachments_controller'

module RedminePublicPreview
  module Patches
    module AttachmentsControllerPatch
      extend ActiveSupport::Concern

      private # read_authorize is a private method in AttachmentsController

      def read_authorize
        token_value = params[:public_preview_token]

        if token_value.present? && @attachment # Ensure attachment is loaded
          # Find the token in the database. Ensure it's active and matches the issue.
          # Assumes PublicPreviewToken has methods `active?`, and attributes `object_type`, `object_id`.
          token_record = PublicPreviewToken.find_by(value: token_value, object_type: 'Issue', object_id: @attachment.container_id)

          if token_record && token_record.active? && token_record.object_id == @attachment.container_id && token_record.object_type == @attachment.container_type
            return true # Access granted by token
          end
        end
        super # Fallback to original Redmine authorization
      end
    end
  end
end

Rails.configuration.to_prepare do
  target_controller = AttachmentsController
  patch_module = RedminePublicPreview::Patches::AttachmentsControllerPatch

  unless target_controller.ancestors.include?(patch_module)
    target_controller.prepend(patch_module)
  end
end 
