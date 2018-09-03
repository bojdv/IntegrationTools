class SA_ESIA_SMEV3

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count, db_username)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count
    @db_username = db_username

    @menu_name = 'СА ЕСИА СМЭВ3'
    @category = Category.find_by_category_name('СА ЕСИА СМЭВ3')
    @manager = QueueManager.find_by_manager_name('iTools[EGG]')
    @result = Hash.new
    @functional = "Проверка СА ЕСИА СМЭВ3"
  end

  def request_Confirm
    sleep 1.5
    begin
      count = 1
      until @result["request_Confirm"] == "true" or count > @try_count
        xml_name = 'Confirm_ok'
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
          change_smevmessageid(xml_rexml, '666ac963-7aaf-11e8-af4d-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIAConfirmResponse'
        if answer_decode.include?(expected_result)
          @result["request_Confirm"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_Confirm"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_Confirm"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_DELETE_ACCOUNT
    sleep 1.5
    begin
      count = 1
      until @result["request_DELETE_ACCOUNT"] == "true" or count > @try_count
        xml_name = 'DELETE_ACCOUNT_ok'
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
          change_smevmessageid(xml_rexml, '54cc4e23-7ad8-11e8-acd0-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIADeleteAccountResponse'
        if answer_decode.include?(expected_result)
          @result["request_DELETE_ACCOUNT"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_DELETE_ACCOUNT"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_DELETE_ACCOUNT"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_FIND_ACCOUNT
    sleep 1.5
    begin
      count = 1
      until @result["request_FIND_ACCOUNT"] == "true" or count > @try_count
        xml_name = 'FIND_ACCOUNT_ok'
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
          change_smevmessageid(xml_rexml, '72e05f8e-786f-11e8-8700-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIAFindAccountResponse'
        if answer_decode.include?(expected_result)
          @result["request_FIND_ACCOUNT"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_FIND_ACCOUNT"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_FIND_ACCOUNT"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_RECOVER
    sleep 1.5
    begin
      count = 1
      until @result["request_RECOVER"] == "true" or count > @try_count
        xml_name = 'RECOVER_ok'
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
          change_smevmessageid(xml_rexml, '31149fb9-7911-11e8-b972-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIARecoverResponse'
        if answer_decode.include?(expected_result)
          @result["request_RECOVER"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_RECOVER"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_RECOVER"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_REGISTER
    sleep 1.5
    begin
      count = 1
      until @result["request_REGISTER"] == "true" or count > @try_count
        xml_name = 'REGISTER_ok'
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
          change_smevmessageid(xml_rexml, '42ffdfac-7911-11e8-b972-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIARegisterResponse'
        if answer_decode.include?(expected_result)
          @result["request_REGISTER"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_REGISTER"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_REGISTER"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_REGISTER_BY_SIMPLIFIED
    sleep 1.5
    begin
      count = 1
      until @result["request_REGISTER_BY_SIMPLIFIED"] == "true" or count > @try_count
        xml_name = 'REGISTER_BY_SIMPLIFIED_ok'
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
          change_smevmessageid(xml_rexml, '364498aa-7911-11e8-b972-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIARegisterBySimplifiedResponse'
        if answer_decode.include?(expected_result)
          @result["request_REGISTER_BY_SIMPLIFIED"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_REGISTER_BY_SIMPLIFIED"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_REGISTER_BY_SIMPLIFIED"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_REGISTER_CERTIFICATE
    sleep 1.5
    begin
      count = 1
      until @result["request_REGISTER_CERTIFICATE"] == "true" or count > @try_count
        xml_name = 'REGISTER_CERTIFICATE_ok'
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
          change_smevmessageid(xml_rexml, '48407a6d-7911-11e8-b972-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIARegisterCertificateResponse'
        if answer_decode.include?(expected_result)
          @result["request_REGISTER_CERTIFICATE"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_REGISTER_CERTIFICATE"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_REGISTER_CERTIFICATE"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_REGISTER_CHILD
    sleep 1.5
    begin
      count = 1
      until @result["request_REGISTER_CHILD"] == "true" or count > @try_count
        xml_name = 'REGISTER_CHILD_ok'
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
          change_smevmessageid(xml_rexml, '3de7b47b-7911-11e8-b972-005056b644cd', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIARegisterChildResponse'
        if answer_decode.include?(expected_result)
          @result["request_REGISTER_CHILD"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_REGISTER_CHILD"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_REGISTER_CHILD"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def request_UPRID
    sleep 1.5
    begin
      count = 1
      until @result["request_UPRID"] == "true" or count > @try_count
        xml_name = 'UPRID_ok'
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
          change_smevmessageid(xml_rexml, '57fcc4ba-8ff6-11e8-bbc2-005056b654e4', @db_username, functional)
          answer = receive_from_amq_egg(@manager, functional, true, 80)
        end
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          $log_egg.write_to_browser("Не получили ответ от ЕГГ")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не получили ответ от ЕГГ")
          count +=1
          next
        end
        if answer.include?('<ErrorCode>1022</ErrorCode>') # Если ответ от ЕГГ содержит SOAP Fault
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
        expected_result = 'ESIADataVerifyResponse'
        if answer_decode.include?(expected_result)
          @result["request_UPRID"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["request_UPRID"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["request_UPRID"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end
end