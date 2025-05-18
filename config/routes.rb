# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
  # Route to generate the link (button will POST here)
  # /issues/:issue_id/public_preview/generate
  post 'issues/:issue_id/public_preview/generate', to: 'public_issue_previews#generate', as: 'generate_public_issue_preview_token'

  # Route to view the public preview page
  # /issues/:issue_id/public_preview?t=TOKEN
  get 'issues/:issue_id/public_preview', to: 'public_issue_previews#show', as: 'public_issue_preview'
end
