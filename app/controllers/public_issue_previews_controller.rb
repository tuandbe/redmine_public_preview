class PublicIssuePreviewsController < ApplicationController
  # Skip the global login check for the public show action
  skip_before_action :check_if_login_required, only: [:show]

  # Layout for the public preview page, will be created later
  layout 'public_preview', only: [:show]

  # Skip CSRF for the generate action if the button is GET (though POST is better)
  # Or ensure the button uses method POST and has a CSRF token
  # skip_before_action :verify_authenticity_token, only: [:generate] # Consider security implications carefully

  before_action :find_issue_for_generate, only: [:generate]
  before_action :authorize_for_generate, only: [:generate] # Check permission to create link

  # Action to generate token and redirect
  def generate
    # Delete old tokens for this issue to avoid multiple public links
    PublicPreviewToken.where(issue_id: @issue.id).destroy_all

    token_value = SecureRandom.hex(16) # Generate a random token
    expires_at = 1.week.from_now

    @preview_token = PublicPreviewToken.new(
      issue_id: @issue.id,
      value: token_value,
      expires_at: expires_at
    )

    if @preview_token.save
      # Redirect to the public preview page with the token
      redirect_to public_issue_preview_path(@issue, t: token_value)
    else
      flash[:error] = l(:notice_public_preview_link_generation_failed) # l() is Redmine's helper for I18n
      redirect_to issue_path(@issue)
    end
  end

  # Action to display the public preview page
  def show
    token_value = params[:t]
    @issue = Issue.find_by(id: params[:issue_id]) # Get issue_id from the route

    if @issue.nil?
      render_404
      return
    end

    @preview_token = PublicPreviewToken.find_by(value: token_value, issue_id: @issue.id)

    if @preview_token && @preview_token.expires_at > Time.current
      # Token is valid and not expired
      # The show.html.erb view will display @issue.description
    else
      # Token is invalid or expired
      render_error(message: l(:error_public_preview_link_invalid_or_expired), status: 403)
    end
  end

  private

  def find_issue_for_generate
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_for_generate
    # Assuming the permission is named :generate_public_issue_previews
    # And it is associated with this plugin's project module
    unless User.current.allowed_to?(:generate_public_issue_previews, @issue.project)
      render_403
    end
  end
end
