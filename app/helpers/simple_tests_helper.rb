module SimpleTestsHelper
  # def compare_xml(xml, xml_actual)
  #   expected_answer = Nokogiri::XML(xml)
  #   actual_answer = Nokogiri::XML(xml_actual)
  #   puts EquivalentXml.equivalent?(expected_answer, actual_answer, opts = {:ignore_content => 'extId'})
  #   EquivalentXml.equivalent?(expected_answer, actual_answer, opts = {:normalize_whitespace => false, :ignore_content => 'extId'}) do |n1, n2, result|
  #     puts n1
  #     puts n2
  #     puts result
  #   end
  #   puts xml_actual.include?(xml)
  #   puts xml.xml_name
  #   if xml_actual.include?(xml)
  #     @xml_pass.push(xml.xml_name)
  #   end
  # end
  def send_to_amq_openwire(manager, xml, mode, ignore_ticket, egg) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    if mode == 'single'
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
        count = 25
        xml_actual = receiver.receive(1000)
        while xml_actual.nil?
          xml_actual = receiver.receive(1000)
          puts count -=1
          response_ajax("Ответ не был получен!") and return if count == 0
        end
        if ignore_ticket == 'true'
          count = 25
          xml_actual = receiver.receive(1000)
          while xml_actual.nil?
            xml_actual = receiver.receive(1000)
            puts count -=1
            response_ajax("Ответ не был получен!") and return if count == 0
          end
        end
        if egg == 'false'
          if xml_actual.getText.include?(xml.xml_answer)
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#b3ffcc')" }
            end
          else
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#e9ecef')" }
            end
          end
        else
          response = Document.new(xml_actual.getText)
          answer = response.elements['//mq:Answer'].text
          answer_decode = Base64.decode64(answer)
          answer_decode = answer_decode.force_encoding("utf-8")
          if answer_decode.include?(xml.xml_answer)
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#b3ffcc')" }
            end
          else
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#e9ecef')" }
            end
          end
        end
      rescue => msg
        response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}", 10000)
      ensure
        sender.close if session
        receiver.close if session
        session.close if session
        connection.close if connection
      end
    elsif mode == 'all'
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
        count = 25
        xml_actual = receiver.receive(1000)
        while xml_actual.nil? && count > 0
          xml_actual = receiver.receive(1000)
          puts count -=1
        end
        if ignore_ticket == 'true'
          count = 25
          xml_actual = receiver.receive(1000)
          while xml_actual.nil? && count > 0
            xml_actual = receiver.receive(1000)
            puts count -=1
          end
        end
        if xml_actual.nil?
          @xml_fail << "<u>#{xml.xml_name}</u>: <i>похоже, не получили ответ</i>"
        else
          if egg == 'false'
            xml_actual.getText.include?(xml.xml_answer) ? @xml_pass << xml.xml_name : @xml_fail << "<u>#{xml.xml_name}</u>: <i>фактический ответ не совпал с ожидаемым</i>"
          else
            response = Document.new(xml_actual.getText)
            answer = response.elements['//mq:Answer'].text
            answer_decode = Base64.decode64(answer)
            answer_decode = answer_decode.force_encoding("utf-8")
            answer_decode.include?(xml.xml_answer) ? @xml_pass << xml.xml_name : @xml_fail << "<u>#{xml.xml_name}</u>: <i>фактический ответ не совпал с ожидаемым</i>"
          end
        end
      rescue => msg
        @xml_fail << "<u>#{xml.xml_name}</u>: <i>#{msg.message}</i>"
      ensure
        sender.close if session
        receiver.close if session
        session.close if session
        connection.close if connection
      end
    end
  end

  def send_to_amq_stomp(manager, xml, mode) # Отправка сообщений в Active MQ по протоколу STOMP
    puts 'Sending message to AMQ (STOMP)'
    if mode == 'single'
      begin
        client = Stomp::Client.new(manager.user, manager.password, manager.host, manager.port)
        #Очищаем очередь
        inputqueue = manager.queue_in
        client.subscribe(inputqueue){|msg| }
        client.join(1)
        client.close

        client = Stomp::Client.new(manager.user, manager.password, manager.host, manager.port)
        client.publish("/queue/#{manager.queue_out}", xml.xml_text) #Кидаем запрос в очередь
        sleep 2
        xml_actual = String.new
        client.subscribe(inputqueue){|msg| xml_actual << msg.body.to_s}
        client.join(1)
        client.close
        count = 25
        while xml_actual.empty?
          client = Stomp::Client.new(manager.user, manager.password, manager.host, manager.port)
          client.subscribe(inputqueue){|msg| xml_actual << msg.body.to_s}
          client.join(1)
          client.close
          sleep 1
          puts count -=1
          response_ajax("Ответ не был получен!") and return if count == 0
        end
        if xml_actual.include?(xml.xml_answer)
          respond_to do |format|
            format.js { render :js => "updateActualXml('#{xml_actual.inspect.slice(1..-2)}', '#b3ffcc')" }
          end
        else
          respond_to do |format|
            format.js { render :js => "updateActualXml('#{xml_actual.inspect.slice(1..-2)}', '#e9ecef')" }
          end
        end
      rescue Exception => msg
        response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}", 10000)
      ensure
      end
    elsif mode == 'all'
      begin
        client = Stomp::Client.new(manager.user, manager.password, manager.host, manager.port)
        #Очищаем очередь
        inputqueue = manager.queue_in
        client.subscribe(inputqueue){|msg| }
        client.join(1)
        client.close

        client = Stomp::Client.new(manager.user, manager.password, manager.host, manager.port)
        client.publish("/queue/#{manager.queue_out}", xml.xml_text) #Кидаем запрос в очередь
        sleep 2
        xml_actual = String.new
        client.subscribe(inputqueue){|msg| xml_actual << msg.body.to_s}
        client.join(1)
        client.close
        count = 25
        while xml_actual.empty?
          client = Stomp::Client.new(manager.user, manager.password, manager.host, manager.port)
          client.subscribe(inputqueue){|msg| xml_actual << msg.body.to_s}
          client.join(1)
          client.close
          sleep 1
          puts count -=1
        end
        if xml_actual.empty?
          @xml_fail << "<u>#{xml.xml_name}</u>: <i>похоже, не получили ответ</i>"
        else
          xml_actual.include?(xml.xml_answer) ? @xml_pass << xml.xml_name : @xml_fail << "<u>#{xml.xml_name}</u>: <i>фактический ответ не совпал с ожидаемым</i>"
        end
      rescue Exception => msg
        response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}", 10000)
      ensure
      end
    end
  end
  def send_to_wmq(manager, xml, mode, ignore_ticket, egg)
    puts 'Sending message to WMQ'
    java_import 'javax.jms.JMSException'
    java_import 'javax.jms.QueueConnection'
    java_import 'javax.jms.QueueSender'
    java_import 'javax.jms.QueueReceiver'
    java_import 'javax.jms.QueueSession'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    java_import 'com.ibm.mq.MQMessage'
    java_import 'com.ibm.mq.jms.MQQueueConnectionFactory'
    java_import 'com.ibm.mq.jms.JMSC'
    if mode == 'single'
      begin
        factory = MQQueueConnectionFactory.new
        factory.setHostName(manager.host)
        factory.setQueueManager(manager.channel_manager)
        factory.setChannel(manager.channel)
        factory.setPort(1414)
        factory.setClientID('mqm')
        factory.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP)
        manager.user.nil? ? user ='' : user=manager.user
        manager.password.nil? ? password ='' : password=manager.user
        connection = factory.createQueueConnection(user, password)
        session = connection.createQueueSession(false, QueueSession::AUTO_ACKNOWLEDGE)
        sender = session.createSender(session.createQueue(manager.queue_out))
        textMessage = session.createTextMessage(xml.xml_text)
        textMessage.setJMSType("mcd://xmlns")
        textMessage.setJMSExpiration(2*1000)
        connection.start
        sender.send(textMessage)
        receiver = session.createReceiver(session.createQueue(manager.queue_in))
        count = 25
        xml_actual = receiver.receive(1000)
        while xml_actual.nil?
          xml_actual = receiver.receive(1000)
          puts count -=1
          response_ajax("Ответ не был получен!") and return if count == 0
        end
        if ignore_ticket == 'true'
          count = 25
          xml_actual = receiver.receive(1000)
          while xml_actual.nil?
            xml_actual = receiver.receive(1000)
            puts count -=1
            response_ajax("Ответ не был получен!") and return if count == 0
          end
        end
        if egg == 'false'
          if xml_actual.getText.include?(xml.xml_answer)
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#b3ffcc')" }
            end
          else
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#e9ecef')" }
            end
          end
        else
          response = Document.new(xml_actual.getText)
          answer = response.elements['//mq:Answer'].text
          answer_decode = Base64.decode64(answer)
          answer_decode = answer_decode.force_encoding("utf-8")
          if answer_decode.include?(xml.xml_answer)
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#b3ffcc')" }
            end
          else
            respond_to do |format|
              format.js { render :js => "updateActualXml('#{xml_actual.getText.inspect.slice(1..-2)}', '#e9ecef')" }
            end
          end
        end
      rescue => msg
        response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}", 10000)
      ensure
        sender.close if sender
        receiver.close if receiver
        session.close if session
        connection.close if connection
      end
    elsif mode == 'all'
      begin
        factory = MQQueueConnectionFactory.new
        factory.setHostName(manager.host)
        factory.setQueueManager(manager.channel_manager)
        factory.setChannel(manager.channel)
        factory.setPort(1414)
        factory.setClientID('mqm')
        factory.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP)
        manager.user.nil? ? user ='' : user=manager.user
        manager.password.nil? ? password ='' : password=manager.user
        connection = factory.createQueueConnection(user, password)
        session = connection.createQueueSession(false, QueueSession::AUTO_ACKNOWLEDGE)
        sender = session.createSender(session.createQueue(manager.queue_out))
        textMessage = session.createTextMessage(xml.xml_text)
        textMessage.setJMSType("mcd://xmlns")
        textMessage.setJMSExpiration(2*1000)
        connection.start
        sender.send(textMessage)
        receiver = session.createReceiver(session.createQueue(manager.queue_in))
        count = 25
        xml_actual = receiver.receive(1000)
        while xml_actual.nil? && count > 0
          xml_actual = receiver.receive(1000)
          puts count -=1
        end
        if ignore_ticket == 'true'
          count = 25
          xml_actual = receiver.receive(1000)
          while xml_actual.nil?
            xml_actual = receiver.receive(1000)
            puts count -=1
            response_ajax("Ответ не был получен!") and return if count == 0
          end
        end
        if xml_actual.nil?
          @xml_fail << "<u>#{xml.xml_name}</u>: <i>похоже, не получили ответ</i>"
        else
          if egg == 'false'
            xml_actual.getText.include?(xml.xml_answer) ? @xml_pass << xml.xml_name : @xml_fail << "<u>#{xml.xml_name}</u>: <i>фактический ответ не совпал с ожидаемым</i>"
          else
            response = Document.new(xml_actual.getText)
            answer = response.elements['//mq:Answer'].text
            answer_decode = Base64.decode64(answer)
            answer_decode = answer_decode.force_encoding("utf-8")
            answer_decode.include?(xml.xml_answer) ? @xml_pass << xml.xml_name : @xml_fail << "<u>#{xml.xml_name}</u>: <i>фактический ответ не совпал с ожидаемым</i>"
          end
        end
      rescue => msg
        @xml_fail << "<u>#{xml.xml_name}</u>: <i>#{msg.message}</i>"
      ensure
        sender.close if sender
        receiver.close if receiver
        session.close if session
        connection.close if connection
      end
    end
  end
end