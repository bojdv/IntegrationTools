Rails.application.routes.draw do
  post '/xml_sender/send_to_queue' => 'xml_sender#send_to_queue'
  get '/xml_sender' => 'xml_sender#index'
  root 'main_page#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
