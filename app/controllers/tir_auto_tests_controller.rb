include TirAutotests
require 'open3'
require 'net/http'
require 'net/ftp'
require 'zip'

class TirAutoTestsController < ApplicationController
  def index
    @tir23_components= ['Проверка адаптера Active MQ',
                        'Проверка адаптера HTTP',
                        'Проверка компонента БД',
                        'Проверка компонента File',
                        'Проверка компонента Active MQ',
                        'Проверка компонента трансформации',
                        'Проверка компонента WebServiceProxy',
                        'Проверка компонента Base64 (WebServiceProxy)']
    @tir24_components = Array.new(@tir23_components)
    @tir24_components.push('Проверка OpenNMS')
    regex = /\A[2]{,1}[.][4]{,1}[.][\d]{,2}\Z/
    ftp = Net::FTP.new('server-ora-bssi')
    ftp.login
    @dir = []
    ftp.chdir('build-release/tir-installer/')
    ftp.nlst.each do |line|
      if line.match(regex)
        @dir << line
      end
    end
    end
  def run
    $browser = Hash.new
    $browser[:event] = ''
    $browser[:message] = ''
    response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:tir_version] == 'ТИР 2.3' and tests_params[:functional_tir23].nil?
    response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:tir_version] == 'ТИР 2.4' and tests_params[:functional_tir24].nil?
    begin
      @build_file = "#{Rails.root}/tir-installer-#{tests_params[:build_version]}.zip"
      @installer_path = "C:/TIR_Installer/TIR-#{tests_params[:build_version]}-installer-windows.exe"
      Dir.chdir "#{Rails.root}"
      log_file_name = "log_tir_autotests_#{Time.now.strftime('%H-%M-%S')}.txt"
      $log = Logger.new(File.open("log\\#{log_file_name}", 'w'))
      startTime = Time.now
      if !tests_params[:build_version].empty?
        download_installer
        copy_installer
        send_to_log("Устанавливаем ТИР #{tests_params[:build_version]}...", "Устанавливаем ТИР #{tests_params[:build_version]}...")
        system("#{@installer_path} --optionfile #{Rails.root}/lib/tir_db_data/options24.txt")
      end
      return if dir_empty?(tests_params[:tir_dir])
      send_to_log("#{puts_line}", "#{puts_line}")
      sleep 0.5
      return if db_not_empty?
      send_to_log("#{puts_line}", "#{puts_line}")
      sleep 0.5
      copy_webserviceproxy(tests_params[:tir_dir])
      send_to_log("#{puts_line}", "#{puts_line}")
      add_test_data_in_db
      send_to_log("#{puts_line}", "#{puts_line}")
      start_amq(tests_params[:tir_dir])
      sleep 1
      start_servicemix(tests_params[:tir_dir])
      n = 0
      until ping_server("http://localhost:8161")
        sleep 1
        n += 1
        return if n > 60
      end
      send_to_log("Done! Запустили Active MQ", "Done! Запустили Active MQ")
      n = 0
      until ping_server("http://localhost:1234")
        sleep 1
        n += 1
        return if n > 90
      end
      sleep 3
      send_to_log("Done! Запустили ServiceMix", "Done! Запустили ServiceMix")
      send_to_log("#{puts_line}", "#{puts_line}")
      if tests_params[:tir_version] == 'ТИР 2.3'
        send_to_log("Запустили тесты ТИР 2.3", "Запустили тесты ТИР 2.3")
        runTest(tests_params[:functional_tir23])
      elsif tests_params[:tir_version] == 'ТИР 2.4'
        send_to_log("Запустили тесты ТИР 2.4", "Запустили тесты ТИР 2.4")
        runTest(tests_params[:functional_tir24])
      end
      send_to_log("#{puts_line}", "#{puts_line}")
      delete_rows_from_db if tests_params[:dont_clear_db] == 'false'
      stop_amq(tests_params[:tir_dir]) if tests_params[:dont_stop_TIR] == 'false'
      sleep 1
      stop_servicemix(tests_params[:tir_dir]) if tests_params[:dont_stop_TIR] == 'false'
      delete_db if tests_params[:dont_drop_db] == 'false'
      send_to_log("#{puts_line}", "#{puts_line}")
    ensure
      if File.directory?('C:/TIR') && tests_params[:dont_drop_db] == 'false' # Удаляем каталог ТИР
        FileUtils.rm_r "C:/TIR/."
        send_to_log("Удалили ТИР", "Удалили ТИР")
      end
      if File.exist?(@installer_path) # Удаляем инсталлятор
        File.delete(@installer_path)
        send_to_log("Удалили инсталлятор", "Удалили инсталлятор")
      end
      end_test(log_file_name, startTime)
    end
  end
  def live_stream
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 300)
    sse.write "#{$browser[:message]}", event: "update_log"
    if $browser[:event] == 'colorize'
      sse.write "#{$browser[:tir_version]},#{$browser[:functional]},#{$browser[:color]}", event: "#{$browser[:event]}"
      $browser[:event] = ''
    end
    $browser[:message] =''
  ensure
    sse.close
  end
  def download_log
    Dir.chdir "#{Rails.root}"
    send_file "log\\#{params[:filename]}"
  end
  def tester
    puts File.directory?('C:/TIR')
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :tir_dir, :dont_clear_db, :dont_drop_db, :dont_stop_TIR, :build_version, :functional_tir23 => [], :functional_tir24 => [])
  end