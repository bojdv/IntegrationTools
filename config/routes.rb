Rails.application.routes.draw do
  get 'tir_auto_tests/index'

  get 'simple_tests/index'

  get 'sessions/new'
  get 'users/new'
  get 'product' => 'product#index'
  get '/xml_sender/new' => 'xml_sender#new'
  post '/xml_sender/new' => 'xml_sender#new'
  post '/xml_sender/send_to_queue' => 'xml_sender#send_to_queue'
  post '/xml_sender/manager_choise' => 'xml_sender#manager_choise'
  post '/xml_sender/get_xml_by_product' => 'xml_sender#get_xml_by_product'
  post '/xml_sender/put_xml' => 'xml_sender#put_xml'
  post '/xml_sender/create_xml' => 'xml_sender#create_xml'
  get '/xml_sender' => 'xml_sender#index'
  post '/xml_sender/tester' => 'xml_sender#tester'
  post '/xml_sender/redirect_to_new' => 'xml_sender#redirect_to_new'
  post '/xml_sender/delete_xml' => 'xml_sender#delete_xml'
  post '/xml_sender/save_xml' => 'xml_sender#save_xml'
  post '/xml_sender/get_message' => 'xml_sender#get_message'
  post '/xml_sender/create_category' => 'xml_sender#create_category'
  post '/xml_sender/delete_category' => 'xml_sender#delete_category'
  post '/xml_sender/edit_category' => 'xml_sender#edit_category'
  post '/xml_sender/crud_mq_settings' => 'xml_sender#crud_mq_settings'
  post '/xml_sender/validate_xml' => 'xml_sender#validate_xml'
  post '/xml_sender/add_prefix' => 'xml_sender#add_prefix'
  post '/xml_sender/requests_from_browser' => 'xml_sender#requests_from_browser'
  get 'signup' => 'users#new'
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  # Simple Tests
  get '/simple_tests' => 'simple_tests#index'
  post '/simple_tests/put_simple_test' => 'simple_tests#put_simple_test'
  post '/simple_tests/run_simpleTest' => 'simple_tests#run_simpleTest'

  # TIR Auto Tests
  get '/tir_auto_tests' => 'tir_auto_tests#index'
  post '/tir_auto_tests/run' => 'tir_auto_tests#run'

  resources :users

  root 'main_page#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
