class MailsController < ApplicationController

  ocean_resource_controller required_attributes: [],
                            # permitted_attributes: [:from, :to, :subject, 
                            #                        :plaintext, :html, 
                            #                        :plaintext_url, :html_url,
                            #                        :substitutions],
                            extra_actions: { 'send_sync' => ['send', "POST"]}


  #
  # POST /v1/emails
  #
  # Creates an AsyncJob to send the email asynchronously. Returns immediately.
  # This is the action to which services should interface.
  #
  def create
    @mail = SyncMail.new(params.permit(:from, :to, :subject, 
                                       :plaintext, :html, 
                                       :plaintext_url, :html_url,
                                       :substitutions))
    if @mail.valid?
      url = "#{INTERNAL_OCEAN_API_URL}/#{ASYNC_JOB_VERSION}/async_jobs"
      token = Api.service_token
      body = @mail.to_async_job_post_body_hash(token).to_json

      begin
        aj_resp = Api.request(url, 'POST', body: body, x_api_token: token)
      rescue Api::TimeoutError, Api::NoResponseError => e
        render_api_error 422, e.message
        return
      end

      response.headers['Location'] = aj_resp.headers['Location']
      render json: aj_resp.body, status: 202
    else
      render_validation_errors @mail
    end
  end


  #
  # POST /v1/emails/send
  #
  # Delivers the email synchronously, waiting for the mail server to acknowledge
  # the transmission. This action is called by the AsyncJob and thus is an internal
  # action. Consumers of the Mail service should always use POST /v1/emails.
  #
  def send_sync
    @mail = SyncMail.new(params.permit(:from, :to, :subject, 
                                       :plaintext, :html, 
                                       :plaintext_url, :html_url,
                                       :substitutions))
    if @mail.valid?
      @mail.deliver
      render_head_204
    else
      render_validation_errors @mail
    end
  end

end
