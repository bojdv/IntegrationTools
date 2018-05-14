#require "#{Rails.root}/lib/egg_autotests/egg_autotests_list.rb"

class SA_GIS_GMP

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count

    @menu_name = 'СА ГИС ГМП'
    @category = Category.find_by_category_name('СА ГИС ГМП')
    @manager = QueueManager.find_by_manager_name('iTools[EGG]')
    @result = Hash.new
    @functional = "Проверка адаптера СА ГИС ГМП"
    @SystemIdentifier = "1042202001000215060220170080#{Random.rand(1000...9000)}"
  end

  def run_RequestMessage
    sleep 1.5
    begin
      count = 1
      until @result["run_RequestMessage"] == "true" or count > @try_count
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
        decode_request = get_decode_request(xml.xml_text)
        decode_request = Document.new(decode_request)
        decode_request.elements['//pi:SystemIdentifier'].text = @SystemIdentifier
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:Request"].text = Base64.encode64(decode_request.to_s)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "1. Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}\n2. Добавили в запрос случайный SystemIdentifier: #{decode_request.elements['//pi:SystemIdentifier'].text}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        answer = send_to_amq_and_receive_egg(@manager, xml_rexml.to_s, functional, true)
        next count +=1  if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'успешно'
        if answer_decode.include?(expected_result)
          @result["run_RequestMessage"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["run_RequestMessage"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["run_RequestMessage"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def run_Payment_refinement
    sleep 1.5
    begin
      count = 1
      until @result["run_Payment_refinement"] == "true" or count > @try_count
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
        decode_request = get_decode_request(xml.xml_text)
        decode_request = Document.new(decode_request)
        decode_request.elements['//pi:SystemIdentifier'].text = @SystemIdentifier
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:Request"].text = Base64.encode64(decode_request.to_s)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "1. Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}\n2. Добавили в запрос случайный SystemIdentifier: #{decode_request.elements['//pi:SystemIdentifier'].text}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        answer = send_to_amq_and_receive_egg(@manager, xml_rexml.to_s, functional, true)
        next count +=1  if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'успешно'
        if answer_decode.include?(expected_result)
          @result["run_Payment_refinement"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["run_Payment_refinement"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["run_Payment_refinement"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def run_Payment_cancellation
    sleep 1.5
    begin
      count = 1
      until @result["run_Payment_cancellation"] == "true" or count > @try_count
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
        decode_request = get_decode_request(xml.xml_text)
        decode_request = Document.new(decode_request)
        decode_request.elements['//pi:SystemIdentifier'].text = @SystemIdentifier
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.elements["//mq:Request"].text = Base64.encode64(decode_request.to_s)
        xml_rexml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        $log_egg.write_to_log(functional, "Отредактировали запрос", "1. Добавили в запрос случайный processID: #{xml_rexml.elements["//mq:RequestMessage"].attributes['processID']}\n2. Добавили в запрос случайный SystemIdentifier: #{decode_request.elements['//pi:SystemIdentifier'].text}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        answer = send_to_amq_and_receive_egg(@manager, xml_rexml.to_s, functional, true)
        next count +=1  if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'успешно'
        if answer_decode.include?(expected_result)
          @result["run_Payment_cancellation"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["run_Payment_cancellation"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["run_Payment_cancellation"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end

  def run_Charges
    sleep 1.5
    begin
      count = 1
      until @result["run_Charges"] == "true" or count > @try_count
        xml_name = 'Charges'
        functional = "#{@functional}. #{xml_name}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name}.#{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}.#{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml.xml_text, functional)
        answer = send_to_amq_and_receive_egg(@manager, xml, functional)
        next count +=1  if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        #expected_result = 'Импортируемые данные уже присутствуют в Системе'
        answer = Document.new(answer_decode)
        expected_result = '//pgu:ChargeData'
        if answer.elements[expected_result]
          @result["run_Charges"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["run_Charges"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит ожидаемое значение: #{expected_result}")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["run_Charges"] = "false"
      $log_egg.write_to_browser("Случилось непредвиденное: #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , @menu_name, @fail_menu_color)
    end
  end
end