include TirAutoTestsHelper
require 'rexml/document'
include REXML

module TirAutotests
  def runTest(components)
    if components.include?('Проверка адаптера БД')
      xml = Xml.find(10000)
      manager = QueueManager.find(10042)
      answer = send_to_amq(manager, xml)
      answer = Document.new(answer) if !answer.nil?
      puts answer
      puts "yes" if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
    end
  end
end