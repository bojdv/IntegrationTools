class SQL_query
  class << self
    # db_name - инициализируем переменную класса
    # db_type - берем из контроллера при запуске тестов

    java_import 'oracle.jdbc.OracleDriver'
    require "sqljdbc4-4.1.jar"
    java_import 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
    java_import 'java.sql.DriverManager'

    attr_accessor :db_name, :db_type

    def connection_url
      case db_type
      when 'Oracle 11G'
        "jdbc:oracle:thin:#{db_name}/#{db_name}@vm-corint:1521:corint"
      when 'SQL Server 2012'
        "jdbc:sqlserver://vm-corint:1434;databaseName=#{db_name};user=sa;password=1qaz2WSX"
      when 'SQL Server 2014'
        "jdbc:sqlserver://vm-corint2:1433;databaseName=#{db_name};user=sa;password=1qaz2WSX"
      when 'SQL Server 2016'
        "jdbc:sqlserver://vmns-test2:1433;databaseName=#{db_name};user=sa;password=1qaz2WSX"
      end
    end

    def connection_root_url
      case db_type
      when 'Oracle 11G'
        "jdbc:oracle:thin:sys as sysdba/waaaaa@vm-corint:1521:corint"
      when 'SQL Server 2012'
        "jdbc:sqlserver://vm-corint:1434;user=sa;password=1qaz2WSX"
      when 'SQL Server 2014'
        "jdbc:sqlserver://vm-corint2:1433;user=sa;password=1qaz2WSX"
      when 'SQL Server 2016'
        "jdbc:sqlserver://vmns-test2:1433;user=sa;password=1qaz2WSX"
      end
    end

    def create_mssql_db(functional)
      url = connection_root_url
      run_create_mssql_db(functional, url)
    end

    def drop_db(functional)
      case db_type
      when 'Oracle 11G'
        drop_oracle_db(functional, connection_root_url)
      when 'SQL Server 2012'
        drop_mssql_db(functional, connection_root_url)
      when 'SQL Server 2016'
        drop_mssql_db(functional, connection_root_url)
      end
    end

    def run_create_mssql_db(functional, url)
      begin
        connection = java.sql.DriverManager.getConnection(url);
        stmt = connection.create_statement
        stmt.execute("CREATE DATABASE #{db_name}")
        $log_egg.write_to_browser("Создали БД #{db_type} '#{db_name}' с параметрами: #{SQL_query.connection_url}")
        $log_egg.write_to_log(functional, "Результат создания БД '#{db_name}'", "Создали БД #{db_type} '#{db_name}' с параметрами: #{SQL_query.connection_url}")
      rescue Exception => msg
        puts msg
        puts msg.backtrace.join("\n")
      ensure
        stmt.close if stmt
        connection.close if connection
      end
    end

    def drop_mssql_db(functional, connection_url)
      begin
        connection = java.sql.DriverManager.getConnection(connection_url);
        stmt = connection.create_statement
        query = <<-QUERY
