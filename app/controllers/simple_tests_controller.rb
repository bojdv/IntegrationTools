require 'rexml/document'
include REXML
require "base64"

class SimpleTestsController < ApplicationController
  include SimpleTestsHelper
  def index
    logged_in? ? @qm = QueueManager.where(user_id: current_user.id).or(QueueManager.where(visible_all: true)).order('manager_name').pluck(:manager_name) : @qm = QueueManager.where(visible_all: true).pluck(:manager_name)
    @product = Product.all.order('product_name')
    @category = Category.all.order('category_name')
  end
  def put_simple_test
    if !params[:choice_xml].empty?
      xml = Xml.find(params[:choice_xml])
      autor = User.find(xml.user_id)
      simpleTest = SimpleTest.find_by_xml_id(xml.id)
      if simpleTest = SimpleTest.find_by_xml_id(xml.id)
        manager = QueueManager.find(simpleTest.queue_manager_id)
        respond_to do |format|
          format.js { render :js => "updateSimpleTest('#{xml.xml_text.inspect}', '#{xml.xml_answer.inspect}', '#{xml.xml_description}', '#{autor.email}', '#{manager.manager_name}', '#{manager.queue_out}', '#{manager.queue_in}')"}
        end
      else
        respond_to do |format|
          format.js { render :js => "updateSimpleTest('#{xml.xml_text.inspect}', '#{xml.xml_answer.inspect}', '#{xml.xml_description}', '#{autor.email}')"}
        end
      end
    end
  end
  def run_simpleTest # Запускаем тест
    if run_simpleTest_params[:all_category_test] == 'false'
      response_ajax("Не заполнены параметры:#{@empty_filds.join}") and return if !get_empty_values(run_simpleTest_params).empty?
      mode = 'single'
      ignore_ticket = run_simpleTest_params[:ignore_ticket]
      egg = run_simpleTest_params[:egg]
      xml = Xml.find(run_simpleTest_params[:choice_xml])
      if !simpleTest =SimpleTest.find_by_xml_id(run_simpleTest_params[:choice_xml])
        response_ajax("Не создан Simple Test для этой XML!") and return
      end
      manager = QueueManager.find(simpleTest.queue_manager_id)
      if manager.manager_type == 'Active MQ'
        if manager.amq_protocol == 'OpenWire'
          send_to_amq_openwire(manager, xml, mode, ignore_ticket, egg)
        else
          send_to_amq_stomp(manager, xml, mode)
        end
      else
        send_to_wmq(manager, xml, mode, ignore_ticket, egg)
      end
    elsif run_simpleTest_params[:all_category_test] == 'true'
      response_ajax("Не выбрана категория") and return if run_simpleTest_params[:choice_category].empty?
      @xml_pass = Array.new
      @xml_fail = Array.new
      @xml_missed = Array.new
      mode = 'all'
      ignore_ticket = run_simpleTest_params[:ignore_ticket]
      egg = run_simpleTest_params[:egg]
      xml = Xml.where(category_id: run_simpleTest_params[:choice_category]).to_a
      xml.each do |xml|
        simpleTest = SimpleTest.find_by_xml_id(xml.id)
        if !simpleTest.nil?
          manager = QueueManager.find(simpleTest.queue_manager_id)
          if manager.manager_type == 'Active MQ'
            if manager.amq_protocol == 'OpenWire'
              send_to_amq_openwire(manager, xml, mode, ignore_ticket, egg)
            else
              send_to_amq_stomp(manager, xml, mode)
            end
          else
            send_to_wmq(manager, xml, mode, ignore_ticket, egg)
          end
        else
          @xml_missed << xml.xml_name
        end
      end
      @xml_missed << 'Отсутствуют' if @xml_missed.empty?
      response_ajax("<b>XML, прошедшие тесты:</b><br/>#{@xml_pass.join('<br/>')}<br/><br/><b>XML, не прошедшие тесты:</b><br/>#{@xml_fail.join('<br/>')}<br/><br/><b>XML, у которых нет Simple Test:</b><br/>#{@xml_missed.join('<br/>')}", 10000)
    end
  end
end
private

def run_simpleTest_params
  params.require(:simple_test_data).permit(:choice_xml, :send_xml, :expected_answer, :choice_category, :all_category_test, :ignore_ticket, :egg)
end