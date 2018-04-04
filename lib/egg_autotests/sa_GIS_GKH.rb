class SA_GIS_ZKH

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count

    @menu_name = 'Проверка СА ГИС ЖКХ'
    @category = Category.find_by_category_name('СА ГИС ЖКХ')
    @manager = QueueManager.find_by_manager_name('iTools[EGG]')
    @result = Hash.new
    @functional = "Проверка адаптера СА ГИС ЖКХ"
  end

  def paymentRequest_test
    begin
      count = 1
      until @result["paymentRequest_test"] == "true" or count > @try_count
        sleep 2
        xml_name = 'Payment_request'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name}.#{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}.#{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        decode_request = get_decode_request(xml.xml_text)
        decode_request = Document.new(decode_request)
        decode_request.elements['//tns:OrderID'].text = "1044583104000000150602900000#{Random.rand(1000...10000)}"
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:Request"].text = Base64.encode64(decode_request.to_s)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "1. Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}\n2. Добавили в запрос случайный OrderID: #{decode_request.elements['//tns:OrderID'].text}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        answer = send_to_amq_and_receive_egg(@manager, xml_rexml.to_s, functional)
        next count +=1  if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        answer = Document.new(answer_decode)
        if answer.elements['//ns3:TransportID'] && answer.elements['//ns3:UpdateDate']
          @result["paymentRequest_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе элементы '//ns3:TransportID' и '//ns3:UpdateDate'")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["paymentRequest_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит в себе элементы '//ns3:TransportID' и '//ns3:UpdateDate'")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["paymentRequest_test"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def paymentCancellation_test
    begin
      count = 1
      until @result["paymentCancellation_test"] == "true" or count > @try_count
        sleep 2
        xml_name = 'Payment_Cancellation_request'
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
        xml_rexml.elements["//RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "Добавили в запрос случайный processID: #{xml_rexml.elements["//RequestMessage"].attributes['processID']}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        answer = send_to_amq_and_receive_egg(@manager, xml_rexml.to_s, functional)
        next count +=1 if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        answer = Document.new(answer_decode)
        if answer.elements['//ns3:TransportID']
          @result["paymentCancellation_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе элементы '//ns3:TransportID'")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["paymentCancellation_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит в себе элемент '//ns3:TransportID'")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["paymentCancellation_test"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def paymentDetails_test
    begin
      count = 1
      until @result["paymentDetails_test"] == "true" or count > @try_count
        sleep 2
        xml_name = 'Payment_Details_request'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name}.#{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}.#{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "Добавили в запрос случайный processID: #{xml_rexml.elements["//RequestMessage"].attributes['processID']}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        answer = send_to_amq_and_receive_egg(@manager, xml_rexml.to_s, functional)
        next count +=1  if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        answer = Document.new(answer_decode)
        if answer.elements['//ns3:Charge/ns3:PaymentDocument']
          @result["paymentDetails_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе элемент '//ns3:Charge/ns3:PaymentDocument'")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["paymentDetails_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит в себе элемент '//ns3:Charge/ns3:PaymentDocument'")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["paymentDetails_test"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end
end