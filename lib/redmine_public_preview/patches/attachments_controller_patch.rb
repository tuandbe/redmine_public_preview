require_dependency 'attachments_controller'

module RedminePublicPreview
  module Patches
    module AttachmentsControllerPatch
      extend ActiveSupport::Concern

      # Override check_if_login_required from ApplicationController
      # This method is called as a before_action in ApplicationController.
      # By overriding it here, we can conditionally bypass the login check.
      def check_if_login_required
        # If it's an attempt to access an attachment via public preview token
        # for specific actions, then we effectively skip the original login check.
        if public_preview_token_access_attempt?
          return true # Allow request to proceed without standard login check
        end

        # If not a public preview token access for attachments, fall back to the original behavior.
        super
      end

      private

      # Helper method to determine if the current request is an attempt
      # to access an attachment via a public preview token.
      def public_preview_token_access_attempt?
        # Check if the action is one that serves files and if the token parameter is present.
        %w[show download thumbnail].include?(params[:action].to_s) && params[:public_preview_token].present?
      end

      # Patched read_authorize method for token-based access.
      # The original AttachmentsController#read_authorize is public.
      def read_authorize
        token_value = params[:public_preview_token]

        # Ensure @attachment is loaded and it belongs to an Issue
        if token_value.present? && @attachment && @attachment.container_type == 'Issue'
          # Find the token in the database using issue_id.
          # This assumes your PublicPreviewToken model has an `issue_id` attribute.
          token_record = PublicPreviewToken.find_by(
            value: token_value,
            issue_id: @attachment.container_id # Use issue_id directly
          )

          # Ensure token exists, is active (not expired), and matches the attachment's issue.
          if token_record && token_record.expires_at > Time.current # Check for expiration
            # Additional check to ensure the token is indeed for this specific issue,
            # although find_by already covers this if issue_id is unique for the token.
            # This is more of a sanity check or if there could be other criteria.
            if token_record.issue_id == @attachment.container_id
              return true # Access granted by token
            end
          end
        end
        # Fallback to original Redmine authorization if no valid token access or if attachment is not an Issue attachment
        super
      end
    end
  end
end 
