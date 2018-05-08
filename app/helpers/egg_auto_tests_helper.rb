require 'zip'
module EggAutoTestsHelper

  class Logger_egg # Класс логирования в браузер и БД

    def initialize
      @log_egg = Hash.new # Переменная класса, пустой хэш. В него пишется весь лог.
      @log_dir = "#{Rails.root}/log/egg_log/#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}" # Переменная с именем каталога для логов, имя генерится с текущим временем.
      Dir.mkdir @log_dir # Создаем каталог для логов
    end
    attr_accessor :log_egg, :log_dir # Создаются методы для доступа к переменным класса на чтение и запись.

    def write_to_log(functional, action, result = '') # Метод для записи в лог html.
      # Параметры: functional - Корневое имя теста, action - действие (левая колонка в логе), result - результат (правая колонка в логе), его можно не указывать при вызове.
      if @log_egg.has_key?(functional) # Если хэш уже содержит ключ с именем такого теста, то делаем из этого ключа хэш с ключом action и значением result
        @log_egg[functional][action] = result # Таким образом мы формируем единую таблицу с одним заголовком functional для каждого теста
      else # Если ключ новый, то просто создаем новый хэш
        @log_egg[functional] = {action => result}
      end
    end

    def write_to_browser(text) # Метод для записи текста в лог браузера. text - текст сообщения
      if text.include?('--') # Если в тексте есть тире, то вставляем в лог разделитель. это сделано, если вызов идет из метода puts_line_egg
        $browser_egg[:message] += "#{text}\n"
      else
        $browser_egg[:message] += "[#{Time.now.strftime('%H:%M:%S')}]: #{text}\n" # Вставляем временную метку перед текстом и сам текст
      end
    end

    def make_log # Метод формирующий  файл лога
      log_file_name = "log_egg_autotests_#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}.html" # формируем имя файла
      template = File.read("#{Rails.root}/lib/egg_autotests/logs/log_template.html.erb") # читаем шаблон для лога
      result = ERB.new(template).result(binding)
      File.open("#{@log_dir}/#{log_file_name}", 'w+') do |f|
        f.write result
      end
      folder_to_zip = "#{@log_dir}"
      zipfile_name = "log_egg_autotests_#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}.zip"
      zipfile_path = "#{@log_dir}/#{zipfile_name}"
      Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
        Dir.foreach(folder_to_zip) do |item|
          item_path = "#{folder_to_zip}/#{item}"
          zipfile.add( item,item_path) if File.file?item_path
        end
      end
      FileUtils.rm Dir.glob("#{@log_dir}/*.log")
      FileUtils.rm Dir.glob("#{@log_dir}/*.html")
      FileUtils.rm Dir.glob("#{@log_dir}/*.txt")
      FileUtils.rm Dir.glob("#{@log_dir}/*.1")
      return zipfile_name
    end
  end

  def response_ajax_auto_egg(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect}); kill_listener_egg();"}
    end
  end

  def end_test_egg(startTime = false)
    begin
      endTime = Time.now
      puts_time_egg(startTime, endTime) if startTime
      until $browser_egg[:message].empty? && $browser_egg[:event].empty?
        sleep 0.5
      end
      log_file_name = $log_egg.make_log
    rescue Exception => msg
      puts msg.backtrace.join("\n")
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(@end_test_message, "Ошибка при завершении тестов:", "#{msg.backtrace.join("\n")}")
    ensure
      respond_to do |format|
        format.js { render :js => "kill_listener_egg(); download_link_egg('#{log_file_name}')" }
      end
    end
  end

  def send_to_amq_and_receive_egg(manager, xml, functional, ignore_ticket = false) # Отправка сообщений в Active MQ по протоколу OpenWire.
    # manager - объект менеджера очередей, xml - объект XML сообщения или класса REXML, functional - имя теста, ignore_ticket - игнорирование промежуточного тикета
    # Метод возвращает текст XML сообщения, полученного от ЕГГ
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      xml.class == String  ? xml = xml : xml = xml.xml_text
      $log_egg.write_to_browser("Отправляем XML")
      $log_egg.write_to_log(functional, "Отправка исходящей XML", "Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}, Очередь:#{manager.queue_out}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
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
      count = 60
      $log_egg.write_to_browser("Ждем ответ в течении #{count} секунд")
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
      $log_egg.write_to_browser("Ошибка! #{msg.message}")
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
    # Метод ничего не возвращает
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

  def receive_from_amq_egg(manager, ignore_ticket = false) # Получение сообщений из Active MQ по протоколу OpenWire
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

  def colorize_egg(egg_version, functional, color) # Метод окраски сообщений. Аргументы - версия ЕГГ, имя меню, цвет
    $browser_egg[:event] = 'colorize_egg'
    $browser_egg[:egg_version] = egg_version
    $browser_egg[:functional] = functional
    $browser_egg[:color] = color
  end

  def puts_line_egg # Метод, который вставляет в лог браузера пунктирную линию
    return '--'*40
  end

  def puts_time_egg(startTime, endTime)
    dif = (endTime-startTime).to_i.abs
    min = dif/1.minutes
    $log_egg.write_to_browser("Завершили проверку в #{Time.now.strftime('%H-%M-%S')} за: #{min} мин, #{dif-(min*1.minutes)} сек")
    $log_egg.write_to_log(@end_test_message, "Завершили проверку", "Завершили проверку в #{Time.now.strftime('%H-%M-%S')} за: #{min} мин, #{dif-(min*1.minutes)} сек")
  end

  def dir_empty_egg?(egg_dir)
    begin
      $log_egg.write_to_browser("Проверка наличия каталога '#{egg_dir}'")
      sleep 0.5
      if Dir.entries("#{egg_dir}").size <= 2
        $log_egg.write_to_browser("Ошибка! Каталог '#{egg_dir}' пустой")
        $log_egg.write_to_log(@run_test_message, "Проверка наличия каталога '#{egg_dir}'", "Ошибка! Каталог '#{egg_dir}' пустой")
        return true
      else
        $log_egg.write_to_browser("Done! Каталог #{egg_dir} найден и не пустой")
        $log_egg.write_to_log(@run_test_message, "Проверка наличия каталога '#{egg_dir}'", "Done! Каталог #{egg_dir} найден и не пустой")
        log_file_path = "#{tests_params_egg[:egg_dir]}\\apache-servicemix-6.1.2\\data\\log\\servicemix.log"
        log_dir = "#{tests_params_egg[:egg_dir]}\\apache-servicemix-6.1.2\\data\\log\\servicemix.log"
        if File.exist?(log_file_path)
          FileUtils.rm_r "#{tests_params_egg[:egg_dir]}\\apache-servicemix-6.1.2\\data\\log\\."
          $log_egg.write_to_browser("Done! Удалили старые логи из каталога #{log_dir}")
          $log_egg.write_to_log(@run_test_message, "Удаляем старые логи", "Done! Удалили логи из каталога #{log_dir}")
        end
        return false
      end
    rescue Exception
      $log_egg.write_to_browser("Ошибка! Каталог '#{egg_dir}' не найден")
      $log_egg.write_to_log(@run_test_message, "Проверка наличия каталога '#{egg_dir}'", "Ошибка! Каталог '#{egg_dir}' не найден")
      return true
    end
  end

  def delete_db_egg(functional)
    java_import 'oracle.jdbc.OracleDriver'
    java_import 'java.sql.DriverManager'
    begin
      $log_egg.write_to_browser("Удаляем БД '#{@db_username}'")
      $log_egg.write_to_log(functional, "Удаляем БД '#{@db_username}'", "...")
      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      connection = java.sql.DriverManager.getConnection(url, "sys as sysdba", "waaaaa");
      stmt = connection.create_statement
      stmt.executeUpdate(%Q{BEGIN
  EXECUTE IMMEDIATE 'DROP USER #{@db_username} cascade';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1918 THEN
      RAISE;
    END IF;
END;})
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при удалении БД '#{@db_username}'", "#{msg}")
      return true
    ensure
      stmt.close
      connection.close
    end
    sleep 0.5
    $log_egg.write_to_browser("Удалили БД '#{@db_username}'")
    $log_egg.write_to_log(functional, "Результат удаления БД '#{@db_username}'", "Done!")
  end

  def start_servicemix_egg(dir)
    $log_egg.write_to_browser("Запускаем Servicemix...")
    $log_egg.write_to_log(@run_test_message, "Запускаем Servicemix...", "Ждем окончания запуска eGG")
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
      $log_egg.write_to_log(@run_test_message, "Ошибка запуска Servicemix...", "#{msg}")
      stop_servicemix_egg
    end
  end

  def stop_servicemix_egg(dir = false)
    $log_egg.write_to_log(@end_test_message, "Останавливаем Servicemix...", "Ждем окончания остановки eGG")
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
    $log_egg.write_to_log(@end_test_message, "Результат остановки Servicemix", "Done! Остановили Servicemix...")
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

  def get_decode_answer(xml) # Метод, который получает текст XML и возвращает раскодированный текст тега '//mq:Answer'
    response = Document.new(xml)
    answer = response.elements['//mq:Answer'].text
    answer_decode = Base64.decode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    return answer_decode
  end

  def get_decode_request(xml) # Тоже, что и get_decode_answer
    request = Document.new(xml)
    answer = request.elements['//mq:Request'].text
    answer_decode = Base64.decode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    return answer_decode
  end

  def get_encode_request(xml) # Метод, который получает XML для запроса и возвращает раскодированный тег '//mq:Answer'
    request = Document.new(xml)
    answer = request.elements['//mq:Answer'].text
    answer_decode = Base64.encode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    #$log_egg.write_to_browser("Раскодировали тег Request:\n#{answer_decode}", "Раскодировали запрос!")
    $log_egg.write_to_browser("Раскодировали запрос!")
    return answer_decode
  end

  def validate_egg_xml(xsd_in, xml, functional) # Метод валидации по XSD. xsd_in - путь к XSD, xml - текст XML, functional - название теста
    # Ничего не возвращает, а только пишет в лог результат
    begin
      Dir.chdir File.expand_path File.dirname(xsd_in)
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

  def get_file_body(dir)
    body = String.new
    count = 60 # Ожидание ответа в секундах
    until body.size > 0 or count == 0
      if File.directory?(dir) # Проверяем существует ли директория
        Dir.entries(dir).each_entry do |entry| # Просматриваем каждый файл в каталоге, имя файла пишется в переменную entry
          file_path = "#{dir}/#{entry}"
          if File.file?(file_path)
            body = File.open(file_path, 'r'){|file| file.read}
            #File.delete file_path
          end
        end
        puts "Wait JPM answer...#{count}"
      end
      sleep 1
      count -=1 # Уменьшаем счетчик на 1 секунду
    end
    return body
  end

  def ufebs_file_count(functional, packetepd = false, gis_type = 'gis_gmp') # Метод, который возвращает кол-во полученных из УФЭБС файлов
    # functional - название тест, packetepd - признак, что это запрос packetepd, gis_type - тип адаптера, по умолчанию ГИС ГМП, если другое, то будет ГИС ЖКХ
    if gis_type == 'gis_gmp' # Анализируем тип адаптера и соответственно выбираем каталог, куда класть файлы
      dir = 'C:/data/inbox/1/inbound/all'
    else
      dir = 'C:/data/inbox/GIS_ZKH/inbound/all'
    end
    code_adps000 = 'ADPS000' # Переменная хранит код промежуточного тикета от адаптера
    code_adps001 = 'ADPS001' # Переменная хранит код успешного сообщения от СМЭВ
    fail_code = 'ADP0001' # Переменная хранит код ошибки из СМЭВ, что сервис недоступен
    adps000_count = 0 # Счетчик промежуточных квитков
    adps001_count = 0 # Счетчик финальных успешных квитков
    count = 60 # Ожидание ответа в секундах
    $log_egg.write_to_browser("Ждем ответ в течении #{count} секунд")
    packetepd ? positive_code = 3 : positive_code = 1 # Если мы проверяем запрос packetepd, то будем ждать от адаптера 3 файла с успешным кодом ADPS001, если другие запросы, то один файл.
    until adps001_count == positive_code or count < 0 # Просматриваем каталог, пока не обнаружим нужное кол-во файлов с кодом ADPS001 или пока не пройдет время count
      if File.directory?(dir) # Проверяем существует ли директория
        Dir.entries(dir).each_entry do |entry| # Просматриваем каждый файл в каталоге, имя файла пишется в переменную entry
          adps001_count += 1 if entry.include?(code_adps001) # Если файл содержит в своем имени нужный код, то добавляем +1 к счетчику adps001_count
          count = 0 if entry.include?(fail_code) # Если обнаружили файл с кодом ошибки, то выходим из цикла, больше ждать нет смысла.
        end
        puts "Wait ufebs answer...#{count}"
      end
      sleep 1
      count -=1 # Уменьшаем счетчик на 1 секунду
    end # Этот цикл нужен для того, что бы ждать, пока в каталоге появятся нужные файлы, больше он ничего не делает.
    adps001_count = 0
    # А теперь проходим по каталогу и смотрим по факту, какие файлы там есть.
    if File.directory?(dir)
      $log_egg.write_to_browser("Получили ответ из каталога #{dir}")
      $log_egg.write_to_log(functional, "Получение ответа", "Получили ответ из каталога #{dir}")
      Dir.entries(dir).each_entry do |entry|
        file_path = "#{dir}/#{entry}"
        if File.file?(file_path) # Выводим список файлов в каталоге
          input_xml = File.open(file_path, 'r'){ |file| file.read }
          $log_egg.write_to_browser("Файлы в каталоге: #{entry}")
          $log_egg.write_to_log(functional, "Файлы в каталоге: #{entry}", "#{input_xml}")
        end
        if entry.include?(code_adps000) # Плюсуем счетчик квитков о доставке, если нашли нужный код в имени файла
          adps000_count += 1
        elsif entry.include?(code_adps001) # Плюсуем счетчик финальных квитков, если нашли нужный код в имени файла
          adps001_count += 1
        elsif entry != '.' && entry != '..' # Если в каталоге есть в каталоге файл с любым статусом, кроме тех, что выше, то сообщаем об ошибке.
          filepath = "#{dir}/#{entry}"
          $log_egg.write_to_browser("Путь файла: #{filepath}")
          file = File.open(filepath, 'r'){ |file| file.read }
          $log_egg.write_to_browser("Получили неожиданный статус #{entry}")
          $log_egg.write_to_log(functional, "Получили неожиданный статус \n#{entry}", "Получили неожиданный статус #{entry}\nПуть файла: #{filepath}\n#{file}")
        end
      end
    end
    return adps000_count, adps001_count # Возвращаем кол-во файлов с каждым статусом
  end

  def download_installer_egg # Качаем сборку с ftp
    $log_egg.write_to_browser("Скачиваем инсталлятор eGG #{tests_params_egg[:build_version]}...")
    $log_egg.write_to_log(@run_test_message, "Скачиваем инсталлятор eGG #{tests_params_egg[:build_version]}...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
    begin
      ftp = Net::FTP.new('server-ora-bssi')
      ftp.login
      ftp.chdir("build-release/egg/#{tests_params_egg[:build_version]}")
      ftp.passive = true
      ftp.getbinaryfile("egg-#{tests_params_egg[:build_version]}-installer-windows.exe", localfile = File.basename(@build_file_egg))
    rescue Exception => msg
      #$log_egg.write_to_browser("Ошибка! #{msg}", "Ошибка! #{msg}")
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(@run_test_message, "Ошибка при скачивании инсталлятора", "Ошибка! #{msg}")
    end
  end

  def copy_installer_egg # Копируем сборку в каталог C:\EGG_Installer
    $log_egg.write_to_browser("Копируем инсталлятор...")
    $log_egg.write_to_log(@run_test_message, "Копируем инсталлятор...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
    begin
      FileUtils.cp(@build_file_egg, @installer_path_egg)
      unless File.exist?(@installer_path_egg)
        puts "Copy EGG installer..."
        sleep 2
      end
      File.delete(@build_file_egg)
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(@run_test_message, "Ошибка при копировании инсталлятора", "Ошибка! #{msg}")
    end
  end

  def egg_log_include?(egg_dir, text)
    log_path = "#{egg_dir}\\apache-servicemix-6.1.2\\data\\log\\servicemix.log"
    begin
      file = File.open(log_path, 'r'){ |file| file.read }
      file.include?(text) ? true : false
    rescue Exception => msg
      puts msg
      return false
    end
  end

  def copy_egg_files
    begin
      FileUtils.cp_r("#{tests_params_egg[:egg_dir]}/apache-servicemix-6.1.2/data/log/.", $log_egg.log_dir) # копируем лог сервисмикса
      FileUtils.cp_r Dir.glob("#{tests_params_egg[:egg_dir]}/*.txt"), $log_egg.log_dir # копируем лог инсталлятора
      $log_egg.write_to_log(@end_test_message, "Копирование логов eGG", "Done!")
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(@end_test_message, "Ошибка при копировании логов", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
    end
  end

  def insert_inn(db_user) # Метод вставляет в таблицу zkh_inn запись с поставщиком для тестов. Ничего не возвращает.
    begin
      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      puts "USER=#{@db_username.to_s}"
      connection = java.sql.DriverManager.getConnection(url, @db_username, @db_username);
      stmt = connection.create_statement
      # stmt.executeUpdate("TRUNCATE TABLE zkh_inn")
      # $log_egg.write_to_browser("Очистили таблицу ZKH_INN")
      #$log_egg.write_to_log(functional, "Очистили таблицу ZKH_INN")
      #stmt.executeUpdate("insert into zkh_inn (inn, kpp, name, account, bank_name, bank_bik) values (5406562465, 540501001, 'ФОНД МОДЕРНИЗАЦИИ И РАЗВИТИЯ ЖИЛИЩНО-КОММУНАЛЬНОГО ХОЗЯЙСТВА МУНИЦИПАЛЬНЫХ ОБРАЗОВАНИЙ НОВОСИБИРСКОЙ ОБЛАСТИ', 40604810200290003717, '\"ГАЗПРОМБАНК\" (АКЦИОНЕРНОЕ ОБЩЕСТВО)', '045004783')")
      stmt.executeUpdate("insert into zkh_inn (inn, kpp, name, account, bank_name, bank_bik) values (9909400765, 774763002, 'ООО Межгосударственный банк', 30301810000006000001, 'ПАО СБЕРБАНК', '044525225')")
    ensure
      stmt.close if stmt
      connection.close if connection
    end
  end

  def get_installer_config
    case # Определяем название файла с конфигом инсталлятора
      when tests_params_egg[:build_version].include?('6.9')
        "optionsEgg69.txt"
      when tests_params_egg[:build_version].include?('6.10')
        "optionsEgg610.txt"
      when tests_params_egg[:build_version].include?('6.11')
        "optionsEgg611.txt"
      else
        "optionsEgg69.txt"
    end
  end

end
