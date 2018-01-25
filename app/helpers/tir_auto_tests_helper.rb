module TirAutoTestsHelper
  def send_to_amq(manager, xml) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      textMessage = session.createTextMessage(xml.xml_text)
      sender = session.createSender(session.createQueue(manager.queue_out))
      connection.start
      connection.destroyDestination(session.createQueue(manager.queue_in)) # Удаляем очередь.
      sender.send(textMessage)
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 5
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      return xml_actual.getText
    rescue => msg
      return "#{msg.class}, #{msg.message}"
    ensure
      sender.close if session
      receiver.close if session
      session.close if session
      connection.close if connection
    end

  end
  def send_to_log(text)
    $log += "#{Time.now.strftime('%H:%M:%S')}: #{text}\n"
  end
end
