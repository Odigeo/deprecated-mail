class SynchronousMailer < ActionMailer::Base

  # 
  # This sends an email synchronously.
  #
  # If both plaintext and html are given, both will be preserved as they are. 
  # If only plaintext is given, Kramdown will be used to create the html version.
  # If only html is given, HtmlToPlanText will be used to create a plaintext version.
  # If neither plaintext nor html is given, a "Body is empty" message will be used
  # for both plaintext and html.
  #
  def general(from:      "noreply@#{BASE_DOMAIN}", 
              to:        "nobody@#{BASE_DOMAIN}",
              subject:   "Message from #{BASE_DOMAIN}",
              plaintext: nil, 
              html:      nil)
    @plaintext = plaintext || (html && HtmlToPlainText.plain_text(html)) || "Body is empty." 
    @html = html || Kramdown::Document.new(@plaintext).to_html
    mail from: from, to: to, subject: subject
  end

end


