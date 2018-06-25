module TestPlansHelper
  class Tester
    def waaa
      puts "asa"
    end
  end

  def get_list_of_value(plan)
    backlog = Array.new
    labels = Array.new
    plan.features.each do |b|
      backlog << b.backlog
      labels << b.labels
    end
    return backlog.join(','), labels.join(',')
  end
end
