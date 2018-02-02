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
    send_to_log("Загружаем тестовые данные в БД ТИР:", "Загружаем тестовые данные в БД ТИР:")
    begin
      jmsAdapterSettingsTemplate = Document.new(File.open('lib/tir_db_data/jmsAdapterSettingsTemplate.xml'){|file| file.read})
      jmsSettingsTemplate = Document.new(File.open('lib/tir_db_data/jmsSettingsTemplate.xml'){|file| file.read})
      fileSettingsTemplate = Document.new(File.open('lib/tir_db_data/fileSettingsTemplate.xml'){|file| file.read})
      dbAdapterSettingsTemplate = Document.new(File.open('lib/tir_db_data/dbAdapterSettingsTemplate.xml'){|file| file.read})
      httpSettingsTemplate = Document.new(File.open('lib/tir_db_data/httpSettingsTemplate.xml'){|file| file.read})
      httpAdapterSettingsTemplate = Document.new(File.open('lib/tir_db_data/httpAdapterSettingsTemplate.xml'){|file| file.read})


      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      connection = java.sql.DriverManager.getConnection(url, "tir_autotest", "tir_autotest");
      stmt = connection.create_statement

      # Загружаем настройки
      stmt.executeUpdate("insert into sys_properties (name, value) values ('jmsAdapterSettingsTemplate.xml', q'[#{jmsAdapterSettingsTemplate}]')")
      stmt.executeUpdate("insert into sys_properties (name, value) values ('jmsSettingsTemplate.xml', q'[#{jmsSettingsTemplate}]')")
      stmt.executeUpdate("insert into sys_properties (name, value) values ('dbAdapterSettingsTemplate.xml', q'[#{dbAdapterSettingsTemplate}]')")
      stmt.executeUpdate("insert into sys_properties (name, value) values ('fileSettingsTemplate.xml', q'[#{fileSettingsTemplate}]')")
      stmt.executeUpdate("insert into sys_properties (name, value) values ('httpSettingsTemplate.xml', q'[#{httpSettingsTemplate}]')")
      stmt.executeUpdate("insert into sys_properties (name, value) values ('httpAdapterSettingsTemplate.xml', q'[#{httpAdapterSettingsTemplate}]')")
      send_to_log("Done! Загрузили настройки ТИР в БД", "Done! Загрузили настройки ТИР в БД")
      # Загружаем маршрут [AutoTest] ActiveMQListner.xml
      first, second = '', ''
      n=0
      IO.read('lib/tir_db_data/[AutoTest] ActiveMQListner.xml').each_char do |char|
        if n<20000
          first << char
          n+=1
        else
          second << char
        end
      end
      stmt.executeUpdate(%Q{DECLARE
                  v_long_text clob;
                  v_long_text2 clob;
               BEGIN
                  v_long_text := q'[#{first}]';
                  v_long_text2 := q'[#{second}]';
                  dbms_lob.append(v_long_text,v_long_text2);
                  insert into deployments (id, name, src, version)
                  values ('85376884-9d6d-4e8f-a777-243886f829a1', 'AutoTests/[AutoTest] ActiveMQListner', v_long_text, 'd9a6234b-1fc9-420c-a48e-fade75667d94');
                END;})
      stmt.executeUpdate("update deployments set src = REPLACE(src, ']]', ']]\"') where id = '85376884-9d6d-4e8f-a777-243886f829a1'")

      # Загружаем маршрут [AutoTest] CertGenRequest.xml
      certGenRequest = File.open('lib/tir_db_data/[AutoTest] CertGenRequest.xml'){|file| file.read}
      stmt.executeUpdate(%Q{DECLARE
                  v_long_text clob;
               BEGIN
                  v_long_text := q'[#{certGenRequest}]';
                  insert into deployments (id, name, src, version)
                  values ('03a33e3e-ba0e-4409-8aba-8c7cc4d185cd', 'AutoTests/[AutoTest] CertGenRequest', v_long_text, '88e73c78-25fd-40f9-8c1d-b5853356c30c');
                END;})
      stmt.executeUpdate("update deployments set src = REPLACE(src, ']]', ']]\"') where id = '03a33e3e-ba0e-4409-8aba-8c7cc4d185cd'")

      # Загружаем маршрут [AutoTest] DBAdapter.xml
      first, second = '', ''
      n=0
      IO.read('lib/tir_db_data/[AutoTest] DBAdapter.xml').each_char do |char|
        if n<20000
          first << char
          n+=1
        else
          second << char
        end
      end
      stmt.executeUpdate(%Q{DECLARE
                  v_long_text clob;
                  v_long_text2 clob;
               BEGIN
                  v_long_text := q'[#{first}]';
                  v_long_text2 := q'[#{second}]';
                  dbms_lob.append(v_long_text,v_long_text2);
                  insert into deployments (id, name, src, version)
                  values ('0fe38fdf-3301-43d5-bdaa-a27444511d54', 'AutoTests/[AutoTest] DBAdapter', v_long_text, '476323f7-06da-4232-80d1-3f9b207bfeed');
                END;})
      stmt.executeUpdate("update deployments set src = REPLACE(src, ']]', ']]\"') where id = '0fe38fdf-3301-43d5-bdaa-a27444511d54'")

      # Загружаем маршрут [AutoTest] FileAdapter.xml
      fileAdapter = File.open('lib/tir_db_data/[AutoTest] FileAdapter.xml'){|file| file.read}
      stmt.executeUpdate(%Q{DECLARE
                  v_long_text clob;
               BEGIN
                  v_long_text := q'[#{fileAdapter}]';
                  insert into deployments (id, name, src, version)
                  values ('264aa722-1f7b-47a9-b3fd-ae921e412b63', 'AutoTests/[AutoTest] FileAdapter', v_long_text, 'cd18603f-6377-4c93-827e-8ed097214b6c');
                END;})
      stmt.executeUpdate("update deployments set src = REPLACE(src, ']]', ']]\"') where id = '264aa722-1f7b-47a9-b3fd-ae921e412b63'")

      # Загружаем маршрут [AutoTest] HTTPAdaper.xml
      first, second = '', ''
      n=0
      IO.read('lib/tir_db_data/[AutoTest] HTTPAdaper.xml').each_char do |char|
        if n<20000
          first << char
          n+=1
        else
          second << char
        end
      end
      stmt.executeUpdate(%Q{DECLARE
                  v_long_text clob;
                  v_long_text2 clob;
               BEGIN
                  v_long_text := q'[#{first}]';
                  v_long_text2 := q'[#{second}]';
                  dbms_lob.append(v_long_text,v_long_text2);
                  insert into deployments (id, name, src, version)
                  values ('8d9911c2-bd22-47a6-b8a2-eeb9f247b2e8', 'AutoTests/[AutoTest] HTTPAdaper', v_long_text, 'c5e591e0-f5b0-4a21-a76b-17ea559c0780');
                END;})
      stmt.executeUpdate("update deployments set src = REPLACE(src, ']]', ']]\"') where id = '8d9911c2-bd22-47a6-b8a2-eeb9f247b2e8'")
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}", "Ошибка! #{msg}")
      return true
    ensure
      stmt.close
      connection.close
    end
    send_to_log("Done! Загрузили тестовые маршруты ТИР в БД", "Done! Загрузили тестовые маршруты ТИР в БД")
    sleep 0.5
  end

  def end_test(log_file_name, startTime = false)
    begin
      sleep 0.5
      delete_rows_from_db
      sleep 0.5
      send_to_log("#{puts_line}", "#{puts_line}")
      endTime = Time.now
      puts_time(startTime, endTime) if startTime
      sleep 0.5
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}", "Ошибка! #{msg}")
    ensure
      $browser[:message].clear
      $log.close
      respond_to do |format|
        format.js { render :js => "kill_listener(); download_link('#{log_file_name}')" }
      end
    end
  end

  def dir_empty?(tir_dir)
    begin
      send_to_log("Проверка наличия каталога '#{tir_dir}'", "Проверка наличия каталога 'C:/TIR_Autotest'")
      sleep 0.5
      if Dir.entries("#{tir_dir}").size <= 2
        send_to_log("Ошибка! Каталог '#{tir_dir}' пустой", "Ошибка! Каталог '#{tir_dir}' пустой")
        return true
      else
        send_to_log("Done! Каталог #{tir_dir} найден и не пустой", "Done! Каталог #{tir_dir} найден и не пустой")
        return false
      end
    rescue Exception
      send_to_log("Ошибка! Каталог '#{tir_dir}' не найден", "Ошибка! Каталог '#{tir_dir}' не найден")
      return true
    end
  end

  def db_not_empty?
    java_import 'oracle.jdbc.OracleDriver'
    java_import 'java.sql.DriverManager'
    begin
      send_to_log("Проверка наличия пустой БД 'tir_autotest'", "Проверка наличия пустой БД 'tir_autotest'")
      sleep 0.5
      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      connection = java.sql.DriverManager.getConnection(url, "tir_autotest", "tir_autotest");
      stmt = connection.create_statement

      settings = stmt.execute_query("select * from sys_properties")
      settings_value = String.new
      while (settings.next()) do
        settings_value << settings.getString('name')
      end
      routes =  stmt.execute_query("select * from deployments")
      routes_value = String.new
      while (routes.next()) do
        routes_value << routes.getString('name')
      end
      if !settings_value.empty? || !routes_value.empty?
        send_to_log("Ошибка! БД tir_autotest не пустая! Установите ТИР с нуля", "Ошибка! БД tir_autotest не пустая! Установите ТИР с нуля")
        return true
      else
        send_to_log("Done! Обнаружена пустая БД tir_autotest", "Done! Обнаружена пустая БД tir_autotest")
        return false
      end
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}", "Ошибка! #{msg}")
      return true
    ensure
      stmt.close
      connection.close
    end
  end

  def delete_rows_from_db
    java_import 'oracle.jdbc.OracleDriver'
    java_import 'java.sql.DriverManager'
    begin
      send_to_log("Удаляем тестовые маршруты и настройки из БД 'tir_autotest'", "Удаляем тестовые маршруты и настройки из БД 'tir_autotest'")
      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      connection = java.sql.DriverManager.getConnection(url, "tir_autotest", "tir_autotest");
      stmt = connection.create_statement
      stmt.executeUpdate("TRUNCATE TABLE sys_properties")
      stmt.executeUpdate("TRUNCATE TABLE deployments")
    rescue Exception => msg
      send_to_log("Ошибка! #{msg}", "Ошибка! #{msg}")
      return true
    ensure
      stmt.close
      connection.close
    end
    sleep 0.5
    send_to_log("Done! Удалили тестовые данные.", "Done! Удалили тестовые данные.")
  end
end