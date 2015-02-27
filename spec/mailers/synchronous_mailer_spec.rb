require "spec_helper"

describe SynchronousMailer do

  describe "with only default args" do

    let(:mail) { SynchronousMailer.general }

    it "renders the headers" do
      expect(mail.subject).to eq("Message from #{BASE_DOMAIN}")
      expect(mail.to).to eq(["nobody@#{BASE_DOMAIN}"])
      expect(mail.from).to eq(["noreply@#{BASE_DOMAIN}"])
    end

    it "should render a multipart message by default" do
      expect(mail.body.encoded).to match "----==_mimepart_"
    end

    it "renders both a plaintext and an HTML version" do
      ignore, plaintext, html = mail.body.encoded.split(/\r\n----==_mimepart_.+?\r\n\r\n/m)
      expect(plaintext).to eq("Body is empty.")
      expect(html).to include "<p>Body is empty.</p>"
    end
  end


  describe "given just a plaintext message should create an HTML version too" do

    let(:mail) { SynchronousMailer.general plaintext: "Size *does* matter. _Right_?" }

    it "renders both the supplied plaintext verbatim and a Kramdown HTML version" do
      ignore, plaintext, html = mail.body.encoded.split(/\r\n----==_mimepart_.+?\r\n\r\n/m)
      expect(plaintext).to eq("Size *does* matter. _Right_?")
      expect(html).to include "<p>Size <em>does</em> matter. <em>Right</em>?</p>"
    end
  end


  describe "given just an HTML message should create a plain text version too" do

    let(:mail) { SynchronousMailer.general html: "<p><b>NOBODY</b> knows.</p><p>(But you.)</p>" }

    it "renders both the supplied plaintext verbatim and a Kramdown HTML version" do
      ignore, plaintext, html = mail.body.encoded.split(/\r\n----==_mimepart_.+?\r\n\r\n/m)
      expect(plaintext).to eq("NOBODY knows.\r\n\r\n(But you.)")
      expect(html).to include "<p><b>NOBODY</b> knows.</p><p>(But you.)</p>"
    end
  end


  describe "given both plaintext and html should preserve both" do

    let(:mail) { SynchronousMailer.general plaintext: "Foo", html: "<p>Foo</p><p>(extra)</p>" }

    it "renders both the supplied plaintext verbatim and a Kramdown HTML version" do
      ignore, plaintext, html = mail.body.encoded.split(/\r\n----==_mimepart_.+?\r\n\r\n/m)
      expect(plaintext).to eq("Foo")
      expect(html).to include "<p>Foo</p><p>(extra)</p>"
    end
  end

end
