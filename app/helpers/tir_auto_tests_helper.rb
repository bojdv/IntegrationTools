module TirAutoTestsHelper
  def response_ajax_auto(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect}); kill_listener();"}
    end
  end
  def send_to_amq(manager, xml) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      $log.info("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логи:#{manager.user}, Пароль:#{manager.password}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      textMessage = session.createTextMessage(xml.xml_text)
      textMessage.setJMSCorrelationID(SecureRandom.uuid)
      sender = session.createSender(session.createQueue(manager.queue_out))
      connection.start
      connection.destroyDestination(session.createQueue(manager.queue_in)) # Удаляем очередь.
      sender.send(textMessage)
      send_to_log("Отправили сообщение в ТИР")
      $log.info("Отправили сообщение в ТИР:\n #{textMessage.getText}")
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 5
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      send_to_log("Получили ответ от ТИР")
      $log.info("Получили ответ от ТИР:\n #{xml_actual.getText}")
      return xml_actual.getText
    rescue Exception => msg
      $log.info(msg)
      return "#{msg.class}, #{msg.message}"
    ensure
      sender.close if session
      receiver.close if session
      session.close if session
      connection.close if connection
    end

  end
  def send_to_log(text)
    if text.include?('--')
      $browser[:message] += "#{text}\n"
    else
      $browser[:message] += "[#{Time.now.strftime('%H:%M:%S')}]: #{text}\n"
    end
  end
  def colorize(functional, color)
    $browser[:event] = 'colorize'
    $browser[:functional] = functional
    $browser[:color] = color
  end
  def puts_line
      return '--'*67
  end
  def puts_time(startTime, endTime)
    dif = (endTime-startTime).to_i.abs
    min = dif/1.minutes
    send_to_log("Завершили проверку за: #{min} мин, #{dif-(min*1.minutes)} сек")
  end
end
