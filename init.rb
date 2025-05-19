# Require hook listener
# require_dependency 'redmine_public_preview/hooks' # Old way
require File.join(File.dirname(__FILE__), 'lib', 'redmine_public_preview', 'hooks')
require 'logger'

# Log message to indicate the init.rb file is being loaded
Rails.logger.info "[PublicPreviewPlugin] Loading init.rb of redmine_public_preview plugin"

# The following to_prepare block for assets seems problematic, especially the inner Redmine::Plugin.register call.
# Redmine typically handles asset loading through standard Rails/Sprockets conventions for plugins.
# Commenting out for now to simplify and avoid potential conflicts.
# Rails.application.config.to_prepare do
#   path = File.join(File.dirname(__FILE__), 'assets', 'javascripts')
#   # The Redmine::Plugin.register call here is likely redundant and potentially problematic.
#   # The main registration block is below.
#   # Consider removing this inner registration if it causes issues or is not strictly needed for asset loading.
#   # Redmine::Plugin.register :redmine_public_preview do
#   #   requires_redmine version_or_higher: '5.0.0'
#   # end
# end

# Register the plugin with Redmine
Redmine::Plugin.register :redmine_public_preview do |plugin|
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
  project_module :issue_tracking do
    permission :generate_public_issue_previews, { public_issue_previews: [:generate] }, require: :member
  end

  # Apply AttachmentsController patch directly during plugin registration
  begin
    patch_file_path = File.join(
      File.dirname(__FILE__),
      'lib', 
      'redmine_public_preview',
      'patches',
      'attachments_controller_patch.rb'
    )
    require_dependency patch_file_path

    patch_module = RedminePublicPreview::Patches::AttachmentsControllerPatch

    if defined?(AttachmentsController) && AttachmentsController.is_a?(Class)
      unless AttachmentsController.included_modules.include?(patch_module)
        AttachmentsController.prepend(patch_module)
        Rails.logger.info "[PublicPreviewPlugin] Successfully prepended AttachmentsControllerPatch to AttachmentsController during registration."
      else
        Rails.logger.info "[PublicPreviewPlugin] AttachmentsControllerPatch already included in AttachmentsController (checked during registration)."
      end
    else
      Rails.logger.error "[PublicPreviewPlugin] AttachmentsController is not defined or not a Class. Cannot apply patch."
    end
  rescue LoadError => e
    Rails.logger.error "[PublicPreviewPlugin] Error loading AttachmentsControllerPatch: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue NameError => e
    Rails.logger.error "[PublicPreviewPlugin] Error finding AttachmentsControllerPatch module: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue StandardError => e
    Rails.logger.error "[PublicPreviewPlugin] Unexpected error applying AttachmentsControllerPatch: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  end
end

# Final message to confirm init.rb completed
Rails.logger.info "[PublicPreviewPlugin] Completed loading redmine_public_preview plugin"
