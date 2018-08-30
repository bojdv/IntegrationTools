class SoapController < ApplicationController

  soap_service namespace: 'urn:WashOut'
  soap_action "tester",
              :args   => { :a => :string},
              :return => {:xml => :string}
  def tester
    text = "WAAAA"
    render :soap => {:xml => text}
  end

  soap_action "integer_to_header_string",
              :args   => :integer,
              :return => :string,
              :header_return => :string
  def integer_to_header_string
    render :soap => params[:value].to_s, :header => (params[:value]+1).to_s
  end

end
