class XmlSendersController < ApplicationController
  def index
  end
  def sendd
    client = Stomp::Client.new('admin', 'admin', 'localhost', '61613')
    client.publish("/queue/test_in", params[:user][:xml]) #Кидаем запрос в очередь
    client.close
    puts "Сообщение отправлено в очередь"
  end
end
