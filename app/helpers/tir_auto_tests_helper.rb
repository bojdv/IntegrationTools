module TirAutoTestsHelper
  def response_ajax_auto(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect}); kill_listener();"}
    end
  end
  def send_to_amq_and_receive(manager, xml) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      send_to_log("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}")
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
      send_to_log("Отправили сообщение в ТИР:\n #{textMessage.getText}", "Отправили сообщение в ТИР")
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 5
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      send_to_log("Получили ответ от ТИР:\n #{xml_actual.getText}", "Получили ответ от ТИР")
      return xml_actual.getText
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}")
      return nil
    ensure
      sender.close if session
      receiver.close if session
      session.close if session
      connection.close if connection
    end
  end

    def send_to_amq(manager, xml) # Отправка сообщений в Active MQ по протоколу OpenWire
      java_import 'org.apache.activemq.ActiveMQConnectionFactory'
      java_import 'javax.jms.Session'
      java_import 'javax.jms.TextMessage'
      puts 'Sending message to AMQ (OpenWire)'
      begin
        factory = ActiveMQConnectionFactory.new
        send_to_log("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}")
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
        send_to_log("Отправили сообщение в ТИР:\n #{textMessage.getText}", "Отправили сообщение в ТИР")
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}")
        return nil
      ensure
        sender.close if session
        session.close if session
        connection.close if connection
      end
    end

  def receive_from_amq(manager) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      send_to_log("Получаем XML из менеджера: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      connection.start
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 5
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      send_to_log("Получили ответ от ТИР:\n #{xml_actual.getText}", "Получили ответ от ТИР")
      return xml_actual.getText
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}")
      return nil
    ensure
      sender.close if session
      receiver.close if session
      session.close if session
      connection.close if connection
    end
  end

  def send_to_log(to_log, to_browser = false)
    if to_log
      if to_log.include?('Ошибка')
        $log.error(to_log)
      else
        $log.info(to_log)
      end
    end
    if to_browser
      if to_browser.include?('--')
        $browser[:message] += "#{to_browser}\n"
      else
        $browser[:message] += "[#{Time.now.strftime('%H:%M:%S')}]: #{to_browser}\n"
      end
    end
  end
  def colorize(functional, color)
    $browser[:event] = 'colorize'
    $browser[:functional] = functional
    $browser[:color] = color
  end
  def puts_line
      return '--'*40
  end
  def puts_time(startTime, endTime)
    dif = (endTime-startTime).to_i.abs
    min = dif/1.minutes
    send_to_log("Завершили проверку за: #{min} мин, #{dif-(min*1.minutes)} сек", "Завершили проверку за: #{min} мин, #{dif-(min*1.minutes)} сек")
  end
end
