# Require hook listener
# require_dependency 'redmine_public_preview/hooks' # Old way
require File.join(File.dirname(__FILE__), 'lib', 'redmine_public_preview', 'hooks')
require 'logger'

# Log message to indicate the init.rb file is being loaded
Rails.logger.info "[PublicPreviewPlugin] Loading init.rb of redmine_public_preview plugin"

# Direct patch to AttachmentsController - We do this directly in init.rb for reliability
require_dependency 'attachments_controller'

# Only execute this code if AttachmentsController is defined and available
if defined?(AttachmentsController)
  Rails.logger.info "[PublicPreviewPlugin] Found AttachmentsController, patching read_authorize..."
  
  # Apply the patch to AttachmentsController
  AttachmentsController.class_eval do
    # Store a reference to the original method first
    alias_method :read_authorize_without_public_preview, :read_authorize
    
    # Define new implementation that checks for public preview tokens
    def read_authorize
      token_value = params[:public_preview_token]
      
      if token_value.present? && @attachment && 
         @attachment.container_type == 'Issue' && @attachment.container_id.present?
        
        # Look for a valid token for this issue
        public_token = PublicPreviewToken.find_by(
          value: token_value, 
          issue_id: @attachment.container_id
        )
        
        # If token exists and is not expired, allow access
        if public_token && public_token.expires_at > Time.current
          Rails.logger.debug "[PublicPreviewPlugin] Granting access to attachment via public preview token"
          return true
        end
      end
      
      # Fall back to the original method if no valid token
      read_authorize_without_public_preview
    end
    
    Rails.logger.info "[PublicPreviewPlugin] Successfully patched read_authorize method"
  end
else
  Rails.logger.warn "[PublicPreviewPlugin] AttachmentsController not found! Cannot patch."
end

# Đăng ký JavaScript assets - cách thức đúng cho Redmine 5 (Rails 6+)
# Cách này chỉ áp dụng khi plugin của bạn có thư mục assets
Rails.application.config.to_prepare do
  path = File.join(File.dirname(__FILE__), 'assets', 'javascripts')
  Redmine::Plugin.register :redmine_public_preview do
    requires_redmine version_or_higher: '5.0.0'
  end
end

# Register the plugin with Redmine
Redmine::Plugin.register :redmine_public_preview do
  name 'Redmine Public Issue Preview Plugin'
  author 'tuandbe'
  description 'Allows generating a time-limited public preview link for issues.'
  version '0.0.1'
  url 'https://github.com/tuandbe/redmine_public_preview'
  author_url 'https://github.com/tuandbe/redmine_public_preview'
  requires_redmine version_or_higher: '5.0.0'

  # Plugin settings (configuration page in admin)
  settings default: { 'trackers' => [] }, partial: 'settings/public_preview_settings'

  # Permission to generate public preview links
  # This will be checked in PublicIssuePreviewsController#generate
  # and in the hook to decide whether to display the button
  project_module :issue_tracking do # Attach to the existing issue_tracking module or create a new one
    permission :generate_public_issue_previews, { public_issue_previews: [:generate] }, require: :member
  end

  # If you want to create a separate project module for this plugin:
  # project_module :public_issue_preview_module do |map|
  #   map.permission :generate_public_issue_previews, { public_issue_previews: [:generate] }, require: :member
  # end
end

# Ensure the patches and assets are loaded correctly
Rails.application.config.to_prepare do
  # Require the patch file here, inside to_prepare, to ensure it reloads in development
  require_dependency File.join(File.dirname(__FILE__), 'lib', 'redmine_public_preview', 'patches', 'attachments_controller_patch')

  # Apply the patch
  Rails.logger.info "[PublicPreviewInit] In Rails.application.config.to_prepare block for applying AttachmentsControllerPatch (init.rb)"
  unless AttachmentsController.included_modules.include?(RedminePublicPreview::Patches::AttachmentsControllerPatch)
    AttachmentsController.prepend(RedminePublicPreview::Patches::AttachmentsControllerPatch)
    Rails.logger.info "[PublicPreviewInit] AttachmentsControllerPatch prepended to AttachmentsController via init.rb."
  else
    Rails.logger.info "[PublicPreviewInit] AttachmentsControllerPatch already included in AttachmentsController (checked in init.rb)."
  end
end

# Final message to confirm init.rb completed
Rails.logger.info "[PublicPreviewPlugin] Completed loading redmine_public_preview plugin"
