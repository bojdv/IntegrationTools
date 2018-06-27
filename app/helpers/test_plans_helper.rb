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
      backlog << b.backlog unless b.backlog.nil?
      labels << b.labels
    end
    return backlog.empty? ? nil : backlog.join(','), labels.join(',')
  end

  def find_max_test_dates(plan)
    start_date = Array.new
    end_date = Array.new
    unless plan.features.nil?
      plan.features.each do |f|
        start_date << f.start_date
        end_date << f.end_date
      end
      return start_date.compact.min, end_date.compact.max
    else

    end

  end
end
