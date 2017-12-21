class XmlSenderController < ApplicationController
  def index
    @qm = QueueManager.all
  end
  def send_to_queue
    client = Stomp::Client.new(
        params[:mq_attributes][:user],
        params[:mq_attributes][:password],
        params[:mq_attributes][:host],
        params[:mq_attributes][:port])
    client.publish("/queue/test_in", params[:mq_attributes][:xml]) #Кидаем запрос в очередь
    client.close
  end
  def manager_choise
    (function() {

      this.test = function() {
        return alert('Hello world');
      };

    }).call(this);
  end
end