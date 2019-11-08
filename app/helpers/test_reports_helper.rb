module TestReportsHelper

  def response_ajax_reports(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect});"}
    end
  end

  class JIRA_Report
    def initialize(backlog_keys = nil, labels, worklog_autor)
      @backlog_keys = backlog_keys.nil? ? nil : get_task_key(backlog_keys)
      @backlog_numbers = backlog_keys.nil? ? nil : get_task_number(backlog_keys)
      @labels = get_task_list(labels)
      @project_keys, @project_numbers, @project_name, @project_key = select_prjUrlKeyName
      @worklog_autor = get_task_list(worklog_autor.keys.join(','))
      @projects = split_task(@project_keys.split(','), @project_numbers.split(',')) if !@project_keys.nil?

      @defect_count = Array.new
      @defect_true_count = Array.new
      @defect_open_count = Array.new
      @defect_bkv_count = Array.new
      @deis_defect_worklogtime = Array.new
      @test_tasks = Hash.new
      @def_tasks = Hash.new
      @cons_tasks = Hash.new
      @agree_tasks = Hash.new
      @test_count = 1
      @def_count = 1
      @cons_count = 1
      @agree_count = 1
    end
    attr_accessor :backlog_keys, :backlog_numbers, :project_name, :project_numbers, :project_keys, :projects

    # Функциональные методы

    def get_task_number(value) #Получает строку.
      array = value.scan(/\d+/)
      array.collect! {|elem| "'#{elem.strip}'"}
      array.join(',')
    end

    def get_task_key(value) #Получает строку.
      array = value.scan(/[A-Z]+/)
      array.collect! {|elem| "'#{elem.strip}'"}
      array.join(',')
    end

    def get_task_array(value) # Получает строку. Отдает архив со списком задач
      array = value.split(',')
      array.map!(&:strip)
    end

    def get_task_list(value) # Получает строку. Отдает список через запятую
      array = value.split(',')
      array.collect! {|elem| "'#{elem.strip}'"}
      array.join(',')
    end

    def split_task(keys, numbers) # Получает архив, выдает строку через запятую.
      array = Array.new
      keys.each_index  do |index|
        array << keys[index] + '-' + numbers[index]
      end
      return array.join(',').delete('\'')
    end

    def get_value_from_hash(hash, array) # Принимает хэш и архив и возвращает строку с value хеша, где ключ = элемент массива
      valueArray = Array.new
      hash.map do |key, value|
        array.each do |element|
          valueArray << value if key == element
        end
      end
      return valueArray.join('<br>')
    end


    # СЕЛЕКТЫ!

    # def select_backlog_project_estimate # Плановые оценки тестирования и МП
    #   backlog_estimate = Array.new
    #   project_estimate  = Array.new
    #   if @project_keys.nil? and !@backlog_keys.nil?
    #     select = <<-query
    #   SELECT exptest, prjtest, project_key, issuenum
    #   FROM view_itools_report
    #   WHERE
    #   project_key in (#{@backlog_keys}) and issuenum in (#{@backlog_numbers})
    #   ORDER BY issuenum asc
    #     query
    #   elsif @backlog_keys.nil?  and !@project_keys.nil?
    #     select = <<-query
    #   SELECT exptest, prjtest, project_key, issuenum
    #   FROM view_itools_report
    #   WHERE
    #   project_key in (#{@project_keys}) and issuenum in (#{@project_numbers})
    #   ORDER BY issuenum asc
    #     query
    #   else
    #     select = <<-query
    #   SELECT exptest, prjtest, project_key, issuenum
    #   FROM view_itools_report
    #   WHERE
    #   project_key in (#{@backlog_keys}, #{@project_keys}) and issuenum in (#{@backlog_numbers}, #{@project_numbers})
    #   ORDER BY issuenum asc
    #     query
    #   end
    #
    #   begin
    #     puts "Select select_backlog_project_estimate:\n" + select
    #     url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
    #     connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
    #     stmt = connection.create_statement
    #     rs = stmt.execute_query(select)
    #     while (rs.next()) do
    #       backlog_estimate << rs.getString('exptest')
    #       project_estimate << rs.getString('prjtest')
    #     end
    #   ensure
    #     stmt.close
    #     connection.close
    #   end
    #   return backlog_estimate.map(&:to_i).sum,
    #       project_estimate.map(&:to_i).sum
    # end

    def select_backlog_estimate # Плановые оценки тестирования и МП
      backlog_estimate = Array.new
      return 0 if @backlog_keys.nil?
      select = <<-query
      SELECT exptest
      FROM view_itools_report
      WHERE
      project_key in (#{@backlog_keys}) and issuenum in (#{@backlog_numbers})
      GROUP BY exptest

      query
      begin
        puts "Select select_backlog_estimate:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        while (rs.next()) do
          backlog_estimate << rs.getString('exptest')
        end
      ensure
        stmt.close
        connection.close
      end
      return backlog_estimate.map(&:to_i).sum
    end

    def select_project_estimate # Плановые оценки тестирования и МП
      project_estimate  = Array.new
      select = <<-query
      SELECT prjtest
      FROM view_itools_report
      WHERE
      project_key in (#{@project_keys}) and issuenum in (#{@project_numbers})
      ORDER BY issuenum asc
      query

      begin
        puts "Select select_project_estimate:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        while (rs.next()) do
          project_estimate << rs.getString('prjtest')
        end
      ensure
        stmt.close
        connection.close
      end
      return project_estimate.map(&:to_i).sum
    end

    def select_test_worklog # списания в задачи с типом тестирование и их кол-во
      select = <<-query
      SELECT summary, project_key, issuenum, sum(NVL(prjtest,0)) as prjtest, NVL(O_Estimate,0) as O_Estimate, sum(NVL(worklogtime,0)) as worklogtime, status 
      FROM view_itools_report
      WHERE
      issue_type = 'Тестирование' and label in (#{@labels}) and worklogautor in (#{@worklog_autor})
      GROUP BY summary, project_key, prjtest, O_Estimate, issuenum, status
      ORDER BY issuenum asc
      query
      begin
        puts "Select select_test_worklog:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        testing_worklogtime = Array.new
        test_tasks = Hash.new
        test_count = 1
        while (rs.next()) do
          testing_worklogtime << rs.getString('worklogtime')
          test_tasks[test_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('O_Estimate'), rs.getString('worklogtime'), rs.getString('status')]
          test_count +=1
        end
      ensure
        stmt.close
        connection.close
      end
      return testing_worklogtime.map(&:to_i).sum, test_tasks
    end

    def select_inner_tasks_worklog # списания и количество внутренних дефектов, консультаций, согласований
      select = <<-query
      SELECT summary, project_key, issuenum, issue_type, status, reporter, priority,
      SUM(
      CASE
      WHEN worklogautor not in (#{@worklog_autor}) or worklogautor is null THEN 0
      ELSE worklogtime
      END
      ) worklogtime
      FROM view_itools_report
      WHERE
      issue_type in ('Дефект', 'Консультация') and label in (#{@labels}) and reporter in (#{@worklog_autor})
      or
      issue_type = 'Согласование' and label in (#{@labels}) and worklogautor in (#{@worklog_autor})
      GROUP BY summary, project_key, issuenum, issue_type, status, reporter, priority
      ORDER BY status desc
      query
      begin
        puts "Select select_inner_tasks_worklog:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        defect_worklogtime = Array.new
        cons_worklogtime = Array.new
        agree_worklogtime = Array.new
        open_def = Hash.new
        open_def_count = 1
        open_def_bkv = 0
        agree_task = Hash.new
        agree_count = 1
        def_tasks = Hash.new
        def_count = 1
        cons_task = Hash.new
        cons_count = 1
        while (rs.next()) do
          case rs.getString('issue_type')
            when 'Дефект'
              def_tasks[def_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('priority'), rs.getString('worklogtime'), rs.getString('status')]
              def_count+=1
              defect_worklogtime << rs.getString('worklogtime') if rs.getString('worklogtime')
              open_def_bkv +=1 if (rs.getString('priority') == 'Блокирует' || rs.getString('priority') == 'Критический' || rs.getString('priority') == 'Высокий') and rs.getString('status') != 'Закрыт'
              if rs.getString('status') != 'Закрыт' and rs.getString('status') != 'Отложен'
                open_def[open_def_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('worklogtime'), rs.getString('status')]
                open_def_count +=1
              end
            when 'Консультация'
              cons_task[cons_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('priority'), rs.getString('worklogtime'), rs.getString('status')]
              cons_count+=1
              cons_worklogtime << rs.getString('worklogtime') if rs.getString('worklogtime')
            when 'Согласование'
              agree_task[agree_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('priority'), rs.getString('worklogtime'), rs.getString('status')]
              agree_count+=1
              agree_worklogtime << rs.getString('worklogtime') if rs.getString('worklogtime')
          end
        end
          ensure
          stmt.close
          connection.close
        end
        return defect_worklogtime.map(&:to_i).sum, cons_worklogtime.map(&:to_i).sum, agree_worklogtime.map(&:to_i).sum, def_tasks, cons_task, agree_task, open_def, open_def_bkv
    end

    def select_deis # Отбор дефектов ДЭИС и их кол-ва
      select = <<-query
      SELECT summary, issue_type, project_key, issuenum, status, reasolution,
      SUM(
      CASE
      WHEN worklogautor not in (#{@worklog_autor}) or worklogautor is null THEN 0
      ELSE worklogtime
      END
      ) worklogtime
      FROM view_itools_report
      WHERE project_name in (#{@project_name}) and issue_type in ('Дефект') and etap = 'Приемка ДЭИС'
      GROUP BY summary, issue_type, project_key, issuenum, status, reasolution
      ORDER BY status desc
      query
      begin
        puts "Select select_deis:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        deis_def = Hash.new
        deis_defect_true_count = 0
        deis_def_count = 1
        while (rs.next()) do
            deis_def[deis_def_count] = Array.new
            deis_def[deis_def_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('worklogtime'), rs.getString('reasolution'),rs.getString('status')]
            deis_def_count+=1
            deis_defect_true_count +=1 if rs.getString('reasolution') == 'Выполнен' || rs.getString('reasolution') == 'Отказан' || rs.getString('reasolution') == 'Невозможно исправить'
        end
      ensure
        stmt.close
        connection.close
      end
      return deis_def, deis_defect_true_count
    end

    def select_deis_worklog # отбор списаний в дефекты ДЭИС
      select = <<-query
      SELECT summary, issue_type, project_key, issuenum, status, reasolution, sum(NVL(worklogtime,0)) as worklogtime
      FROM view_itools_report
      WHERE project_name in (#{@project_name}) and issue_type in ('Дефект') and etap = 'Приемка ДЭИС' and worklogautor in (#{@worklog_autor})
      GROUP BY summary, issue_type, project_key, issuenum, status, reasolution
      ORDER BY issue_type desc
      query
      begin

        puts "Select select_deis_worklog:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        deis_bug_worklogtime = Array.new
        while (rs.next()) do
          deis_bug_worklogtime << rs.getString('worklogtime')
        end
      ensure
        stmt.close
        connection.close
      end
      return deis_bug_worklogtime.map(&:to_i).sum
    end

    # def select_nullable_task # отбор задач без меток
    #   select = <<-query
    #   SELECT summary, issue_type, project_key, issuenum, status
    #   FROM view_itools_report
    #   WHERE project_name in (#{@project_name}) and reporter in (#{@worklog_autor}) and label is null
    #   GROUP BY summary, issue_type, project_key, issuenum, status
    #   ORDER BY issue_type desc
    #   query
    #   begin
    #     puts "Select select_nullable_task:\n" + select
    #     url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
    #     connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
    #     stmt = connection.create_statement
    #     rs = stmt.execute_query(select)
    #     nullable_tasks = Hash.new
    #     nullable_count = 1
    #     while (rs.next()) do
    #       nullable_tasks[nullable_count] = Array.new
    #       nullable_tasks[nullable_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('issue_type'), rs.getString('status')]
    #       nullable_count+=1
    #     end
    #   ensure
    #     stmt.close
    #     connection.close
    #   end
    #   return nullable_tasks
    # end

    def select_other_task # отбор остальных задач, где были списания
      select = <<-query
      SELECT summary, issue_type, project_key, issuenum, status,
      SUM(
      CASE
      WHEN worklogautor not in ('bojdv','pekav','kotvv','shpae','tkans','pasap','uboav','povao', 'E.Vasilyeva') or worklogautor is null THEN 0
      ELSE worklogtime
      END
      ) worklogtime
      FROM view_itools_report
      WHERE project_name in (#{@project_name}) and (worklogautor in (#{@worklog_autor}) or reporter in (#{@worklog_autor})) and (label is null or label not in (#{@labels})) and etap != 'Приемка ДЭИС'
      GROUP BY summary, issue_type, project_key, issuenum, status
      ORDER BY issue_type desc
      query
      begin
        puts "Select select_other_task:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        other_tasks = Hash.new
        other_count = 1
        while (rs.next()) do
          other_tasks[other_count] = Array.new
          other_tasks[other_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('issue_type'), rs.getString('worklogtime'), rs.getString('status')]
          other_count+=1
        end
      ensure
        stmt.close
        connection.close
      end
      return other_tasks
    end

    def select_worklog_date # отбор дат тестирования и тестировщиков
      select = <<-query
      SELECT worklogdate, worklogautor
      FROM view_itools_report
      WHERE
      issue_type in ('Тестирование', 'Согласование') and label in (#{@labels}) and worklogautor in (#{@worklog_autor})
      ORDER BY worklogdate asc
      query
      begin
        puts "Select select_worklog_date:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        worklog_time = Array.new
        worklog_autor = Array.new
        while (rs.next()) do
          worklog_time << rs.getString('worklogdate')
          worklog_autor << rs.getString('worklogautor')
        end
      ensure
        stmt.close
        connection.close
      end
      return worklog_time.compact, worklog_autor.uniq
    end

    def select_prjUrlKeyName
      select = <<-query
      SELECT project_key, project_url, project_name
      FROM view_itools_report
      WHERE issue_type in ('Дефект', 'Консультация', 'Тестирование') and label in (#{@labels})
      query
      begin
        puts "Select select_prjUrlKeyName:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        project_url = Array.new
        project_key = Array.new
        project_name = Array.new
        while (rs.next()) do
          project_url << rs.getString('project_url')
          project_name << rs.getString('project_name')
          project_key << rs.getString('project_key')
        end
      ensure
        stmt.close
        connection.close
      end
      if project_name.any?
        project_url.uniq!
        prj_key = get_task_key(project_url.join(','))
        prj_number = get_task_number(project_url.join(','))
        return prj_key,  prj_number, get_task_list(project_name.uniq.join(',')), get_task_list(project_key.uniq.join(','))
      else
        return nil
      end
    end

    def select_worklog_per_date
      select = <<-query
      SELECT trunc(worklogstartdate) as worklogstartdate, sum(NVL(worklogtime,0)) as worklogtime
      FROM view_itools_report
      WHERE
      label in (#{@labels}) and worklogautor in (#{@worklog_autor})
      GROUP BY trunc(worklogstartdate)
      ORDER BY trunc(worklogstartdate) asc
      query
      begin
        puts "Select select_worklog_per_date:\n" + select
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        worklog_per_date = Array.new
        worklog_sum_per_date = Array.new
        hours = 0
        while (rs.next()) do
          hours = hours + rs.getString('worklogtime').to_i
          hash_worklog_per_date = {date: rs.getString('worklogstartdate').to_date, value: rs.getString('worklogtime').to_i/60}
          worklog_per_date << hash_worklog_per_date
          hash_sum_worklog_per_date = {date: rs.getString('worklogstartdate').to_date, value: hours/60}
          worklog_sum_per_date << hash_sum_worklog_per_date
        end
      ensure
        stmt.close
        connection.close
      end
      return worklog_per_date, worklog_sum_per_date
    end

  end

=begin
  def split_tasks(task) # Метод принимает строку со списком задач, например: BSSSNAB-50, BSS-55
    array = task.split(',') # расщепляем строку на элементы массива. Строка разбивается по запятой.
    array.collect! {|element| element.strip.split('-') || element} # Удаляем у каждого элемента пробелы и разбиваем элемент на два, если в нем есть дефис
    Hash[*array.flatten!] # Схлопываем двумерный массив в одномерный и возвращаем хэш, например: {"BSSSNAB"=>"50", "BSS"=>"55"}.
  end
=end
end
