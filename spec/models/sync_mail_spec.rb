require 'spec_helper'

describe SyncMail do

  before :each do
    @h = {from: "the-sender@example.com", 
          to: "the-recipient@example.com", 
          subject: "Welcome, tester", 
          plaintext: "This is the body of the email.",
          html: "<p>This is the body of the email.</p>",
          plaintext_url: "http://example.com/blirg.txt",
          html_url: "http://example.com/blirg.html",
          substitutions: {}
         }
  end


  it "should be instantiatable with keyword arguments" do
    expect(SyncMail.new(@h)).to be_a SyncMail
  end

  it "should require to" do
    m = SyncMail.new(@h.except :to)
    expect(m).not_to be_valid
    expect(m.errors[:to]).to eq(["is required"])
  end

  it "should require subject" do
    m = SyncMail.new(@h.except :subject)
    expect(m).not_to be_valid
    expect(m.errors[:subject]).to eq(["can't be blank"])
  end

  it "should require from, if present, to be a correct email address" do
    @h[:from] = "clearly@not@correct"
    m = SyncMail.new(@h)
    expect(m).not_to be_valid
    expect(m.errors[:from]).to eq(["is an invalid email address"])
  end

  it "should require to to be a correct email address" do
    @h[:to] = "clearly@not@correct"
    m = SyncMail.new(@h)
    expect(m).not_to be_valid
    expect(m.errors[:to]).to eq(["is an invalid email address"])
  end

  it "should require one or more of plaintext, html, plaintext_url, or html_url to be present" do
    @h[:plaintext] = nil
    @h[:html] = nil
    @h[:plaintext_url] = nil
    @h[:html_url] = nil
    m = SyncMail.new(@h)
    expect(m).not_to be_valid
    expect(m.errors[:base]).to eq(["must have text in plaintext, html, plaintext_url, or html_url"])
  end


  describe "#to_async_job_post_body_hash" do

    it "should return a hash" do
      expect(SyncMail.new(@h).to_async_job_post_body_hash('')).to be_a Hash
    end

    it "should contain encoded credentials as a string" do
      cred = SyncMail.new(@h).to_async_job_post_body_hash('')['credentials']
      expect(cred).to be_a String
      expect(cred).to eq(Api.credentials(API_USER, API_PASSWORD))
    end

    it "should contain the token argument" do
      token = SyncMail.new(@h).to_async_job_post_body_hash('the-token')['token']
      expect(token).to eq('the-token')
    end

    it "should contain an array of one job step" do
      steps = SyncMail.new(@h).to_async_job_post_body_hash('')['steps']
      expect(steps).to be_an Array
      expect(steps.length).to eq(1)
      steps.each { |step| expect(step).to be_a Hash }
    end


    describe "the job step" do

      before :each do
        @step = SyncMail.new(@h).to_async_job_post_body_hash('')['steps'].first
      end

      it "should have an URL to the mails#send action" do
        expect(@step['url']).to eq(Rails.application.routes.url_helpers.send_mails_url(host: INTERNAL_OCEAN_API_URL))
      end

      it "should be a POST" do
        expect(@step['method']).to eq('POST')
      end

      it "should have a maximum step time" do
        expect(@step['step_time']).to eq(EMAIL_STEP_TIME)
      end

      it "should have a poison limit" do
        expect(@step['poison_limit']).to eq(EMAIL_POISON_LIMIT)
      end

      it "should have a retry base" do
        expect(@step['retry_base']).to eq(EMAIL_RETRY_BASE)
      end

      it "should have a retry multiplier" do
        expect(@step['retry_multiplier']).to eq(EMAIL_RETRY_MULTIPLIER)
      end

      it "should have a retry exponent" do
        expect(@step['retry_exponent']).to eq(EMAIL_RETRY_EXPONENT)
      end


      describe "POST body" do

        it "should be a Hash" do
          expect(@step['body']).to be_a Hash
        end

        it "should have a from key" do
          expect(@step['body']['from']).to be_a String
        end

        it "should have a to key" do
          expect(@step['body']['to']).to be_a String
        end

        it "should have a subject key" do
          expect(@step['body']['subject']).to be_a String
        end

        it "should have a plaintext key" do
          expect(@step['body']['plaintext']).to be_a String
        end

        it "should have a html key" do
          expect(@step['body']['html']).to be_a String
        end

        it "should have a plaintext_url key" do
          expect(@step['body']['plaintext_url']).to be_a String
        end

        it "should have a html_url key" do
          expect(@step['body']['html_url']).to be_a String
        end

        it "should have a substitutions key" do
          expect(@step['body']['substitutions']).to be_a Hash
        end
      end
    end

  end


  describe "#deliver" do

    it "should call the mailer" do
      expect(SynchronousMailer).to receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"This is the body of the email.", 
              :html=>"<p>This is the body of the email.</p>"}).
        and_return(double("SynchronousMailer", :deliver_now => true) )
      SyncMail.new(@h).deliver
    end

    it "should perform any substitutions before delivery" do
      @h['plaintext'] = "This is the body of the email. Do you have a body?"
      @h['html'] = "<p>This is the body of the email. Do you have a body?</p>"
      @h['substitutions'] = {"body" => "corpus", 
                             "tester" => "customer"}
      expect(SynchronousMailer).to receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, customer", 
              :plaintext=>"This is the corpus of the email. Do you have a corpus?", 
              :html=>"<p>This is the corpus of the email. Do you have a corpus?</p>"}).
        and_return(double("SynchronousMailer", :deliver_now => true))
      SyncMail.new(@h).deliver
    end

    it "should obtain any plaintext_url text if present" do 
      @h['plaintext'] = nil
      @h['plaintext_url'] = "http://api.example.com/v1/texts/something/something/something"
      expect(Api::RemoteResource).to receive(:get).with(@h['plaintext_url']).
        and_return({'result' => 'Dynamic text rules.'})
      expect(SynchronousMailer).to receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"Dynamic text rules.", 
              :html=>"<p>This is the body of the email.</p>"}).
        and_return(double("SynchronousMailer", :deliver_now => true))
      SyncMail.new(@h).deliver
    end

    it "should obtain any html_url text if present, using html if markdown is true" do
      @h['html'] = nil
      @h['html_url'] = "http://api.example.com/v1/texts/something/something/something"
      expect(Api::RemoteResource).to receive(:get).with(@h['html_url']).
        and_return({'markdown' => true, 'html' => '<p>Be <b>BOLD</b>!</p>'})
      expect(SynchronousMailer).to receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"This is the body of the email.", 
              :html=>"<p>Be <b>BOLD</b>!</p>"}).
        and_return(double("SynchronousMailer", :deliver_now => true))
      SyncMail.new(@h).deliver
    end

    it "should obtain any html_url text if present, using result if markdown is false" do
      @h['html'] = nil
      @h['html_url'] = "http://api.example.com/v1/texts/something/something/something"
      expect(Api::RemoteResource).to receive(:get).with(@h['html_url']).
        and_return({'markdown' => false, 'result' => '<p>This is HTML stored as plaintext</p>'})
      expect(SynchronousMailer).to receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"This is the body of the email.", 
              :html=>"<p>This is HTML stored as plaintext</p>"}).
        and_return(double("SynchronousMailer", :deliver_now => true))
      SyncMail.new(@h).deliver
    end

  end

end
