include TirAutotests
require 'open3'
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
    response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:tir_version] == 'ТИР 2.2' and tests_params[:functional_tir22].nil?
    response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:tir_version] == 'ТИР 2.3' and tests_params[:functional_tir23].nil?
    log_file_name = "log_tir_autotests_#{Time.now.strftime('%H-%M-%S')}.txt"
    $log = Logger.new(File.open("log\\#{log_file_name}", 'w'))
    startTime = Time.now
    end_test(log_file_name) and return if dir_empty?(tests_params[:tir_dir])
    send_to_log("#{puts_line}", "#{puts_line}")
    sleep 0.5
    end_test(log_file_name) and return if db_not_empty?
    send_to_log("#{puts_line}", "#{puts_line}")
    sleep 0.5
    add_test_data_in_db
    send_to_log("#{puts_line}", "#{puts_line}")
    if tests_params[:tir_version] == 'ТИР 2.2'
      send_to_log("Запустили тесты ТИР 2.2", "Запустили тесты ТИР 2.2")
      runTest(tests_params[:functional_tir22])
    elsif tests_params[:tir_version] == 'ТИР 2.3'
      send_to_log("Запустили тесты ТИР 2.3", "Запустили тесты ТИР 2.3")
      runTest(tests_params[:functional_tir23])
    end
    send_to_log("#{puts_line}", "#{puts_line}")
    end_test(log_file_name, startTime)
  end
  def live_stream
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 200)
    sse.write "#{$browser[:message]}", event: "update_log"
    if $browser[:event] == 'colorize'
      sse.write "#{$browser[:functional]}, #{$browser[:color]}", event: "#{$browser[:event]}"
      $browser[:event] = ''
    end
    $browser[:message] =''
  ensure
    sse.close
  end
  def download_log
    send_file "log\\#{params[:filename]}"
  end
  def tester
    #wait_thr = Open3.popen3('C:\TIR22\apache-activemq-5.11.1\bin\startcrypt.bat') do |i, o, e, w|
    # user_input = "hello"
    # output, status = Open3.capture2('C:\TIR22\apache-activemq-5.11.1\bin\startcrypt.bat', user_input)
    # puts output            # -> "hello; rm -rf *\n"
    # puts status.pid        # 123 or the process id
    # puts status.exitstatus # 0
    # Process.kill("KILL",status.pid)
    IO.popen("cmd", "r+") do |io|

      # io.puts "ls -l"
      io.puts "dir"
      io.puts "exit"
      io.close_write
    end
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :tir_dir, :functional_tir22 => [], :functional_tir23 => [])
  end