USE master
IF EXISTS(select * from sys.databases where name='#{db_name}')
DROP DATABASE #{db_name}
        QUERY
        stmt.execute(query)
      rescue Exception => msg
        puts msg
        puts msg.backtrace.join("\n")
        $log_egg.write_to_browser("Ошибка! #{msg}")
        $log_egg.write_to_log(functional, "Ошибка при удалении БД '#{db_name}'", "#{msg}")
      ensure
        stmt.close if stmt
        connection.close if connection
      end
      $log_egg.write_to_browser("Удалили БД '#{db_name}'")
      $log_egg.write_to_log(functional, "Результат удаления БД '#{db_name}'", "Done!")
    end

    def drop_oracle_db(functional, connection_root_url)
      begin
        $log_egg.write_to_browser("Удаляем БД '#{db_name}'")
        $log_egg.write_to_log(functional, "Удаляем БД '#{db_name}'", "...")
        connection = java.sql.DriverManager.getConnection(connection_root_url);
        stmt = connection.create_statement
        stmt.executeUpdate(%Q{BEGIN
  EXECUTE IMMEDIATE 'DROP USER #{db_name} cascade';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1918 THEN
      RAISE;
    END IF;
END;})
      rescue Exception => msg
        $log_egg.write_to_browser("Ошибка! #{msg}")
        $log_egg.write_to_log(functional, "Ошибка при удалении БД '#{db_name}'", "#{msg}")
        return true
      ensure
        stmt.close
        connection.close
      end
      sleep 0.5
      $log_egg.write_to_browser("Удалили БД '#{db_name}'")
      $log_egg.write_to_log("Завершение тестов", "Результат удаления БД '#{db_name}'", "Done!")
    end
  end

  # SQL запросы для автотестов в переменной экземпляре класса SQL_query

  def initialize
    @dbname = self.class.db_name
    @stmt, @connection = make_connection
  end

  def make_connection
    url = self.class.connection_url
    connection = java.sql.DriverManager.getConnection(url);
    stmt = connection.create_statement
    return stmt, connection
  rescue Exception => msg
    puts msg
    puts msg.backtrace.join("\n")
    stmt.close if stmt
    connection.close if connection
  end

  def close_connection
    @stmt.close if @stmt
    @connection.close if @connection
  end

  def insert_inn # Метод вставляет в таблицу zkh_inn запись с поставщиком для тестов. Ничего не возвращает.
    begin
      @stmt.executeUpdate("insert into zkh_inn (inn, kpp, name, account, bank_name, bank_bik) values (9909400765, 774763002, 'ООО Межгосударственный банк', 30301810000006000001, 'ПАО СБЕРБАНК', '044525225')")
    ensure
      close_connection
    end
  end

  def insert_ZKH_SMEV3(functional)# Метод заполняет Реестр получателей платежей ГИС ЖКХ СМЭВ3. Ничего не возвращает.
    begin
      # Вставка записи в таблицу ZKH_SMEV3_PAYMENT_RECEIVER
      rs = @stmt.executeQuery("select OGRN from ZKH_SMEV3_PAYMENT_RECEIVER")
      unless rs.isBeforeFirst()
        row_insert = @stmt.executeUpdate("INSERT INTO ZKH_SMEV3_PAYMENT_RECEIVER (OGRN, INN, KPP, NAME, REC_DATECREATE, REC_DATEUPDATE) VALUES ('1234567890123', '1234567890', '123456789', 'Получатель', TO_DATE('29.01.19', 'DD.MM.RR'), TO_DATE('29.01.19', 'DD.MM.RR'))")
      end
      if row_insert == 1
        $log_egg.write_to_browser("Вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER")
        $log_egg.write_to_log(functional, "Вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER", "INSERT INTO ZKH_SMEV3_PAYMENT_RECEIVER (OGRN, INN, KPP, NAME, REC_DATECREATE, REC_DATEUPDATE) VALUES ('1234567890123', '1234567890', '123456789', 'Получатель', TO_DATE('29.01.19', 'DD.MM.RR'), TO_DATE('29.01.19', 'DD.MM.RR'))")
      else
        $log_egg.write_to_browser("Не вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER, т к она уже существует")
        $log_egg.write_to_log(functional, "Не вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER, т к она уже существует", "INSERT INTO ZKH_SMEV3_PAYMENT_RECEIVER (OGRN, INN, KPP, NAME, REC_DATECREATE, REC_DATEUPDATE) VALUES ('1234567890123', '1234567890', '123456789', 'Получатель', TO_DATE('29.01.19', 'DD.MM.RR'), TO_DATE('29.01.19', 'DD.MM.RR'))")
      end
      # Вставка записи в таблицу ZKH_SMEV3_PAYMENT_RECEIVER_INF
    rs = @stmt.executeQuery("select PAYMENT_RECEIVER_OGRN from ZKH_SMEV3_PAYMENT_RECEIVER_INF")
    unless rs.isBeforeFirst()
      row_insert = @stmt.executeUpdate("INSERT INTO ZKH_SMEV3_PAYMENT_RECEIVER_INF (GUID, UPDATEDATE, RECIPIENT_INN, RECIPIENT_KPP, BANK_NAME, PAYMENT_RECIPIENT, BIK, OPERATING_ACCOUNT, CORRESPONDENT_ACCOUNT, KBK, OKTMO, NUMBER_BUDGETARY_ACCOUNT, IS_CAPITAL_REPAIR, PAYMENT_RECEIVER_OGRN, REC_DATECREATE, REC_DATEUPDATE) VALUES ('1', TO_DATE('29.01.19', 'DD.MM.RR'), '1234512345', '987654321', 'СБЕРБАНК', 'получатель', '044525225', '30301810000006000001', '30301810000006000002', '18210202131061010160', '87654321', '30301810000006000003', '1', '1234567890123', TO_DATE('29.01.19', 'DD.MM.RR'), TO_DATE('29.01.19', 'DD.MM.RR'))")
    end
    if row_insert == 1
      $log_egg.write_to_browser("Вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER_INF")
      $log_egg.write_to_log(functional, "Вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER_INF", "INSERT INTO ZKH_SMEV3_PAYMENT_RECEIVER_INF (GUID, UPDATEDATE, RECIPIENT_INN, RECIPIENT_KPP, BANK_NAME, PAYMENT_RECIPIENT, BIK, OPERATING_ACCOUNT, CORRESPONDENT_ACCOUNT, KBK, OKTMO, NUMBER_BUDGETARY_ACCOUNT, IS_CAPITAL_REPAIR, PAYMENT_RECEIVER_OGRN, REC_DATECREATE, REC_DATEUPDATE) VALUES ('1', TO_DATE('29.01.19', 'DD.MM.RR'), '1234512345', '987654321', 'СБЕРБАНК', 'получатель', '044525225', '30301810000006000001', '30301810000006000002', '18210202131061010160', '87654321', '30301810000006000003', '1', '1234567890123', TO_DATE('29.01.19', 'DD.MM.RR'), TO_DATE('29.01.19', 'DD.MM.RR'))")
    else
      $log_egg.write_to_browser("Не вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER_INF, т к она уже существует")
      $log_egg.write_to_log(functional, "Не вставили запись в таблицу ZKH_SMEV3_PAYMENT_RECEIVER_INF, т к она уже существует", "INSERT INTO ZKH_SMEV3_PAYMENT_RECEIVER_INF (GUID, UPDATEDATE, RECIPIENT_INN, RECIPIENT_KPP, BANK_NAME, PAYMENT_RECIPIENT, BIK, OPERATING_ACCOUNT, CORRESPONDENT_ACCOUNT, KBK, OKTMO, NUMBER_BUDGETARY_ACCOUNT, IS_CAPITAL_REPAIR, PAYMENT_RECEIVER_OGRN, REC_DATECREATE, REC_DATEUPDATE) VALUES ('1', TO_DATE('29.01.19', 'DD.MM.RR'), '1234512345', '987654321', 'СБЕРБАНК', 'получатель', '044525225', '30301810000006000001', '30301810000006000002', '18210202131061010160', '87654321', '30301810000006000003', '1', '1234567890123', TO_DATE('29.01.19', 'DD.MM.RR'), TO_DATE('29.01.19', 'DD.MM.RR'))")
    end
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Завершение тестов", "Ошибка при вставке записи в таблицу ZKH_SMEV3_PAYMENT_RECEIVER_INF", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
    ensure
      close_connection
    end
    end

  def change_smevmessageid(xml_rexml, smev_id, functional) # метод меняет id для запросов в СМЭВ3
    begin
      process_id = xml_rexml.elements["//mq:RequestMessage"].attributes["processID"]
      result = 0
      count = 30
      while result == 0 # 0, if no rows are affected by the operation.
        result = @stmt.executeUpdate("UPDATE EGG_SMEV3_CONTEXT SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
        sleep 1
        puts count -=1
        return nil if count == 0
      end
      $log_egg.write_to_browser("Заменили id в SMEVMESSAGEID на #{smev_id}")
      $log_egg.write_to_log(functional, "Заменили id в SMEVMESSAGEID", "UPDATE EGG_SMEV3_CONTEXT SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Завершение тестов", "Ошибка при замене SMEVMESSAGEID", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
    ensure
      close_connection
    end
  end

  def change_smevmessageid_gis_gmp(xml_rexml, smev_id, functional, ufebs = false) # метод меняет id для запросов ГИС ГМП в СМЭВ3
    begin
      if ufebs
        process_id = xml_rexml.elements["//tns:Request"].attributes["processId"]
      else
        process_id = xml_rexml.elements["//mq:RequestMessage"].attributes["processID"]
      end
      row_updated = 0
      count = 30
      while row_updated.zero?
        rs = @stmt.executeQuery("select SMEVMESSAGEID from FK_SMEV3 WHERE PROCESSID = '#{process_id}'")
        if rs.isBeforeFirst()
          while rs.next() do
            check_null = rs.getString('SMEVMESSAGEID')
          end
          if check_null
            row_updated = @stmt.executeUpdate("UPDATE FK_SMEV3 SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
            if row_updated == 1
              $log_egg.write_to_browser("Заменили id в SMEVMESSAGEID на #{smev_id}")
              $log_egg.write_to_log(functional, "Заменили id в SMEVMESSAGEID", "UPDATE FK_SMEV3 SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
            end
          end
        end
        if count == 0
          $log_egg.write_to_browser("Не заменили id в SMEVMESSAGEID")
          $log_egg.write_to_log(functional, "Не заменили id в SMEVMESSAGEID", "UPDATE FK_SMEV3 SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
          return nil
        end
        puts count -=1
        sleep 0.5
      end
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Завершение тестов", "Ошибка при замене SMEVMESSAGEID", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
    ensure
      close_connection
    end
  end

  def change_smevmessageid_gis_zkh(xml_rexml, smev_id, functional, ufebs = false) # метод меняет id для запросов ГИС ЖКХ в СМЭВ3
    begin
      if ufebs
        process_id = xml_rexml.elements["//tns:Request"].attributes["processId"]
      else
        process_id = xml_rexml.elements["//mq:RequestMessage"].attributes["processID"]
      end
      row_updated = 0
      count = 30
      while row_updated.zero?
        rs = @stmt.executeQuery("select SMEVMESSAGEID from ZKH_SMEV3 WHERE PROCESSID = '#{process_id}'")
        if rs.isBeforeFirst()
          while rs.next() do
            check_null = rs.getString('SMEVMESSAGEID')
          end
          if check_null
            row_updated = @stmt.executeUpdate("UPDATE ZKH_SMEV3 SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
            if row_updated == 1
              $log_egg.write_to_browser("Заменили id в SMEVMESSAGEID на #{smev_id}")
              $log_egg.write_to_log(functional, "Заменили id в SMEVMESSAGEID", "UPDATE ZKH_SMEV3 SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
            end
          end
        end
        if count == 0
          $log_egg.write_to_browser("Не заменили id в SMEVMESSAGEID")
          $log_egg.write_to_log(functional, "Не заменили id в SMEVMESSAGEID", "UPDATE ZKH_SMEV3 SET SMEVMESSAGEID = '#{smev_id}' WHERE PROCESSID = '#{process_id}'")
          return nil
        end
        puts count -=1
        sleep 0.5
      end
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log("Завершение тестов", "Ошибка при замене SMEVMESSAGEID", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
    ensure
      close_connection
    end
  end

  def check_provider_file(functional)
    begin
      inn = Array.new
      count = 60
      $log_egg.write_to_browser("Ждем появления поставщика в таблице zkh_inn в течении #{count} секунд")
      $log_egg.write_to_log(functional, "Ожидаем импорт", "Ждем появления поставщика в таблице zkh_inn в течении #{count} секунд")
      until inn.include?('9999999999') or count < 0
        org = @stmt.execute_query("select * from zkh_inn")
        while (org.next()) do
          inn << org.getString('inn')
        end
        count -= 1
        sleep 1
      end
    ensure
      close_connection
      return inn
    end
  end

  def check_provider_mq(functional)
    begin
      inn = Array.new
      count = 200
      $log_egg.write_to_browser("Ждем появления поставщика в таблице zkh_inn в течении #{count} секунд")
      $log_egg.write_to_log(functional, "Ожидаем импорт", "Ждем появления поставщика в таблице zkh_inn в течении #{count} секунд")
      until inn.include?('7707083893') or count < 0
        org = @stmt.execute_query("select bank_inn from zkh_inn where bank_name = 'ПАО СБЕРБАНК'")
        while (org.next()) do
          inn << org.getString('bank_inn')
          puts inn
        end
        count -= 1
        sleep 1
      end
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Случилось непредвиденное:(", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
    ensure
      close_connection
      return inn
    end
  end
end
