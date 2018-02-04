include TirAutotests
require 'open3'
require 'net/http'

class TirAutoTestsController < ApplicationController
  def index
    $browser = Hash.new
    $browser[:event] = ''
    $browser[:message] = ''
    @tir22_components= ['Проверка адаптера Active MQ',
                        'Проверка адаптера HTTP',
                        'Проверка компонента БД',
                        'Проверка компонента File',
                        'Проверка компонента Active MQ',
                        'Проверка компонента трансформации',
                        'Проверка компонента WebServiceProxy',
                        'Проверка компонента Base64 (WebServiceProxy)']
    @tir23_components = Array.new(@tir22_components)
    @tir23_components.push('Проверка OpenNMS')
  end
  def run
    begin
      response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:tir_version] == 'ТИР 2.2' and tests_params[:functional_tir22].nil?
      response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:tir_version] == 'ТИР 2.3' and tests_params[:functional_tir23].nil?
      Dir.chdir "#{Rails.root}"
      log_file_name = "log_tir_autotests_#{Time.now.strftime('%H-%M-%S')}.txt"
      $log = Logger.new(File.open("log\\#{log_file_name}", 'w'))
      startTime = Time.now
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
      send_to_log("Done! Запустили ServiceMix", "Done! Запустили ServiceMix")
      send_to_log("#{puts_line}", "#{puts_line}")
      if tests_params[:tir_version] == 'ТИР 2.2'
        send_to_log("Запустили тесты ТИР 2.2", "Запустили тесты ТИР 2.2")
        runTest(tests_params[:functional_tir22])
      elsif tests_params[:tir_version] == 'ТИР 2.3'
        send_to_log("Запустили тесты ТИР 2.3", "Запустили тесты ТИР 2.3")
        runTest(tests_params[:functional_tir23])
      end
      send_to_log("#{puts_line}", "#{puts_line}")
      delete_rows_from_db
      stop_amq(tests_params[:tir_dir])
      sleep 1
      stop_servicemix(tests_params[:tir_dir])
    ensure
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
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :tir_dir, :functional_tir22 => [], :functional_tir23 => [])
  end