module RedminePublicPreviewHelper
  def redmine_public_preview_javascripts
    javascript_include_tag('subtask_creator', plugin: 'redmine_public_preview')
  end
end 
