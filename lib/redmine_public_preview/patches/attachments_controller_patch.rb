require_dependency 'attachments_controller'

module RedminePublicPreview
  module Patches
    module AttachmentsControllerPatch
      extend ActiveSupport::Concern

      # When this module is prepended, these methods will override the
      # original ones in AttachmentsController.

      def check_if_login_required
        # If the request is for an attachment and includes a public preview token,
        # we bypass the standard login check. Authorization will be handled
        # by our patched `read_authorize` method.
        if params[:public_preview_token].present? && %w[show download thumbnail].include?(params[:action].to_s)
          return # Skip login check, handled by read_authorize
        end

        # For all other requests, fall back to Redmine's default behavior.
        super
      end

      def read_authorize
        token_value = params[:public_preview_token]

        # Only apply token logic if a token is present and the attachment is on an issue.
        if token_value.present? && @attachment&.container_type == 'Issue'
          # Find the token record by its value
          token_record = PublicPreviewToken.find_by(value: token_value)

          # Ensure the token exists, is not expired, and is linked to an issue
          if token_record&.expires_at&. > Time.current && token_record.issue_id
            # Retrieve the main issue from the token
            main_issue = token_record.issue # Now works thanks to `belongs_to :issue`

            if main_issue
              attachment_issue = @attachment.container

              # Grant access if the attachment is on the main issue OR a descendant of it.
              # Using `ancestors` on the attachment's issue is generally more efficient.
              if main_issue == attachment_issue || attachment_issue.ancestors.include?(main_issue)
                # Set project for compatibility with other filters
                @project = attachment_issue.project
                return true # Access granted.
              end
            end
          end
        end

        # If token logic doesn't grant access, or doesn't apply,
        # fall back to the standard Redmine authorization check.
        super
      end
    end
  end
end 
