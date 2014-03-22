require 'spec_helper'

describe MailsController do
  
  render_views
  
  describe "POST send_sync" do
    
    before :each do
      permit_with 200
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "incredibly-fake!"
      @args = {from: "the-sender@example.com", 
               to: "the-recipient@example.com", 
               subject: "Welcome, tester", 
               plaintext: "This is the body of the email.",
               html: "<p><This is the body of the email./p>",
               plaintext_url: nil,
               html_url: nil,
               substitutions: nil,
              }
    end
    
    
    it "should return JSON" do
      post :send_sync, @args
      response.content_type.should == "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      post :send_sync, @args
      response.status.should == 400
    end
    
    it "should return a 400 if the authentication represented by the X-API-Token can't be found" do
      request.headers['X-API-Token'] = 'unknown, matey'
      Api.stub(:permitted?).and_return(double(:status => 400, :body => {:_api_error => []}))
      post :send_sync, @args
      response.status.should == 400
      response.content_type.should == "application/json"
    end

    it "should return a 403 if the X-API-Token doesn't yield POST authorisation for sending synchronised Mails" do
      Api.stub(:permitted?).and_return(double(:status => 403, :body => {:_api_error => []}))
      post :send_sync, @args
      response.status.should == 403
      response.content_type.should == "application/json"
    end

    it "should return a 422 when there are validation errors" do
      post :send_sync, @args.merge(:to => nil)
      response.status.should == 422
      response.content_type.should == "application/json"
      JSON.parse(response.body).should == {"to"=>["is required"]}
    end
                
    it "should return a 204 and send the mail when successful" do
      SyncMail.any_instance.should_receive(:deliver)
      post :send_sync, @args
      response.status.should == 204
    end
  end
  
end
