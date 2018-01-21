class SimpleTestsController < ApplicationController
  def index
    logged_in? ? @qm = QueueManager.where(user_id: current_user.id).or(QueueManager.where(visible_all: true)).order('manager_name').pluck(:manager_name) : @qm = QueueManager.where(visible_all: true).pluck(:manager_name)
    @product = Product.all.order('product_name')
    @category = Category.all.order('category_name')
  end
  def put_simple_test
    if !params[:choice_xml].empty?
      xml = Xml.find(params[:choice_xml])
      puts xml.xml_text
      puts xml.xml_answer
      respond_to do |format|
        format.js { render :js => "updateSimpleTest('#{xml.xml_text.inspect}', '#{xml.xml_answer.inspect}')" }
      end
    end
  end
end
