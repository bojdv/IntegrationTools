Rails.application.routes.draw do
  get 'product' => 'product#index'
  get '/xml_sender/new' => 'xml_sender#new'
  post '/xml_sender/send_to_queue' => 'xml_sender#send_to_queue'
  post '/xml_sender/manager_choise' => 'xml_sender#manager_choise'
  post '/xml_sender/get_xml_by_product' => 'xml_sender#get_xml_by_product'
  post '/xml_sender/put_xml' => 'xml_sender#put_xml'
  post '/xml_sender/create_xml' => 'xml_sender#create_xml'
  get '/xml_sender' => 'xml_sender#index'
  post '/xml_sender/tester' => 'xml_sender#tester'

  root 'main_page#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
