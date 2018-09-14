class SA_GIS_GMP_SMEV3

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count, db_username)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count
    @db_username = db_username

    @menu_name = 'СА ГИС ГМП СМЭВ3'
    @category = Category.find_by_category_name('СА ГИС ГМП СМЭВ3')
    @manager = QueueManager.find_by_manager_name('iTools[EGG]')
    @result = Hash.new
    @functional = "Проверка СА ГИС ГМП СМЭВ3"
  end

  def Payment_new
    sleep 1.5
    begin
      count = 1
      until @result["Payment_new"] == "true" or count > @try_count
        xml_name = 'Payment_новый'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name}.#{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}.#{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        if send_to_amq_egg(@manager, xml_rexml.to_s, functional)
          change_smevmessageid_gis_gmp(xml_rexml, '25106819-6012-11e8-9f80-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Ошибка СМЭВ. Электронный сервис СМЭВ вернул SOAP Fault")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Электронный сервис СМЭВ вернул SOAP Fault")
          count +=1
          next
        end
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'Успешно'
        if answer_decode.include?(expected_result)
          @result["Payment_new"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["Payment_new"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["Payment_new"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def Payment_refinement
    sleep 1.5
    begin
      count = 1
      until @result["Payment_refinement"] == "true" or count > @try_count
        xml_name = 'Payment_уточнение'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name}.#{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}.#{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        if send_to_amq_egg(@manager, xml_rexml.to_s, functional)
          change_smevmessageid_gis_gmp(xml_rexml, '25106819-6012-11e8-9f80-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Ошибка СМЭВ. Электронный сервис СМЭВ вернул SOAP Fault")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Электронный сервис СМЭВ вернул SOAP Fault")
          count +=1
          next
        end
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'Успешно'
        if answer_decode.include?(expected_result)
          @result["Payment_refinement"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["Payment_refinement"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["Payment_refinement"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def Payment_cancellation
    sleep 1.5
    begin
      count = 1
      until @result["Payment_cancellation"] == "true" or count > @try_count
        xml_name = 'Payment_аннулирование'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name}.#{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}.#{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        if send_to_amq_egg(@manager, xml_rexml.to_s, functional)
          change_smevmessageid_gis_gmp(xml_rexml, '25106819-6012-11e8-9f80-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Ошибка СМЭВ. Электронный сервис СМЭВ вернул SOAP Fault")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Электронный сервис СМЭВ вернул SOAP Fault")
          count +=1
          next
        end
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'Успешно'
        if answer_decode.include?(expected_result)
          @result["Payment_cancellation"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["Payment_cancellation"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["Payment_cancellation"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def Charges
    sleep 1.5
    begin
      count = 1
      until @result["Charges"] == "true" or count > @try_count
        xml_name = 'Charges_запрос'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name}.#{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}.#{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        if send_to_amq_egg(@manager, xml_rexml.to_s, functional)
          change_smevmessageid_gis_gmp(xml_rexml, '93c40542-657b-11e8-b6ef-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Ошибка СМЭВ. Электронный сервис СМЭВ вернул SOAP Fault")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Электронный сервис СМЭВ вернул SOAP Fault")
          count +=1
          next
        end
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'ChargeInfo'
        if answer_decode.include?(expected_result)
          @result["Charges"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["Charges"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["Charges"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

end