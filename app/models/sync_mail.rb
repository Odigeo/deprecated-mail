class SyncMail

  include ActiveModel::Model

  attr_accessor :from, :to, :subject, :plaintext, :html, 
                :plaintext_url, :html_url,
                :substitutions

  validate :has_message_text

  def has_message_text
    if plaintext.blank? && html.blank? && plaintext_url.blank? && html_url.blank?
      errors[:base] << "must have text in plaintext, html, plaintext_url, or html_url"
    end
  end

  validates :to, presence: { message: "is required" }
  validates :subject, presence: true

  validates :from, email: { message: "is an invalid email address" }, allow_blank: true
  validates :to,   email: { message: "is an invalid email address" }, allow_blank: true


  def to_async_job_post_body_hash(token)
    { 'credentials' => Api.credentials(API_USER, API_PASSWORD),
      'token' => token,
      'steps' => [{ 'step_time' => EMAIL_STEP_TIME,
                    'poison_limit' => EMAIL_POISON_LIMIT,
                    'retry_base' => EMAIL_RETRY_BASE,
                    'retry_multiplier' => EMAIL_RETRY_MULTIPLIER,
                    'retry_exponent' => EMAIL_RETRY_EXPONENT,
                    'url' => Rails.application.routes.url_helpers.send_mails_url(host: INTERNAL_OCEAN_API_URL),
                    'method' => 'POST',
                    'body' => { 'from' => from,
                                'to' => to,
                                'subject' => subject,
                                'plaintext' => plaintext,
                                'html' => html,
                                'plaintext_url' => plaintext_url,
                                'html_url' => html_url,
                                'substitutions' => substitutions                                
                              }
                  }
                 ]
    }
  end


  def deliver
    # Retrieve URLs, if present
    if plaintext.blank? && plaintext_url.present?
      rsrc = Api::RemoteResource.get(plaintext_url)
      self.plaintext = rsrc['result'] if rsrc
    end
    if html.blank? && html_url
      rsrc = Api::RemoteResource.get(html_url)
      if rsrc
        self.html = rsrc['markdown'] ? rsrc['html'] : rsrc['result']
      end
    end
    # Perform substitutions
    (substitutions || {}).each do |k, v|
      subject.gsub! k, v if subject
      plaintext.gsub! k, v if plaintext
      html.gsub! k, v if html
    end
    # Send it
    SynchronousMailer.general(from: from, to: to, subject: subject,
                              plaintext: plaintext, html: html).deliver_now
  end

end
