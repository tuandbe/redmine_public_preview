module RedminePublicPreview
  class Hooks < Redmine::Hook::ViewListener
    # Add JS files to the header
    def view_layouts_base_html_head(context={})
      # Trả về trực tiếp thẻ script với plugin path
      javascript_include_tag('subtask_creator', plugin: 'redmine_public_preview')
    end
    
    # Hook to add a button to the issue details
    # You might need to find a more suitable hook, e.g.:
    # :view_issues_show_details_bottom
    # :view_issues_show_description_bottom
    # :view_issues_sidebar_queries_bottom
    # Or a hook in the operations buttons area (requires checking Redmine source code)
    # Temporarily using view_issues_show_details_bottom
    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      project = context[:project]
      view_context = context[:controller].view_context # Access to view helpers like link_to, url_for, l, etc.

      # Check if this issue's tracker is enabled in settings
      settings = Setting.plugin_redmine_public_preview
      allowed_tracker_ids = settings['trackers'] || []
      
      # If trackers are configured and this issue's tracker is not allowed, don't show buttons
      if allowed_tracker_ids.present? && !allowed_tracker_ids.include?(issue.tracker_id.to_s)
        return ''
      end

      buttons_html = []

      # 1. "Generate Public Preview" button
      if User.current.allowed_to?(:generate_public_issue_previews, project)
        generate_button = view_context.link_to(
          l(:button_generate_public_preview),
          view_context.generate_public_issue_preview_token_path(issue),
          method: :post,
          class: 'icon icon-public', # Or a more appropriate icon class
          title: l(:button_generate_public_preview), # Add title for clarity
          form: { target: '_blank' } # To make the result of POST (redirect) open in a new tab
        )
        buttons_html << generate_button
      end

      # 2. "Copy Link" and optionally "Open Link" buttons if a valid token exists
      # Get the latest valid token
      latest_token = PublicPreviewToken.where(issue_id: issue.id)
                                       .where('expires_at > ?', Time.current)
                                       .order(expires_at: :desc).first

      if latest_token
        # Must use _url for a full URL including host, necessary for copying/sharing
        # Ensure default_url_options is configured correctly in Redmine (config/configuration.yml)
        # for url_for to generate absolute URLs.
        begin
          preview_url = view_context.public_issue_preview_url(issue, t: latest_token.value, protocol: Setting.protocol)
        rescue StandardError => e
          # If there's an error generating the URL (e.g., host not set), don't show copy/open buttons
          Rails.logger.error "Could not generate public_issue_preview_url: #{e.message}"
          preview_url = nil
        end

        if preview_url
          # Optional: "Open Link" button
          # open_button = view_context.link_to(
          #   '', # No text, just icon
          #   preview_url,
          #   target: '_blank',
          #   class: 'icon icon-external-link', # Icon for opening link
          #   title: l(:title_open_public_preview_link)
          # )
          # buttons_html << open_button

          # "Copy Link" button
          # Note: navigator.clipboard.writeText requires HTTPS or localhost to work securely in many browsers.
          # Redmine.flash is a Redmine JavaScript helper to display notifications.
          copy_script = "navigator.clipboard.writeText('#{view_context.j(preview_url)}').then(() => { Redmine.flash('notice', '#{view_context.j(l(:notice_public_preview_link_copied))}'); }, () => { Redmine.flash('error', '#{view_context.j(l(:error_public_preview_link_copy_failed))}'); }); return false;"
          copy_button = view_context.link_to(
            '', # No text, just icon
            '#', # href is not important due to onclick
            onclick: copy_script,
            class: 'icon icon-copy', # Copy icon
            title: l(:button_copy_public_preview_link),
            style: 'margin-left: 5px;' # Add some spacing if multiple buttons are present
          )
          buttons_html << copy_button
        end
      end

      # 3. "Create Sub-task" button for design orders
      if User.current.allowed_to?(:add_issues, project)
        # Check if the issue has the necessary custom fields
        brief_field = issue.custom_field_values.find { |cfv| cfv.custom_field.name == 'Brief ảnh Od' }
        designer_field = issue.custom_field_values.find { |cfv| cfv.custom_field.name == 'Designer' }
        design_date_field = issue.custom_field_values.find { |cfv| cfv.custom_field.name == 'Design Date' }
        
        # Log the custom fields we found for debugging
        Rails.logger.debug "Found custom fields: Brief=#{brief_field&.custom_field&.id}, Designer=#{designer_field&.custom_field&.id}, DesignDate=#{design_date_field&.custom_field&.id}"
        
        # Create a JavaScript function to check if Brief field has content
        check_script = <<~JAVASCRIPT
          function checkBriefAndCreateSubtask() {
            var briefField = #{brief_field && !brief_field.value.to_s.empty? ? 'true' : 'false'};
            if (!briefField) {
              Redmine.flash('error', '#{view_context.j(l(:error_brief_required))}');
              return false;
            }
            return true;
          }
        JAVASCRIPT
        
        # Add the script to the page
        buttons_html << view_context.javascript_tag(check_script)
        
        # Thay thế cách lưu data-attributes để đảm bảo chúng được render đúng cách trong HTML
        html_options = {
          class: 'icon icon-add subtask-creator-button',
          title: l(:title_create_design_subtask),
          onclick: 'return checkBriefAndCreateSubtask();'
        }
        
        # Thiết lập data-attributes trực tiếp như HTML attributes - bao gồm cả giá trị
        html_options['data-parent-id'] = issue.id
        html_options['data-parent-subject'] = issue.subject
        
        # Thêm ID và giá trị của các trường tùy chỉnh
        if brief_field&.custom_field
          html_options['data-brief-field-id'] = brief_field.custom_field.id 
          html_options['data-brief-value'] = brief_field.value.to_s
        end
        
        if designer_field&.custom_field
          html_options['data-designer-field-id'] = designer_field.custom_field.id
          
          # Nếu giá trị của designer là một ID người dùng, tìm tên hiển thị của người dùng đó
          designer_value = designer_field.value.to_s
          
          # Nếu có thể chuyển đổi sang số (có thể là ID người dùng)
          if designer_value.to_i.to_s == designer_value
            user = User.find_by(id: designer_value.to_i)
            if user
              # Sử dụng tên hiển thị của người dùng
              designer_value = user.name
              Rails.logger.debug "Found designer user: #{user.name} (ID: #{user.id})"
            end
          end
          
          html_options['data-designer-value'] = designer_value
        end
        
        if design_date_field&.custom_field
          html_options['data-design-date-field-id'] = design_date_field.custom_field.id
          html_options['data-design-date-value'] = design_date_field.value.to_s
        end
        
        # Tìm tracker "Od Ảnh" trong project
        # TODO: Thêm cấu hình tracker trong admin
        od_anh_tracker = Tracker.find_by(name: 'Od Ảnh')
        tracker_id = od_anh_tracker&.id
        
        if tracker_id
          Rails.logger.debug "Found Od Ảnh tracker with ID: #{tracker_id}"
        else
          Rails.logger.debug "Tracker 'Od Ảnh' not found, using default tracker"
        end
        
        # Tạo URL với tham số issue[tracker_id] nếu tìm thấy
        new_issue_params = {
          project_id: project.identifier,
          issue: {
            parent_issue_id: issue.id,
            subject: "#{l(:subtask_order_prefix)} - #{issue.subject}"
          }
        }
        
        # Thêm tracker_id nếu tìm thấy
        new_issue_params[:issue][:tracker_id] = tracker_id if tracker_id
        
        create_subtask_button = view_context.link_to(
          l(:button_create_subtask),
          view_context.new_project_issue_path(new_issue_params),
          html_options
        )
        buttons_html << create_subtask_button
      end

      return buttons_html.join('&nbsp;').html_safe if buttons_html.any?
      ''
    rescue StandardError => e
      Rails.logger.error "Error in RedminePublicPreview hook (view_issues_show_details_bottom): #{e.message} Backtrace: #{e.backtrace.join("\n")}"
      return ''
    end
  end
end 
 