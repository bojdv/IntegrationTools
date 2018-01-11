module XmlSenderHelper
  def response_ajax(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect});"}
    end
  end
  def get_empty_values hash
    a = []
    white_list = [
        'autor',
        'xml_description',
        'category_name',
        'select_category_name',
        'xml_name',
        'settings_name',
        'xml_in',
        'xsd',
        '@tempfile']
    hash.reject do |k,v|
      if v.is_a?(Hash)
        v.reject do |key,value|
          if !white_list.include?(key)
            a << key if value.empty?
          end
        end
      end
    end
    a.each_index do |index|
      a[index] = 'Очередь' if ['queue','queue_in'].include?(a[index])
      a[index] = 'Порт' if ['port','port_in'].include?(a[index])
      a[index] = 'Хост' if ['host','host_in'].include?(a[index])
      a[index] = 'Пользователь' if ['user','user_in'].include?(a[index])
      a[index] = 'XML сообщение' if a[index] == 'xml'
      a[index] = 'Пароль' if ['password','password_in'].include?(a[index])
      a[index] = 'Название настройки' if ['manager_name'].include?(a[index])
      a[index] = 'Название продукта' if ['product_name'].include?(a[index])
      a[index] = 'Название XML' if ['select_xml_name'].include?(a[index])
    end
    a.map! {|value| '<br/>'+value}
    return a.join
  end
end
