class CcFormatValidatorController < ApplicationController
  include CcFormatValidatorHelper

  def index
    @validator_log = CcFormatValidatorLog.all
  end

  def start
    $thread = Thread.new do
      while true
        xml = receive_xml
        if xml
          validate_cc_xml(xml)
        end
        sleep 5
      end
    end
  end

  def stop
    $thread.kill
  end

  def clear_log
    CcFormatValidatorLog.delete_all
#     string = <<EOF
# <StatementRequest xmlns="http://bssys.com/sbns/integration">
# 	<branchExtId>8</branchExtId>
# 	<docId>e8a5aff6-c054-41cd-826b-adbb1b7888b0</docId>
# 	<fromDate>2018-02-22</fromDate>
# 	<orgExtId>8000319</orgExtId>
# 	<orgId>84158069-a99a-43ae-9bee-0bf9c1ea6b6b</orgId>
# 	<orgInn>4028001072</orgInn>
# 	<orgLegacyId>8000319</orgLegacyId>
# 	<orgName>Организация</orgName>
# 	<sysCreateTime>2018-02-28T12:24:12.425+03:00</sysCreateTime>
# 	<toDate>2018-02-22</toDate>
# 	<accounts>
# 		<Acc>
# 			<account>40702810800010000001</account>
# 			<bankBIC>042908770</bankBIC>
# 		</Acc>
# 	</accounts>
# </StatementRequest>
# EOF
#     xml = Document.new(string)
#     puts xml.elements[1].name
  end
end
