include TirAutoTestsHelper
module TirAutotests
  def runTest(components)
    if components.include?('Test1')
      xml = Xml.find(10000)
      manager = QueueManager.find(10042)
      puts xml.xml_name, manager.manager_name
    end
  end
end