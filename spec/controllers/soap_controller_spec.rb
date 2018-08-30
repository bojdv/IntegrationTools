require 'rails_helper'

RSpec.describe SoapController, type: :controller do

  describe "GET #tester" do
    it "returns http success" do
      get :tester
      expect(response).to have_http_status(:success)
    end
  end

end
