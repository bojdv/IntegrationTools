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
        if answer
          answer = Document.new(answer)
          if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
            send_to_log("Проверка пройдена!")
            colorize('Проверка адаптера БД', '#b3ffcc')
          else
            send_to_log("Проверка не пройдена!")
            colorize('Проверка адаптера БД', '#ff3333')
          end
        else
          send_to_log("Похоже, не получили ответ:(")
          colorize('Проверка адаптера БД', '#ff3333')
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}")
      end
    end
    if components.include?('Проверка адаптера Active MQ')
      begin
        sleep 1
        send_to_log("Начали проверку адаптера Active MQ")
        xml = Xml.find(10000)
        manager = QueueManager.find(10042)
        answer = send_to_amq(manager, xml)
        if answer
          answer = Document.new(answer)
          if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
            send_to_log("Проверка пройдена!")
            colorize('Проверка адаптера Active MQ', '#b3ffcc')
          else
            send_to_log("Проверка не пройдена!")
            colorize('Проверка адаптера Active MQ', '#ff3333')
          end
        else
          send_to_log("Похоже, не получили ответ:(")
          colorize('Проверка адаптера Active MQ', '#ff3333')
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}")
      end
    end
  end
end