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
    SyncMail.new(@h).should be_a SyncMail
  end

  it "should require to" do
    m = SyncMail.new(@h.except :to)
    m.should_not be_valid
    m.errors[:to].should == ["is required"]
  end

  it "should require subject" do
    m = SyncMail.new(@h.except :subject)
    m.should_not be_valid
    m.errors[:subject].should == ["can't be blank"]
  end

  it "should require from, if present, to be a correct email address" do
    @h[:from] = "clearly@not@correct"
    m = SyncMail.new(@h)
    m.should_not be_valid
    m.errors[:from].should == ["is an invalid email address"]
  end

  it "should require to to be a correct email address" do
    @h[:to] = "clearly@not@correct"
    m = SyncMail.new(@h)
    m.should_not be_valid
    m.errors[:to].should == ["is an invalid email address"]
  end

  it "should require one or more of plaintext, html, plaintext_url, or html_url to be present" do
    @h[:plaintext] = nil
    @h[:html] = nil
    @h[:plaintext_url] = nil
    @h[:html_url] = nil
    m = SyncMail.new(@h)
    m.should_not be_valid
    m.errors[:base].should == ["must have text in plaintext, html, plaintext_url, or html_url"]
  end


  describe "#to_async_job_post_body_hash" do

    it "should return a hash" do
      SyncMail.new(@h).to_async_job_post_body_hash('').should be_a Hash
    end

    it "should contain encoded credentials as a string" do
      cred = SyncMail.new(@h).to_async_job_post_body_hash('')['credentials']
      cred.should be_a String
      cred.should == Api.credentials(API_USER, API_PASSWORD)
    end

    it "should contain the token argument" do
      token = SyncMail.new(@h).to_async_job_post_body_hash('the-token')['token']
      token.should == 'the-token'
    end

    it "should contain an array of one job step" do
      steps = SyncMail.new(@h).to_async_job_post_body_hash('')['steps']
      steps.should be_an Array
      steps.length.should == 1
      steps.each { |step| step.should be_a Hash }
    end


    describe "the job step" do

      before :each do
        @step = SyncMail.new(@h).to_async_job_post_body_hash('')['steps'].first
      end

      it "should have an URL to the mails#send action" do
        @step['url'].should == Rails.application.routes.url_helpers.send_mails_url(host: INTERNAL_OCEAN_API_URL)
      end

      it "should be a POST" do
        @step['method'].should == 'POST'
      end

      it "should have a maximum step time" do
        @step['step_time'].should == EMAIL_STEP_TIME
      end

      it "should have a poison limit" do
        @step['poison_limit'].should == EMAIL_POISON_LIMIT
      end

      it "should have a retry base" do
        @step['retry_base'].should == EMAIL_RETRY_BASE
      end

      it "should have a retry multiplier" do
        @step['retry_multiplier'].should == EMAIL_RETRY_MULTIPLIER
      end

      it "should have a retry exponent" do
        @step['retry_exponent'].should == EMAIL_RETRY_EXPONENT
      end


      describe "POST body" do

        it "should be a Hash" do
          @step['body'].should be_a Hash
        end

        it "should have a from key" do
          @step['body']['from'].should be_a String
        end

        it "should have a to key" do
          @step['body']['to'].should be_a String
        end

        it "should have a subject key" do
          @step['body']['subject'].should be_a String
        end

        it "should have a plaintext key" do
          @step['body']['plaintext'].should be_a String
        end

        it "should have a html key" do
          @step['body']['html'].should be_a String
        end

        it "should have a plaintext_url key" do
          @step['body']['plaintext_url'].should be_a String
        end

        it "should have a html_url key" do
          @step['body']['html_url'].should be_a String
        end

        it "should have a substitutions key" do
          @step['body']['substitutions'].should be_a Hash
        end
      end
    end

  end


  describe "#deliver" do

    it "should call the mailer" do
      SynchronousMailer.should_receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"This is the body of the email.", 
              :html=>"<p>This is the body of the email.</p>"}).
        and_return(double("SynchronousMailer", :deliver => true) )
      SyncMail.new(@h).deliver
    end

    it "should perform any substitutions before delivery" do
      @h['plaintext'] = "This is the body of the email. Do you have a body?"
      @h['html'] = "<p>This is the body of the email. Do you have a body?</p>"
      @h['substitutions'] = {"body" => "corpus", 
                             "tester" => "customer"}
      SynchronousMailer.should_receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, customer", 
              :plaintext=>"This is the corpus of the email. Do you have a corpus?", 
              :html=>"<p>This is the corpus of the email. Do you have a corpus?</p>"}).
        and_return(double("SynchronousMailer", :deliver => true))
      SyncMail.new(@h).deliver
    end

    it "should obtain any plaintext_url text if present" do 
      @h['plaintext'] = nil
      @h['plaintext_url'] = "http://api.example.com/v1/texts/something/something/something"
      expect(Api::RemoteResource).to receive(:get).with(@h['plaintext_url']).
        and_return({'result' => 'Dynamic text rules.'})
      SynchronousMailer.should_receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"Dynamic text rules.", 
              :html=>"<p>This is the body of the email.</p>"}).
        and_return(double("SynchronousMailer", :deliver => true))
      SyncMail.new(@h).deliver
    end

    it "should obtain any html_url text if present, using html if markdown is true" do
      @h['html'] = nil
      @h['html_url'] = "http://api.example.com/v1/texts/something/something/something"
      expect(Api::RemoteResource).to receive(:get).with(@h['html_url']).
        and_return({'markdown' => true, 'html' => '<p>Be <b>BOLD</b>!</p>'})
      SynchronousMailer.should_receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"This is the body of the email.", 
              :html=>"<p>Be <b>BOLD</b>!</p>"}).
        and_return(double("SynchronousMailer", :deliver => true))
      SyncMail.new(@h).deliver
    end

    it "should obtain any html_url text if present, using result if markdown is false" do
      @h['html'] = nil
      @h['html_url'] = "http://api.example.com/v1/texts/something/something/something"
      expect(Api::RemoteResource).to receive(:get).with(@h['html_url']).
        and_return({'markdown' => false, 'result' => '<p>This is HTML stored as plaintext</p>'})
      SynchronousMailer.should_receive(:general).
        with({:from=>"the-sender@example.com", :to=>"the-recipient@example.com", 
              :subject=>"Welcome, tester", 
              :plaintext=>"This is the body of the email.", 
              :html=>"<p>This is HTML stored as plaintext</p>"}).
        and_return(double("SynchronousMailer", :deliver => true))
      SyncMail.new(@h).deliver
    end

    it "should log and re-raise any exception encountered during delivery" do
      m = SyncMail.new(@h)
      dbl = double
      allow(dbl).to receive(:deliver).and_raise RuntimeError, "Boom"
      SynchronousMailer.should_receive(:general).and_return(dbl)
      expect(Rails.logger).to receive(:warn).
        with("Exception when sending email from 'the-sender@example.com' to 'the-recipient@example.com': 'Boom'")
      expect { m.deliver }.
        to raise_error(RuntimeError, "Boom")
    end

  end

end
