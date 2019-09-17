#require "#{Rails.root}/lib/egg_autotests/egg_autotests_list.rb"

class IA_UFEBS_GIS_GMP_SMEV3

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count, ufebs_version)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count

    @menu_name = 'ИА УФЭБС (ГИС ГМП СМЭВ3)'
    @category = Category.find_by_category_name('ИА УФЭБС ГИС ГМП')
    @dir_outbound = 'C:/data/INAD_GISGMP_UFEBS/outbound'
    @dir_inbound = 'C:/data/INAD_GISGMP_UFEBS/inbound'
    @result = Hash.new
    @functional = "Проверка ИА УФЭБС (ГИС ГМП СМЭВ3)"
    @ufebs_version = ufebs_version #\app\smx\resourceapp.war\wsdl\XSD\CBR\х\ed\cbr_ed101_vх.xsd
    @edno_ed101 = Random.rand(1000..50000)
  end

  def get_decode_answer(xml) # Метод, который получает текст XML и возвращает раскодированный текст тега '//mq:Answer'
    response = Document.new(xml)
    answer = response.elements['//mq:Answer'].text
    answer_decode = Base64.decode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    return answer_decode
  end

  def change_id(functional, correlation_id) # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
    30.times do
      $egg_integrator.core_in_ufebs_gmp_smev3.any? ? (break) : (sleep 1)
    end
    if $egg_integrator.core_in_ufebs_gmp_smev3.any?
      @xml_from_ia = $egg_integrator.core_in_ufebs_gmp_smev3.first[:body]
      $log_egg.write_to_browser("Перехватили сообщение от ИА к ядру. CorrelationID: #{$egg_integrator.core_in_ufebs_gmp_smev3.first[:correlation_id]}")
      $log_egg.write_to_log(functional, "Перехватили сообщение от ИА к ядру. CorrelationID: #{$egg_integrator.core_in_ufebs_gmp_smev3.first[:correlation_id]}", @xml_from_ia)
    else
      $log_egg.write_to_browser("Сообщение не дошло до ядра")
      $log_egg.write_to_log(functional, "Проверка сообщения в очереди core_sa", "Сообщение не дошло до ядра")
      return
      # count +=1
      # next
    end
    decode_rexml_request = get_decode_core_request(@xml_from_ia)
    #$log_egg.write_to_log(functional, "decode_rexml_request", "#{decode_rexml_request}")
    case # Определяем наличие префикса у xml
      when decode_rexml_request.to_s.include?('p1:ImportedPayment')
        decode_rexml_request.elements['//p1:ImportedPayment'].attributes['Id'] = correlation_id
      when decode_rexml_request.to_s.include?('ImportedChange')
        decode_rexml_request.elements['//ImportedChange'].attributes['Id'] = correlation_id
      else
        $log_egg.write_to_log(functional, "correlation_id", "не заменили")
    end
    xml_to_sa = get_encode_core_request(functional, @xml_from_ia, decode_rexml_request.to_s)
    $egg_integrator.send_to_core(xml_to_sa, $egg_integrator.core_in_ufebs_gmp_smev3.first[:correlation_id])
    $log_egg.write_to_browser("Изменили в XML Id и отправили в ядро")
    $log_egg.write_to_log(functional, "Изменили в XML Id и отправили в ядро", xml_to_sa)
    $egg_integrator.core_in_ufebs_gmp_smev3.clear
  end

  def ed101_test
    sleep 1.5
    begin
      count = 1
      until @result["ed101_test"] == "true" or count > @try_count
        xml_name = 'ed101'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED101'
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
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = @edno_ed101
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        if !validate_egg_xml(xsd, xml_rexml.to_s, functional)
          @result["ed101_test"] = "false"
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          return
        end
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_id(functional, 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1') # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
        answer = ufebs_file_count(functional, false, 'gis_gmp_smev3')
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
          @result["ed101_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
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
        count +=1
      end
    rescue Exception => msg
      @result["ed101_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

    def ed104_test
    sleep 1.5
    begin
      count = 1
      until @result["ed104_test"] == "true" or count > @try_count
        xml_name = 'ed104'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED104'
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
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_id(functional, 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1') # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
        answer = ufebs_file_count(functional, false, 'gis_gmp_smev3')
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
          @result["ed104_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        elsif answer.first == 0 and answer.last == 0
          @result["ed104_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result["ed104_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["ed104_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

  def ed105_test
    sleep 1.5
    begin
      count = 1
      until @result["ed105_test"] == "true" or count > @try_count
        xml_name = 'ed105'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED105'
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
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_id(functional, 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1') # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
        answer = ufebs_file_count(functional, false, 'gis_gmp_smev3')
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
          @result["ed105_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        elsif answer.first == 0 and answer.last == 0
          @result["ed105_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result["ed105_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["ed105_test"] = "false"
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
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED108'
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
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['ChargeOffDate'] = date
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDDate'] = date
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['FileDate'] = date
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['ReceiptDate'] = date
        xml_rexml.elements["//ed:AccDoc"].attributes['AccDocDate'] = date
        xml_rexml.elements["//ed:CreditTransferTransactionInfo"].attributes['PayerDocDate'] = date
        xml_rexml.elements["//ed:CreditTransferTransactionInfo"].attributes['TransactionDate'] = date
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_id(functional, 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1') # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
        answer = ufebs_file_count(functional, false, 'gis_gmp_smev3')
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
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
        count +=1
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
        functional = "Проверка ИА УФЭБС (ГИС ГМП СМЭВ3). #{xml_name}"
        xml_root_element = 'PacketEPD'
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
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//ed:ED101"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//ed:ED104"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//ed:ED105"].attributes['EDNo'] = Random.rand(1000..50000)
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
          $egg_integrator.core_in_ufebs_gmp_smev3.any? ? (break) : (sleep 1)
        end

        if $egg_integrator.core_in_ufebs_gmp_smev3.any?
          sleep 3
          $egg_integrator.core_in_ufebs_gmp_smev3.each do |request|
            @xml_from_ia = request[:body]
            $log_egg.write_to_browser("Перехватили сообщение от ИА к ядру. CorrelationID: #{request[:correlation_id]}")
            $log_egg.write_to_log(functional, "Перехватили сообщение от ИА к ядру. CorrelationID: #{request[:correlation_id]}", @xml_from_ia)
            decode_rexml_request = get_decode_core_request(@xml_from_ia)
            decode_rexml_request.elements['//p1:ImportedPayment'].attributes['Id'] = 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1'
            xml_to_sa = get_encode_core_request(functional, @xml_from_ia, decode_rexml_request.to_s)
            $egg_integrator.send_to_core(xml_to_sa, request[:correlation_id])
            $log_egg.write_to_browser("Изменили в XML Id и отправили в ядро")
            $log_egg.write_to_log(functional, "Изменили в XML Id и отправили в ядро", xml_to_sa)
            sleep 2
            change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
          end
          $egg_integrator.core_in_ufebs_gmp_smev3.clear
        else
          $log_egg.write_to_browser("Сообщение не дошло до ядра")
          $log_egg.write_to_log(functional, "Проверка сообщения в очереди core_sa", "Сообщение не дошло до ядра")
          return
          # count +=1
          # next
        end
        #########################################################
        answer = ufebs_file_count(functional, true, 'gis_gmp_smev3')
        if answer.first == 3 and answer.last == 3
          @result["packetepd_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
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
        count +=1
      end
    rescue Exception => msg
      @result["packetepd_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

  def ed101_change
    sleep 1.5
    begin
      count = 1
      until @result["ed101_change"] == "true" or count > @try_count
        xml_name = 'change_ed101'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED101'
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}. #{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/#{@ufebs_version}/cbr_ed101_v#{@ufebs_version}.xsd"
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = @edno_ed101
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        if !validate_egg_xml(xsd, xml_rexml.to_s, functional)
          @result["ed101_change"] = "false"
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          return
        end
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_id(functional, 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1') # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
        answer = ufebs_file_count(functional, false, 'gis_gmp_smev3')
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
          @result["ed101_change"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        elsif answer.first == 0 and answer.last == 0 # Если ничего не нашли в каталоге
          @result["ed101_change"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0 # Если получили только ответ от адаптера (ADPS000), а не от СМЭВ
          @result["ed101_change"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["ed101_change"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

  def ed101_delete
    sleep 1.5
    begin
      count = 1
      until @result["ed101_delete"] == "true" or count > @try_count
        xml_name = 'delete_ed101'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED101'
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}. #{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/#{@ufebs_version}/cbr_ed101_v#{@ufebs_version}.xsd"
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = @edno_ed101
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        if !validate_egg_xml(xsd, xml_rexml.to_s, functional)
          @result["ed101_delete"] = "false"
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          return
        end
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_id(functional, 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1') # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
        answer = ufebs_file_count(functional, false, 'gis_gmp_smev3')
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
          @result["ed101_delete"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        elsif answer.first == 0 and answer.last == 0 # Если ничего не нашли в каталоге
          @result["ed101_delete"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0 # Если получили только ответ от адаптера (ADPS000), а не от СМЭВ
          @result["ed101_delete"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["ed101_delete"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

  def ed101_change_delete
    sleep 1.5
    begin
      count = 1
      until @result["ed101_change_delete"] == "true" or count > @try_count
        xml_name = 'change_delete_ed101'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED101'
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{xml_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{@menu_name}. #{xml_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: @category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml_rexml = Document.new(xml.xml_text)
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/#{@ufebs_version}/cbr_ed101_v#{@ufebs_version}.xsd"
        xml_rexml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = @edno_ed101
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        if !validate_egg_xml(xsd, xml_rexml.to_s, functional)
          @result["ed101_change_delete"] = "false"
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
          return
        end
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        change_id(functional, 'I_09bcf2c6-a08a-4ea2-959d-8e198ba689d1') # Перехватываем сообщение до ядра и меняем Id на entityId ответа из заглушки
        change_smevmessageid_gis_gmp(Document.new(@xml_from_ia), '3fc2ba3d-8c27-11e9-aab8-005056b6497f', functional, true)
        answer = ufebs_file_count(functional, false, 'gis_gmp_smev3')
        if answer.first == 1 and answer.last == 1 # Если нашли в каталоге 1 файл со статусом ADPS000 (Принят адаптером) и 1 файл со статусом ADPS001 (Принят СМЭВ), считаем, что все ок.
          @result["ed101_change_delete"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        elsif answer.first == 0 and answer.last == 0 # Если ничего не нашли в каталоге
          @result["ed101_change_delete"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0 # Если получили только ответ от адаптера (ADPS000), а не от СМЭВ
          @result["ed101_change_delete"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["ed101_change_delete"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка!", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

end
