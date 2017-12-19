Rails.application.routes.draw do
  post '/xmlsender/sendd' => 'xml_senders#sendd'
  root 'xml_senders#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
