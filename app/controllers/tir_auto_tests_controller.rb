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
    java_import 'oracle.jdbc.OracleDriver'
    java_import 'java.sql.DriverManager'
    e = Element.new 'tns:jmsAdapter'
    e.add_element 'tns:ActiveMQ', {'alias'=>'tir',
                                   'name'=>'tir_in5',
                                   'concurrentConsumers' => '10',
                                   'maxConnections' => '10',
                                   'sleep' => 'false',
                                   'sleepConfirm' => 'true',
                                   'active' => 'true',
                                   'persistent' => 'true',
                                   'xmlversion' => '1.1',
                                   'brokerURL' => 'tcp://localhost:61617',
                                   'username' => 'admin',
                                   'password' => 'admin'}
    exist_settings = String.new
    url = "jdbc:oracle:thin:@vm-corint:1521:corint"
    connection = java.sql.DriverManager.getConnection(url, "tir_vmcorint", "tir_vmcorint");
    select_stmt = connection.create_statement
    rs=select_stmt.execute_query("select value from sys_properties where name = 'jmsAdapterSettingsTemplate.xml'")
    while(rs.next())
      tir_amq_settings = rs.getString("value") # get first column
    end

    tir_amq_settings = Document.new(tir_amq_settings)
    tir_amq_settings.elements.each('//tns:ActiveMQ'){|e| exist_settings << e.attributes["name"] if e.attributes["name"] == "tir_in3"}
    if exist_settings.empty?
      tir_amq_settings.elements['//tns:jmsAdapterSettingsTemplate'].add_element(e)
    end
    # query = %{update sys_properties
    #            set value = to_clob(q'[#{tir_amq_settings}]')
    #            where name = 'jmsAdapterSettingsTemplate.xml'}
    query = %Q{DECLARE
                v_long_text CLOB;
              BEGIN
                v_long_text := q'[#{tir_amq_settings}]';
                update sys_properties
                set value = v_long_text
                where name = 'jmsAdapterSettingsTemplate.xml';
              END;}
    rs=select_stmt.execute_query(query)
    select_stmt.close
    connection.close
    rs.close
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :functional_tir22 => [], :functional_tir23 => [])
  end