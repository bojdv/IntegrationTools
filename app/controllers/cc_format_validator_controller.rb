# encoding: utf-8
require 'rexml/document'
include REXML
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
          begin
            validate_result = validator.validate_cc_xml
            check_etalon_result = validator.check_etalon_elems
            answer = if validate_result.nil?
              validator.make_answer('DECLINED_BY_ABS', "\nРезультат валидации: \nНе найдена XSD")
            elsif validate_result.empty? and check_etalon_result.empty?
              validator.make_answer
            elsif validate_result.empty? and check_etalon_result.any?
              validator.make_answer('DECLINED_BY_ABS', "\nРезультат валидации: \nвалидация пройдена\nРезультат проверки наличия эталонных элементов:\nЭти элементы отсутствуют в xml: #{check_etalon_result.join(',')}\n")
            elsif !validate_result.empty? and check_etalon_result.empty?
              validator.make_answer('DECLINED_BY_ABS', "\nРезультат валидации: \n#{validate_result}\nРезультат проверки наличия эталонных элементов:\nэлементы присутствуют\n")
            elsif !validate_result.empty? and check_etalon_result.any?
              validator.make_answer('DECLINED_BY_ABS', "\nРезультат валидации: \n#{validate_result}\nРезультат проверки наличия эталонных элементов:\nЭти элементы отсутствуют в xml: #{check_etalon_result.join(',')}\n")
            end
            validator.send_to_amq_openwire(answer)
          rescue Exception => msg
            puts "Error! #{msg.message}\n#{msg.backtrace.join("\n")}"
          end
        end
        sleep 1
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
    puts $thread.alive?
  end
end
