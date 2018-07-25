# encoding: utf-8
class CcFormatValidatorController < ApplicationController
  include CcFormatValidatorHelper

  def index
    @validator_log = CcFormatValidatorLog.all
    uniq_date = Array.new
    @validator_log.each do |data|
      uniq_date << data.created_at.to_date
    end
    @uniq_date = uniq_date.uniq
  end

  def start
    $thread = Thread.new do
      while true
        validator = Validator.new
        if validator.xml
          result = validator.validate_cc_xml
          puts result
          if result.nil?
            answer = validator.make_answer
          else
            answer = validator.make_answer('DECLINED_BY_ABS', result)
          end
          validator.send_to_amq_openwire(answer)
        end
        sleep 3
      end
    end
  end

  def stop
    $thread.kill
  end

  def clear_log
    CcFormatValidatorLog.delete_all
  end

  def tester
    a = '6'
    case a
      when 'Pay', 'p'
        puts "1"
      when 'Pay3'
        puts 2
    end
  end
end
