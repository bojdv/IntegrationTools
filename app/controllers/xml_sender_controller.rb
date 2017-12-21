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
    select_manager = QueueManager.find(params[:manager_name][:id])
    respond_to do |format|
      format.js { render :js => "changeText(\"#{select_manager.queue}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\");" }
    end
  end
end