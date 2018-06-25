module FeaturesHelper

  def get_empty_fields hash
    @empty_filds = []
    hash.reject do |key,value|
      # feature controller
      @empty_filds << 'Название доработки' if key == 'name' and value.empty? and hash.has_key?('test_plan_id')
      @empty_filds << 'Метка' if key == 'labels' and value.empty?
      @empty_filds << 'Задача с оценкой' if key == 'backlog' and value.empty?
      # test_plans controller
      @empty_filds << 'Название плана' if key == 'name' and value.empty? and hash.has_key?('status')
      @empty_filds << 'Статус' if key == 'status' and value.empty?
      @empty_filds << 'Продукт' if key == 'product_id' and value.empty?
    end
    @empty_filds.map! {|value| '<br/>'+value}
    return @empty_filds
  end
end
