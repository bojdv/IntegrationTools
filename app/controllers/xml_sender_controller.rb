class XmlSenderController < ApplicationController
  def index
    @manager = QueueManager.all
  end
  def send_to_queue
    client = Stomp::Client.new('admin', 'admin', 'localhost', '61613')
    client.publish("/queue/test_in", params[:user][:xml]) #Кидаем запрос в очередь
    client.close
    puts "Сообщение отправлено в очередь"
  end
end
