include TirAutotests
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
    log_file_name = "log_tir_autotests_#{Time.now.strftime('%H-%M-%S')}.txt"
    $log = Logger.new(File.open("log\\#{log_file_name}", 'w'))
    startTime = Time.now
    if tests_params[:tir_version] == 'ТИР 2.2'
      response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:functional_tir22].nil?
      send_to_log("Запустили тесты ТИР 2.2", "Запустили тесты ТИР 2.2")
      runTest(tests_params[:functional_tir22])
    elsif tests_params[:tir_version] == 'ТИР 2.3'
      response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:functional_tir23].nil?
      send_to_log("Запустили тесты ТИР 2.3", "Запустили тесты ТИР 2.3")
      runTest(tests_params[:functional_tir23])
    end
    endTime = Time.now
    send_to_log("#{puts_line}", "#{puts_line}")
    puts_time(startTime, endTime)
    sleep 1
    $browser[:message].clear
    $log.close
    respond_to do |format|
      format.js { render :js => "kill_listener(); download_link('#{log_file_name}')" }
    end
  end
  def tester
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
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :functional_tir22 => [], :functional_tir23 => [])
  end