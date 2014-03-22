require "spec_helper"

describe MailsController do
  describe "routing" do

    it "doesn't route to #index" do
      get("/v1/mails").should_not be_routable
    end

    it "doesn't route to #show" do
      get("/v1/mails/1").should_not be_routable
    end

    it "routes to #create" do
      post("/v1/mails").should route_to("mails#create")
    end

    it "routes to #send_sync" do
      post("/v1/mails/send").should route_to("mails#send_sync")
    end

    it "doesn't route to #update" do
      put("/v1/mails/1").should_not be_routable
    end

    it "doesn't route to #destroy" do
      delete("/v1/mails/1").should_not be_routable
    end

  end
end
