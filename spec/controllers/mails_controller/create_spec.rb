require 'spec_helper'

describe MailsController do
  
  render_views
  
  describe "POST create" do
    
    before :each do
      permit_with 200
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "incredibly-fake!"
      @args = {from: "the-sender@example.com", 
               to: "the-recipient@example.com", 
               subject: "Welcome, tester", 
               plaintext: "This is the body of the email."}
    end
    
    
    it "should return JSON" do
      Api.should_receive(:request).and_return(double(headers: {}, body: {'async_job' => {}}))
      post :create, @args
      response.content_type.should == "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      post :create, @args
      response.status.should == 400
    end
    
    it "should return a 400 if the authentication represented by the X-API-Token can't be found" do
      request.headers['X-API-Token'] = 'unknown, matey'
      Api.stub(:permitted?).and_return(double(:status => 400, :body => {:_api_error => []}))
      post :create, @args
      response.status.should == 400
      response.content_type.should == "application/json"
    end

    it "should return a 403 if the X-API-Token doesn't yield POST authorisation for Mails" do
      Api.stub(:permitted?).and_return(double(:status => 403, :body => {:_api_error => []}))
      post :create, @args
      response.status.should == 403
      response.content_type.should == "application/json"
    end

    it "should return a 422 when there are validation errors" do
      post :create, @args.merge(:to => nil)
      response.status.should == 422
      response.content_type.should == "application/json"
      JSON.parse(response.body).should == {"to"=>["is required"]}
    end
                
    it "should return a 202 when successful" do
      Api.should_receive(:request).with("#{INTERNAL_OCEAN_API_URL}/#{ASYNC_JOB_VERSION}/async_jobs",
                                        'POST', body: an_instance_of(String)
                                       ).and_return(double(headers: {}, body: {'async_job' => {}}))
      post :create, @args
      response.status.should == 202
    end

    it "should pass on the Location header from the AsyncJob response when successful" do
      Api.should_receive(:request).and_return(double(headers: {'Location' => 'blahonga'}, body: {'async_job' => {}}))
      post :create, @args
      response.headers['Location'].should == 'blahonga'
    end

    it "should return the AsyncJob in the body when successful" do
      Api.should_receive(:request).and_return(double(headers: {}, body: {'async_job' => {'foo' => 1, 'bar' => 2}}))
      post :create, @args
      j = JSON.parse(response.body)
      j['async_job'].should == {'foo' => 1, 'bar' => 2}
    end    

    it "should check the response from AsyncJob for timeout"
    it "should check the response from AsyncJob for status code errors"
    
  end
  
end
