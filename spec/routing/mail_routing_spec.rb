require "spec_helper"

describe MailsController do
  describe "routing" do

    it "doesn't route to #index" do
      expect(get("/v1/mails")).not_to be_routable
    end

    it "doesn't route to #show" do
      expect(get("/v1/mails/1")).not_to be_routable
    end

    it "routes to #create" do
      expect(post("/v1/mails")).to route_to("mails#create")
    end

    it "routes to #send_sync" do
      expect(post("/v1/mails/send")).to route_to("mails#send_sync")
    end

    it "doesn't route to #update" do
      expect(put("/v1/mails/1")).not_to be_routable
    end

    it "doesn't route to #destroy" do
      expect(delete("/v1/mails/1")).not_to be_routable
    end

  end
end
