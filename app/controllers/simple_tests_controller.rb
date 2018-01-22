class SimpleTestsController < ApplicationController
  include SimpleTestsHelper
  require 'equivalent-xml'
  def index
    logged_in? ? @qm = QueueManager.where(user_id: current_user.id).or(QueueManager.where(visible_all: true)).order('manager_name').pluck(:manager_name) : @qm = QueueManager.where(visible_all: true).pluck(:manager_name)
    @product = Product.all.order('product_name')
    @category = Category.all.order('category_name')
  end
  def put_simple_test
    if !params[:choice_xml].empty?
      xml = Xml.find(params[:choice_xml])
      respond_to do |format|
        format.js { render :js => "updateSimpleTest('#{xml.xml_text.inspect}', '#{xml.xml_answer.inspect}')" }
      end
    end
  end
  def run_simpleTest
    if run_simpleTest_params[:all_category_test] == 'false'
      response_ajax("Не заполнены параметры:#{@empty_filds.join}") and return if !get_empty_values(run_simpleTest_params).empty?
      mode = 'single'
      xml = Xml.find(run_simpleTest_params[:choice_xml])
      simpleTest =SimpleTest.find_by_xml_id(run_simpleTest_params[:choice_xml])
      manager = QueueManager.find(simpleTest.queue_manager_id)
      if manager.manager_type == 'Active MQ'
        if manager.amq_protocol == 'OpenWire'
          send_to_amq_openwire(manager, xml, mode)
        else
          send_to_amq_stomp(manager, xml.xml_text)
        end
      else
        send_to_wmq(manager, xml.xml_text)
      end
    elsif run_simpleTest_params[:all_category_test] == 'true'
      response_ajax("Не выбрана категория") and return if run_simpleTest_params[:choice_category].empty?
      @xml_pass = Array.new
      @xml_fail = Array.new
      mode = 'all'
      xml = Xml.where(category_id: run_simpleTest_params[:choice_category]).to_a
      xml.each do |xml|
        simpleTest =SimpleTest.find_by_xml_id(xml.id)
        manager = QueueManager.find(simpleTest.queue_manager_id)
        if manager.manager_type == 'Active MQ'
          if manager.amq_protocol == 'OpenWire'
            send_to_amq_openwire(manager, xml, mode)
          else
            send_to_amq_stomp(manager, xml, mode)
          end
        else
          send_to_wmq(manager, xml, mode)
        end
      end
      response_ajax("<b>Эти XML прошли тесты:</b><br/>#{@xml_pass.join('<br/>')}<br/><b>А эти нет:</b><br/>#{@xml_fail.join('<br/>')}", 10000)
      # respond_to do |format|
      #   format.js { render :js => "updateActualXml('<b>Эти XML прошли тесты:</b>\\n#{@xml_pass.join('\n')}\\nА эти нет:\\n#{@xml_fail.join('\n')}', 'transparent')" }
      # end
    end
  end
end
private

def run_simpleTest_params
  params.require(:simple_test_data).permit(:choice_xml, :send_xml, :expected_answer, :choice_category, :all_category_test)
end