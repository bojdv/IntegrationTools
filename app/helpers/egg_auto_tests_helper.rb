module EggAutoTestsHelper

  class Logger_egg
    def initialize
      @log_egg = Hash.new
      @log_dir = "#{Rails.root}/log/egg_log/#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}"
    end
    attr_accessor :log_egg, :log_dir

    def write_to_log(component, action, result = '')
      if @log_egg.has_key?(component)
        @log_egg[component][action] = result
      else
        @log_egg[component] = {action => result}
      end
    end

    def write_to_browser(text)
      if text.include?('--')
        $browser_egg[:message] += "#{text}\n"
      else
        $browser_egg[:message] += "[#{Time.now.strftime('%H:%M:%S')}]: #{text}\n"
      end
    end

    def make_log
      Dir.mkdir @log_dir
      log_file_name = "log_egg_autotests_#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}.html"
      template = File.read("#{Rails.root}/lib/egg_autotests/logs/log_template.html.erb")
      result = ERB.new(template).result(binding)
      File.open("#{@log_dir}/#{log_file_name}", 'w+') do |f|
        f.write result
      end
      return log_file_name
    end
  end

  # def $log_egg.write_to_browser(to_browser)
  #   # if to_browser
  #     if to_browser.include?('--')
  #       $browser_egg[:message] += "#{to_browser}\n"
  #     else
  #       $browser_egg[:message] += "[#{Time.now.strftime('%H:%M:%S')}]: #{to_browser}\n"
  #     end
  #   # end
  #   # if to_log
  #   #   if to_log.include?('Ошибка')
  #   #     $log_egg.error(to_log)
  #   #   else
  #   #     $log_egg.info(to_log)
  #   #   end
  #   # end
  # end

  def response_ajax_auto_egg(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect}); kill_listener_egg();"}
    end
  end

  def end_test_egg(startTime = false)
    begin
      endTime = Time.now
      puts_time_egg(startTime, endTime) if startTime
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Завершение тестов", "Ошибка при завершении тестов:", "#{msg}")
    ensure
      #$log_egg.close if !$log_egg.nil?
      log_file_name = $log_egg.make_log
      until $browser_egg[:message].empty? && $browser_egg[:event].empty?
        sleep 0.5
      end
      respond_to do |format|
        format.js { render :js => "kill_listener_egg(); download_link_egg('#{log_file_name}')" }
      end
    end
  end

  def send_to_amq_and_receive_egg(manager, xml, functional, ignore_ticket = false) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      $log_egg.write_to_browser("Отправляем XML")
      $log_egg.write_to_log(functional, "Отправка исходящей XML", "Отправляем XML #{xml.xml_name} по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}, Очередь:#{manager.queue_out}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      xml.class == String  ? xml = xml : xml = xml.xml_text
      textMessage = session.createTextMessage(xml)
      textMessage.setJMSCorrelationID(SecureRandom.uuid)
      sender = session.createSender(session.createQueue(manager.queue_out))
      connection.start
      connection.destroyDestination(session.createQueue(manager.queue_in)) # Удаляем очередь.
      sender.send(textMessage)
      #$log_egg.write_to_browser("Отправили сообщение в eGG:\n #{textMessage.getText}", "Отправили сообщение в eGG")
      $log_egg.write_to_browser("Отправили сообщение в eGG")
      $log_egg.write_to_log(functional, "Отправили сообщение в eGG", "#{textMessage.getText}")
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 40
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      if xml_actual.getText.include?("<ErrorCode>1014</ErrorCode>")
        $log_egg.write_to_browser("Пришла ошибка из СМЭВ: Внешний сервис недоступен")
        $log_egg.write_to_log(functional, "Результат отправки:", "Пришла ошибка из СМЭВ: Внешний сервис недоступен.\n#{xml_actual.getText}")
        return nil
      end
      if ignore_ticket
        $log_egg.write_to_log(functional, "Получили квиток", "Получили промежуточный квиток из очереди #{manager.queue_in}:\n #{xml_actual.getText}")
        $log_egg.write_to_browser("Получили промежуточный квиток от eGG")
        count = 40
        xml_actual = receiver.receive(1000)
        while xml_actual.nil?
          xml_actual = receiver.receive(1000)
          puts count -=1
          return nil if count == 0
        end
      end
      #$log_egg.write_to_browser("Получили ответ от eGG из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили ответ от eGG")
      $log_egg.write_to_browser("Получили ответ от eGG")
      $log_egg.write_to_log(functional, "Получили ответ", "Получили ответ от eGG из очереди #{manager.queue_in}:\n #{xml_actual.getText}")
      return xml_actual.getText
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
      $log_egg.write_to_log(functional, "Случилось непредвиденное", "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
      return nil
    ensure
      sender.close if sender
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end

  def send_to_amq_egg(manager, xml, queue = manager.queue_out) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      $log_egg.write_to_browser("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}, Очередь:#{queue}")
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
      #$log_egg.write_to_browser("Отправили сообщение в eGG:\n #{textMessage.getText}", "Отправили сообщение в eGG")
      $log_egg.write_to_browser("Отправили сообщение в eGG")
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      return nil
    ensure
      sender.close if sender
      session.close if session
      connection.close if connection
    end
  end

  def receive_from_amq_egg(manager, ignore_ticket = false) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      $log_egg.write_to_browser("Получаем XML из менеджера: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      connection.start
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 40
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      if ignore_ticket
        #$log_egg.write_to_browser("Получили промежуточный квиток из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили промежуточный квиток от eGG")
        $log_egg.write_to_browser("Получили промежуточный квиток от eGG")
        count = 40
        xml_actual = receiver.receive(1000)
        while xml_actual.nil?
          xml_actual = receiver.receive(1000)
          puts count -=1
          response_ajax("Ответ не был получен!") and return if count == 0
        end
      end
      #$log_egg.write_to_browser("Получили ответ от eGG из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили ответ от eGG")
      $log_egg.write_to_browser("Получили ответ от eGG")
      return xml_actual.getText
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      return nil
    ensure
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end

  def colorize_egg(egg_version, functional, color)
    $browser_egg[:event] = 'colorize_egg'
    $browser_egg[:egg_version] = egg_version
    $browser_egg[:functional] = functional
    $browser_egg[:color] = color
  end
  def puts_line_egg
    return '--'*40
  end
  def puts_time_egg(startTime, endTime)
    dif = (endTime-startTime).to_i.abs
    min = dif/1.minutes
    $log_egg.write_to_browser("Завершили проверку в #{Time.now.strftime('%H-%M-%S')} за: #{min} мин, #{dif-(min*1.minutes)} сек")
    $log_egg.write_to_log("Завершение тестов", "Завершили проверку", "Завершили проверку в #{Time.now.strftime('%H-%M-%S')} за: #{min} мин, #{dif-(min*1.minutes)} сек")
  end

  def dir_empty_egg?(egg_dir)
    begin
      $log_egg.write_to_browser("Проверка наличия каталога '#{egg_dir}'")
      sleep 0.5
      if Dir.entries("#{egg_dir}").size <= 2
        $log_egg.write_to_browser("Ошибка! Каталог '#{egg_dir}' пустой")
        $log_egg.write_to_log("Установка/запуск eGG", "Проверка наличия каталога '#{egg_dir}'", "Ошибка! Каталог '#{egg_dir}' пустой")
        return true
      else
        $log_egg.write_to_browser("Done! Каталог #{egg_dir} найден и не пустой")
        $log_egg.write_to_log("Установка/запуск eGG", "Проверка наличия каталога '#{egg_dir}'", "Done! Каталог #{egg_dir} найден и не пустой")
        log_file_path = "#{tests_params_egg[:egg_dir]}\\apache-servicemix-6.1.2\\data\\log\\servicemix.log"
        log_dir = "#{tests_params_egg[:egg_dir]}\\apache-servicemix-6.1.2\\data\\log\\servicemix.log"
        if File.exist?(log_file_path)
          FileUtils.rm_r "#{tests_params_egg[:egg_dir]}\\apache-servicemix-6.1.2\\data\\log\\."
          $log_egg.write_to_browser("Done! Удалили старые логи из каталога #{log_dir}")
          $log_egg.write_to_log("Установка/запуск eGG", "Удаляем старые логи", "Done! Удалили логи из каталога #{log_dir}")
        end
        return false
      end
    rescue Exception
      $log_egg.write_to_browser("Ошибка! Каталог '#{egg_dir}' не найден")
      $log_egg.write_to_log("Установка/запуск eGG", "Проверка наличия каталога '#{egg_dir}'", "Ошибка! Каталог '#{egg_dir}' не найден")
      return true
    end
  end

  def delete_db_egg
    java_import 'oracle.jdbc.OracleDriver'
    java_import 'java.sql.DriverManager'
    begin
      $log_egg.write_to_browser("Удаляем БД 'egg_autotest'")
      $log_egg.write_to_log("Завершение тестов", "Удаляем БД 'egg_autotest'", "...")
      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      connection = java.sql.DriverManager.getConnection(url, "sys as sysdba", "waaaaa");
      stmt = connection.create_statement
      stmt.executeUpdate("drop user egg_autotest cascade")
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Завершение тестов", "Ошибка при удалении БД 'egg_autotest'", "#{msg}")
      return true
    ensure
      stmt.close
      connection.close
    end
    sleep 0.5
    $log_egg.write_to_browser("Удалили БД 'egg_autotest'")
    $log_egg.write_to_log("Завершение тестов", "Результат удаления БД 'egg_autotest'", "Done!")
  end

  def start_servicemix_egg(dir)
    $log_egg.write_to_browser("Запускаем Servicemix...")
    $log_egg.write_to_log("Установка/запуск eGG", "Запускаем Servicemix...", "Ждем окончания запуска eGG")
    begin
      Dir.chdir "#{dir}\\apache-servicemix-6.1.2\\bin"
      startcrypt = "#{dir}\\apache-servicemix-6.1.2\\bin\\startcrypt.bat"
      @servicemix_start_thread_egg = Thread.new do
        Open3.popen3(startcrypt) do | input, output, error, wait_thr |
          input.sync = true
          output.sync = true
          input.puts "admin"
          input.close
          # Thread.new do
          #   puts wait_thr.pid
          #   Thread.current.kill
          # end
          # Process.kill("KILL",wait_thr.pid)
          puts output.readlines do |line|
            puts line
          end
        end
      end
    rescue Exception => msg
      #$log_egg.write_to_browser("Ошибка! #{msg}", "Ошибка! #{msg}")
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Установка/запуск eGG", "Ошибка запуска Servicemix...", "#{msg}")
      stop_servicemix_egg
    end
  end

  def stop_servicemix_egg(dir = false)
    $log_egg.write_to_log("Завершение тестов", "Останавливаем Servicemix...", "Ждем окончания остановки eGG")
    $log_egg.write_to_browser("Останавливаем Servicemix...")
    Dir.chdir "#{dir}\\apache-servicemix-6.1.2\\bin"
    @servicemix_stop_thread_egg = Thread.new do
      sleep 1
      system('servicemix.bat stop')
    end
    sleep 5
    @kill_cmd_thread_egg = Thread.new do
      system('Taskkill /IM cmd.exe /F')
    end
    while @servicemix_start_thread_egg.alive?
      puts "@@servicemix_start_thread_egg alive!"
      if @servicemix_stop_thread_egg.alive?
        puts "@@servicemix_stop_thread_egg alive!"
        sleep 0.5
      end
      if @kill_cmd_thread_egg.alive?
        puts "@@kill_cmd_thread_egg alive!"
        sleep 0.5
      end
      sleep 1
    end
    $log_egg.write_to_log("Завершение тестов", "Результат остановки Servicemix", "Done! Остановили Servicemix...")
    $log_egg.write_to_browser("Done! Остановили Servicemix...")
  end
  def ping_server_egg(host)
    begin
      uri = URI.parse(host)
      response = Net::HTTP.get_response(uri)
      puts response.code
      return true if response.code == '200' || '401'
    rescue Errno::ECONNREFUSED
      return false
    end
  end
  def get_decode_answer(xml)
    response = Document.new(xml)
    answer = response.elements['//mq:Answer'].text
    answer_decode = Base64.decode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    return answer_decode
  end
  def get_decode_request(xml)
    request = Document.new(xml)
    answer = request.elements['//mq:Request'].text
    answer_decode = Base64.decode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    #$log_egg.write_to_browser("Раскодированный тег Request:\n#{answer_decode}", "Раскодировали запрос!")
    $log_egg.write_to_browser("Раскодировали запрос!")
    return answer_decode
  end
  def get_encode_request(xml)
    request = Document.new(xml)
    answer = request.elements['//mq:Answer'].text
    answer_decode = Base64.encode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    #$log_egg.write_to_browser("Раскодировали тег Request:\n#{answer_decode}", "Раскодировали запрос!")
    $log_egg.write_to_browser("Раскодировали запрос!")
    return answer_decode
  end
  def validate_egg_xml(xsd_in, xml, functional)
    begin
      xsd = Nokogiri::XML::Schema(File.read(xsd_in))
      xml = Nokogiri::XML(xml)
      result = xsd.validate(xml)
      a = "."
      Random.rand(1..6).times {a += "."}
        if result.any?
          $log_egg.write_to_browser("Валидация не пройдена!")
          $log_egg.write_to_log(functional, "Валидация не пройдена!#{a}", "#{result.join('<br/>')}")
          return false
        else
          $log_egg.write_to_browser("Валидация прошла успешно!")
          $log_egg.write_to_log(functional, "Результат выполнения валидации#{a}", "Валидация прошла успешно!")
          return true
        end
    rescue Exception => msg
      #$log_egg.write_to_browser("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Валидация XML по XSD", "Ошибка при валидации по XSD#{a}", "Ошибка при валидации по XSD #{xsd_in}: #{msg}")
    end
  end

  def ufebs_file_count(packetepd = false, gis_type = 'gis_gmp')
    if gis_type == 'gis_gmp'
      dir = 'C:/data/inbox/1/inbound/all'
    else
      dir = 'C:/data/inbox/GIS_ZKH/inbound/all'
    end
    code_adps000 = 'ADPS000'
    code_adps001 = 'ADPS001'
    fail_code = 'ADP0001'
    adps000_count = 0
    adps001_count = 0
    count = 50
    packetepd ? positive_code = 3 : positive_code = 1
    $log_egg.write_to_browser("packetepd: #{positive_code}")
    until adps001_count == positive_code or count < 0
      if File.directory?(dir)
        Dir.entries(dir).each_entry do |entry|
          adps001_count += 1 if entry.include?(code_adps001)
          count = 0 if entry.include?(fail_code)
        end
        puts "Wait ufebs answer..."
      end
      sleep 1
      count -=1
    end
    adps001_count = 0
    if File.directory?(dir)
      #$log_egg.write_to_browser("Получили ответ из каталога #{dir}", "Получили ответ из каталога #{dir}")
      $log_egg.write_to_browser("Получили ответ из каталога #{dir}")
      Dir.entries(dir).each_entry do |entry|
        $log_egg.write_to_browser("Файлы в каталоге: #{entry}")
        if entry.include?(code_adps000)
          adps000_count += 1
        elsif entry.include?(code_adps001)
          adps001_count += 1
        elsif entry != '.' && entry != '..'
          filepath = "#{dir}/#{entry}"
          $log_egg.write_to_browser("Путь файла: #{filepath}")
          file = File.open(filepath, 'r'){ |file| file.read }
          #$log_egg.write_to_browser("Получили неожиданный статус \n#{file}", "Получили неожиданный статус #{entry}")
          $log_egg.write_to_browser("Получили неожиданный статус #{entry}")
        end
      end
    end
    return adps000_count, adps001_count
  end

  def download_installer_egg # Качаем сборку с ftp
    $log_egg.write_to_browser("Скачиваем инсталлятор eGG #{tests_params_egg[:build_version]}...")
    $log_egg.write_to_log("Установка/запуск eGG", "Скачиваем инсталлятор eGG #{tests_params_egg[:build_version]}...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
    begin
      ftp = Net::FTP.new('server-ora-bssi')
      ftp.login
      ftp.chdir("build-release/egg/#{tests_params_egg[:build_version]}")
      ftp.passive = true
      ftp.getbinaryfile("egg-#{tests_params_egg[:build_version]}-installer-windows.exe", localfile = File.basename(@build_file_egg))
    rescue Exception => msg
      #$log_egg.write_to_browser("Ошибка! #{msg}", "Ошибка! #{msg}")
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Установка/запуск eGG", "Ошибка при скачивании инсталлятора", "Ошибка! #{msg}")
    end
  end

  def copy_installer_egg # Копируем сборку в каталог C:\EGG_Installer
    $log_egg.write_to_browser("Копируем инсталлятор...")
    $log_egg.write_to_log("Установка/запуск eGG", "Копируем инсталлятор...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
    begin
      FileUtils.cp(@build_file_egg, @installer_path_egg)
      unless File.exist?(@installer_path_egg)
        puts "Copy EGG installer..."
        sleep 2
      end
      File.delete(@build_file_egg)
    rescue Exception => msg
      puts msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Установка/запуск eGG", "Ошибка при копировании инсталлятора", "Ошибка! #{msg}")
    end
  end

  def egg_run?
    log_path = "#{tests_params_egg[:egg_dir]}\\apache-servicemix-6.1.2\\data\\log\\servicemix.log"
    begin
      file = File.open(log_path, 'r'){ |file| file.read }
      file.include?('Successfully') ? true : false
    rescue Exception => msg
      return false
    end
  end

  def copy_egg_log

  end
end
