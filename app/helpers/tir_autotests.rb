include TirAutoTestsHelper
require 'rexml/document'
include REXML

module TirAutotests
  def runTest(components)
    if components.include?('Проверка адаптера БД')
      begin
        send_to_log("Начали проверку адаптера БД")
        xml = Xml.find(10000)
        manager = QueueManager.find(10042)
        answer = send_to_amq(manager, xml)
        answer = Document.new(answer) if !answer.nil?
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!")
        else
          send_to_log("Проверка не пройдена!")
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}")
      end
    end
  end
end