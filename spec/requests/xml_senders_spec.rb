require 'spec_helper'

describe "XML Sender" do
  subject { page }
  describe "Home page" do
    before {visit xmlsender_path}

    it { should have_content('XmlSenders') }
    it { should have_title("IntegrationUI") }
  end
end
