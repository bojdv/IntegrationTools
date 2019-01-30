
class IA_UFEBS_GIS_ZKH

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count, ufebs_version, db_username)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count
    @db_username = db_username

    @menu_name = 'ИА УФЭБС (ГИС ЖКХ)' # Название меню. Используется, что бы программа поняла, какому пункту изменить цвет после проверки.
    @category = Category.find_by_category_name('ИА УФЭБС ГИС ЖКХ') # Создаем переменную, содержащую категорию с нужным имененм из XML Sender
    @dir_outbound = 'C:/data/inbox/GIS_ZKH/outbound' # Каталог, куда кладем файлы
    @dir_inbound = 'C:/data/inbox/GIS_ZKH/inbound' # Каталог, от куда читаем файлы
    @result = Hash.new # пустой хэш, в который пишутся результаты выполнения теста
    @functional = "Проверка ИА УФЭБС (ГИС ЖКХ)" # Имя корневого раздела теста в логе html
    @ufebs_version = ufebs_version #\app\smx\resourceapp.war\wsdl\XSD\CBR\х\ed\cbr_ed101_vх.xsd
  end

  def change_transportguid(functional, transport_guid)
    30.times do
      $egg_integrator.core_in_ufebs_zkh.any? ? (break) : (sleep 1)
    end
    if $egg_integrator.core_in_ufebs_zkh.any?
      xml_from_ia = $egg_integrator.core_in_ufebs_zkh.first[:body]
      $log_egg.write_to_browser("Перехватили сообщение от ИА к ядру. CorrelationID: #{$egg_integrator.core_in_ufebs_zkh.first[:correlation_id]}")
      $log_egg.write_to_log(functional, "Перехватили сообщение от ИА к ядру. CorrelationID: #{$egg_integrator.core_in_ufebs_zkh.first[:correlation_id]}", xml_from_ia)
    else
      $log_egg.write_to_browser("Сообщение не дошло до ядра")
      $log_egg.write_to_log(functional, "Проверка сообщения в очереди core_sa", "Сообщение не дошло до ядра")
      return
      # count +=1
      # next
    end
    decode_rexml_request = get_decode_core_request(xml_from_ia)
    decode_rexml_request.root.add_element('gis:TransportGUID').text = transport_guid
    xml_to_sa = get_encode_core_request(functional, xml_from_ia, decode_rexml_request.to_s)
    $egg_integrator.send_to_core(xml_to_sa, $egg_integrator.core_in_ufebs_zkh.first[:correlation_id])
    $log_egg.write_to_browser("Изменили в XML TransportGUID и отправили в ядро")
    $log_egg.write_to_log(functional, "Изменили в XML TransportGUID и отправили в ядро", xml_to_sa)
    $egg_integrator.core_in_ufebs_zkh.clear
  end

  def ed101_test
    sleep 1.5
    begin # begin означает начало блока, в котором мы хотим отловить исключение, если оно случится, что будет выполнен блок rescue
      count = 1 # Номер попытки для вывода в лог
      xml_name = 'ed101' # Название XML в XML_sender, которую будем использовать
      until @result["ed101_test"] == "true" or count > @try_count # Выполняем цикл, пока результат не будет true или пока счетчик не превысит число попыток
        functional = "#{@functional}. #{xml_name}. Попытка #{count}" # Формируем название теста для лога
        insert_inn # Вставляем в БД запись с поставщиком
        xml_root_element = 'ED101'  # Корневой элемент, просто, что бы не писать руками в куче мест
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")  # Формируем случайную дату
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{xml_name}")  # Публикуем запись в html лог. Параметры см. в описании метода
        $log_egg.write_to_browser("#{puts_line_egg}")  # Публикуем запись в лог браузера
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}. #{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first  # Создаем переменную на основе поиска в БД по имени XML и имени категории
        raise @not_find_xml if xml.nil?  # Исключение, если не нашли XML
        $log_egg.write_to_log(functional, "Получили xml", "Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text) # Создаем объект джема REXML на основе текста XML, что бы обращаться к ее элементам (парсить)
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/#{@ufebs_version}/cbr_#{xml_name}_v#{@ufebs_version}.xsd" # Путь к XSD для валидации
        xml_rexml.elements["//#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000) # Генерим случайное значение в диапазоне 1000-50000 для атрибута EDNo
        xml_rexml.elements["//#{xml_root_element}"].attributes['EDDate'] = date
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional) # Валидируем запрос
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s } # Создаем файл в исходящем каталоге и пишем в него текст XML из БД
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_transportguid(functional, '00000000-0000-0000-0000-000000000000') # Перехватываем сообщение до ядра и меняем TransportGUID на значение из заглушки
        answer = ufebs_file_count(functional, false, 'gis_zkh') # Читай описание в методе. Возвращает число найденных в каталоге файлов с нужными статусами
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
          @result["ed101_test"] = "true" # Добавляем в хэш ключ ed101_test со значенеим true
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false") # Если хэш @result не содержит значение false, то вызываем метод, который красит меню в зеленый цвет
        elsif answer.first == 0 and answer.last == 0 # Если ничего не нашли в каталоге
          @result["ed101_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0 # Если получили только ответ от адаптера (ADPS000), а не от СМЭВ
          @result["ed101_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1 # Увеличиваем счетчик на +1, иначе говоря count = count + 1
      end
    rescue Exception => msg # Записываем текст исключения в переменную msq
      @result["ed101_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

  def ed108_test
    sleep 1.5
    begin
      count = 1
      until @result["ed108_test"] == "true" or count > @try_count
        xml_name = 'ed108'
        xml_root_element = 'ED108'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        insert_inn # Вставляем в БД запись с поставщиком
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}. #{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/#{@ufebs_version}/cbr_#{xml_name}_v#{@ufebs_version}.xsd"
        xml_rexml.elements["//#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//#{xml_root_element}"].attributes['EDDate'] = date
        xml_rexml.elements["//#{xml_root_element}"].attributes['ChargeOffDate'] = date
        xml_rexml.elements["//#{xml_root_element}"].attributes['ReceiptDate'] = date
        xml_rexml.elements["//AccDoc"].attributes['AccDocDate'] = date
        xml_rexml.elements["//CreditTransferTransactionInfo"].attributes['PayerDocDate'] = date
        xml_rexml.elements["//CreditTransferTransactionInfo"].attributes['TransactionDate'] = date
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_transportguid(functional, '00000000-0000-0000-0000-000000000000') # Перехватываем сообщение до ядра и меняем TransportGUID на значение из заглушки
        answer = ufebs_file_count(functional, false, 'gis_zkh')
        if answer.first == 1 and answer.last == 1
          @result["ed108_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        elsif answer.first == 0 and answer.last == 0
          @result["ed108_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result["ed108_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count += 1
      end
    rescue Exception => msg
      @result["ed108_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

  def packetepd_test
    sleep 1.5
    begin
      count = 1
      until @result["packetepd_test"] == "true" or count > @try_count
        xml_name = 'packetepd'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'PacketEPD'
        insert_inn # Вставляем в БД запись с поставщиком
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}. #{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/#{@ufebs_version}/cbr_#{xml_name}_v#{@ufebs_version}.xsd"
        xml_rexml.elements["//#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//ED101"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//ED108"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//ED108"].attributes['ChargeOffDate'] = date
        xml_rexml.elements["//ED108"].attributes['EDDate'] = date
        xml_rexml.elements["//ED108"].attributes['ReceiptDate'] = date
        xml_rexml.elements["//AccDoc"].attributes['AccDocDate'] = date
        xml_rexml.elements["//CreditTransferTransactionInfo"].attributes['PayerDocDate'] = date
        xml_rexml.elements["//CreditTransferTransactionInfo"].attributes['TransactionDate'] = date
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")

        # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        30.times do
          $egg_integrator.core_in_ufebs_zkh.any? ? (break) : (sleep 1)
        end

        if $egg_integrator.core_in_ufebs_zkh.any?
          sleep 3
          $egg_integrator.core_in_ufebs_zkh.each do |request|
            xml_from_ia = request[:body]
            $log_egg.write_to_browser("Перехватили сообщение от ИА к ядру. CorrelationID: #{request[:correlation_id]}")
            $log_egg.write_to_log(functional, "Перехватили сообщение от ИА к ядру. CorrelationID: #{request[:correlation_id]}", xml_from_ia)
            decode_rexml_request = get_decode_core_request(xml_from_ia)
            decode_rexml_request.root.add_element('gis:TransportGUID').text = '00000000-0000-0000-0000-000000000000'
            xml_to_sa = get_encode_core_request(functional, xml_from_ia, decode_rexml_request.to_s)
            $egg_integrator.send_to_core(xml_to_sa, request[:correlation_id])
            $log_egg.write_to_browser("Изменили в XML TransportGUID и отправили в ядро")
            $log_egg.write_to_log(functional, "Изменили в XML TransportGUID и отправили в ядро", xml_to_sa)
            sleep 2
          end
          $egg_integrator.core_in_ufebs_zkh.clear
        else
          $log_egg.write_to_browser("Сообщение не дошло до ядра")
          $log_egg.write_to_log(functional, "Проверка сообщения в очереди core_sa", "Сообщение не дошло до ядра")
          return
          # count +=1
          # next
        end
        #########################################################

        answer = ufebs_file_count(functional, true, 'gis_zkh')
        if answer.first == 2 and answer.last == 2
          @result["packetepd_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
          res = true
        elsif answer.first == 0 and answer.last == 0
          @result["packetepd_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result["packetepd_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        else
          @result["packetepd_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count += 1
      end
    rescue Exception => msg
      @result["packetepd_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end
end
