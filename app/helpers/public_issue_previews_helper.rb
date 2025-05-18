module PublicIssuePreviewsHelper
  # Modifies image URLs within the issue description to include the public preview token.
  # This allows attachments to be viewed by non-logged-in users via a valid token.
  def format_description_for_public_preview(issue_description, token_value)
    return '' if issue_description.blank? || token_value.blank?

    # Nokogiri is used by Redmine core, so it should be available.
    doc = Nokogiri::HTML.fragment(issue_description)

    doc.css('img').each do |img|
      src = img['src']
      next if src.blank? # Skip if src is empty

      # Check if the src is a Redmine attachment URL
      # Example: /attachments/download/123/image.png or http://domain.com/attachments/download/123/image.png
      if src.match?(%r{(?:/|^)attachments/download/\d+/.+})
        begin
          uri = URI.parse(src)
          # Ensure query is not nil before trying to decode it
          current_query_params = uri.query ? URI.decode_www_form(uri.query) : []
          new_query_ar = current_query_params << ["public_preview_token", token_value]
          uri.query = URI.encode_www_form(new_query_ar)
          img['src'] = uri.to_s
        rescue URI::InvalidURIError
          # Log or handle invalid URIs if necessary, but continue processing
          Rails.logger.warn "[PublicIssuePreview] Invalid URI found in image src: #{src} while processing for public preview."
        end
      end
    end

    doc.to_html.html_safe # Use html_safe as we are manipulating HTML content
  end
end
