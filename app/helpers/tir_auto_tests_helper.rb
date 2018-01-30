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
      send_to_log("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}, Очередь:#{manager.queue_out}")
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
      send_to_log("Получили ответ от ТИР из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили ответ от ТИР")
      return xml_actual.getText
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}")
      return nil
    ensure
      sender.close if sender
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end

    def send_to_amq(manager, xml, queue = manager.queue_out) # Отправка сообщений в Active MQ по протоколу OpenWire
      java_import 'org.apache.activemq.ActiveMQConnectionFactory'
      java_import 'javax.jms.Session'
      java_import 'javax.jms.TextMessage'
      puts 'Sending message to AMQ (OpenWire)'
      begin
        factory = ActiveMQConnectionFactory.new
        send_to_log("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}, Очередь:#{queue}")
        factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
        manager.user.nil? ? user ='' : user=manager.user
        manager.password.nil? ? password ='' : password=manager.user
        connection = factory.createQueueConnection(user, password)
        session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
        if xml.is_a? String
          textMessage = session.createTextMessage(xml)
        else
          textMessage = session.createTextMessage(xml.xml_text)
        end
        textMessage.setJMSCorrelationID(SecureRandom.uuid)
        sender = session.createSender(session.createQueue(queue))
        connection.start
        connection.destroyDestination(session.createQueue(manager.queue_in)) # Удаляем очередь.
        sender.send(textMessage)
        send_to_log("Отправили сообщение в ТИР:\n #{textMessage.getText}", "Отправили сообщение в ТИР")
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}")
        return nil
      ensure
        sender.close if sender
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
      send_to_log("Получили ответ от ТИР из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили ответ от ТИР")
      return xml_actual.getText
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}")
      return nil
    ensure
      receiver.close if receiver
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
  def add_test_data_in_db
    java_import 'oracle.jdbc.OracleDriver'
    java_import 'java.sql.DriverManager'

    jmsAdapterSettingsTemplate = Document.new(File.open('lib/tir_db_data/jmsAdapterSettingsTemplate.xml'){|file| file.read})
    jmsSettingsTemplate = Document.new(File.open('lib/tir_db_data/jmsSettingsTemplate.xml'){|file| file.read})
    fileSettingsTemplate = Document.new(File.open('lib/tir_db_data/fileSettingsTemplate.xml'){|file| file.read})
    dbAdapterSettingsTemplate = Document.new(File.open('lib/tir_db_data/dbAdapterSettingsTemplate.xml'){|file| file.read})
    httpSettingsTemplate = Document.new(File.open('lib/tir_db_data/httpSettingsTemplate.xml'){|file| file.read})
    httpAdapterSettingsTemplate = Document.new(File.open('lib/tir_db_data/httpAdapterSettingsTemplate.xml'){|file| file.read})

    activeMQListner = Document.new(File.open('lib/tir_db_data/[AutoTest] ActiveMQListner.xml'){|file| file.read})


    url = "jdbc:oracle:thin:@vm-corint:1521:corint"
    connection = java.sql.DriverManager.getConnection(url, "tir_test", "tir_test");
    select_stmt = connection.create_statement

    select_stmt.executeUpdate("insert into sys_properties (name, value) values ('jmsAdapterSettingsTemplate.xml', q'[#{jmsAdapterSettingsTemplate}]')")
    select_stmt.executeUpdate("insert into sys_properties (name, value) values ('jmsSettingsTemplate.xml', q'[#{jmsSettingsTemplate}]')")
    select_stmt.executeUpdate("insert into sys_properties (name, value) values ('dbAdapterSettingsTemplate.xml', q'[#{dbAdapterSettingsTemplate}]')")
    select_stmt.executeUpdate("insert into sys_properties (name, value) values ('fileSettingsTemplate.xml', q'[#{fileSettingsTemplate}]')")
    select_stmt.executeUpdate("insert into sys_properties (name, value) values ('httpSettingsTemplate.xml', q'[#{httpSettingsTemplate}]')")
    select_stmt.executeUpdate("insert into sys_properties (name, value) values ('httpAdapterSettingsTemplate.xml', q'[#{httpAdapterSettingsTemplate}]')")

    select_stmt.executeUpdate("insert into deployments (id, name, src, version) values ('85376884-9d6d-4e8f-a777-243886f829a1', 'AutoTests/[AutoTest] ActiveMQListner', q'[#{activeMQListner}]', 'd9a6234b-1fc9-420c-a48e-fade75667d94')")
    query = %Q{DECLARE
v_long_text CLOB;
BEGIN
v_long_text := q'[#{tir_amq_settings}]';
update sys_properties
set value = v_long_text
where name = 'jmsAdapterSettingsTemplate.xml';
END;}
    select_stmt.close
    connection.close
  end
end
