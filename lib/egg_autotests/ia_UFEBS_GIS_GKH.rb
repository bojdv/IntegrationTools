
class IA_UFEBS_GIS_GKH

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count

    @menu_name = 'Проверка ИА УФЭБС (ГИС ЖКХ)'
    @category = Category.find_by_category_name('ИА УФЭБС ГИС ЖКХ')
    @dir_outbound = 'C:/data/inbox/GIS_ZKH/outbound'
    @dir_inbound = 'C:/data/inbox/GIS_ZKH/inbound'
    @result = Hash.new
    @functional = "Проверка ИА УФЭБС (ГИС ЖКХ)"
  end

  def providerCatalog_test # Справочник поставщиков
    begin
      sleep 1.5
      functional = "#{@functional}. Импорт справочника поставщиков"
      $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{functional}")
      $log_egg.write_to_browser("#{puts_line_egg}")
      $log_egg.write_to_browser("Начали проверку: #{functional}")
      catalog = "#{Rails.root}\\lib\\egg_autotests\\provider_catalog.csv"
      in_dir = "C:/tmp/files/in"
      FileUtils.cp(catalog, in_dir)
      $log_egg.write_to_log(functional, "Копируем справочник", "Скопировали справочник из каталога: #{catalog}\nВ каталог: #{in_dir}")
      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      connection = java.sql.DriverManager.getConnection(url, "egg_autotest", "egg_autotest");
      stmt = connection.create_statement
      inn = String.new
      count = 30
      until inn == '5406562465' or count < 0
        org = stmt.execute_query("select * from zkh_inn")
        while (org.next()) do
          inn << org.getString('inn')
          puts inn
        end
        count -= 1
        sleep 1
      end
      if inn == '5406562465'
        @result["providerCatalog_test"] = "true"
        $log_egg.write_to_browser("Проверка пройдена! Нашли поставщика с ИНН = 5406562465 в таблице zkh_inn")
        $log_egg.write_to_log(functional, "Проверка пройдена!", "Нашли поставщика с ИНН = 5406562465 в таблице zkh_inn")
        colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
      else
        @result["providerCatalog_test"] = "false"
        $log_egg.write_to_browser("Проверка не пройдена! Не нашли поставщика с ИНН = 5406562465 в таблице zkh_inn")
        $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не нашли поставщика с ИНН = 5406562465 в таблице zkh_inn")
        colorize_egg(@egg_version, @menu_name, @fail_menu_color)
      end
    rescue Exception => msg
      @result["providerCatalog_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Случилось непредвиденное:(", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    ensure
      stmt.close
      connection.close
    end
  end

  def ed101_test
    sleep 1.5
    begin
      count = 1
      until @result["ed101_test"] == "true" or count > @try_count
        xml_name = 'ed101'
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        xml_root_element = 'ED101'
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
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd"
        xml_rexml.elements["//#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml_rexml.elements["//#{xml_root_element}"].attributes['EDDate'] = date
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml_rexml.to_s, functional)
        FileUtils.rm_r @dir_inbound if File.directory?(@dir_inbound)# Чистим каталог для получения
        $log_egg.write_to_browser("Удалили каталог #{@dir_inbound}...")
        $log_egg.write_to_log(functional, "Удаляем каталог для отправления", "Удалили каталог #{@dir_inbound}")
        File.open("#{@dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml_rexml.to_s }
        $log_egg.write_to_browser("Положили запрос в каталог #{@dir_outbound}")
        $log_egg.write_to_log(functional, "Подкладываем запрос #{xml_name}.xml", "Положили запрос в каталог #{@dir_outbound}:\n#{xml_rexml.to_s}")
        answer = ufebs_file_count(functional, false, 'gis_zkh')
        if answer.first == 1 and answer.last == 1
          @result["ed101_test"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done!")
          colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
        elsif answer.first == 0 and answer.last == 0
          @result["ed101_test"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена! Не получили ответ от eGG")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! Не получили ответ от eGG!")
          colorize_egg(@egg_version, @menu_name, @fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
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
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd"
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
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd"
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