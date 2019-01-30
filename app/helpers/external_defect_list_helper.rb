module ExternalDefectListHelper

  def select_defects
    select = <<-query
SELECT project_key, issuenum, summary, status, created, label
FROM view_itools_report
WHERE issue_type in ('Дефект', 'Консультация') and label in ('ExternalDefectsAnalize_SN', 'ExternalDefectsAnalize_EGG', 'ExternalDefectsAnalize_FA', 'ExternalDefectsAnalize_TIR', 'ExternalDefectsAnalize_MT', 'ExternalDefectsAnalize_EPOS') and updated >= SYSDATE - 7
GROUP BY project_key, issuenum, summary, status, created, label
    query
    begin
      url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
      connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
      stmt = connection.create_statement
      rs = stmt.execute_query(select)
      defects = Array.new
      while (rs.next()) do
        defects << { key: "#{rs.getString('project_key')}-#{rs.getString('issuenum')}",
                     summary: "#{rs.getString("summary")}",
                     status: "#{rs.getString("status")}",
                     created: "#{rs.getString("created")}",
                     labels: "#{rs.getString("label")}",}
      end
    ensure
      stmt.close
      connection.close
    end
    return defects
  end

  def update_external_defects
    defects = select_defects
    defects.each do |defect|
      ExternalDefectList.create(key: defect[:key],
                                summary: defect[:summary],
                                created: defect[:created],
                                status: defect[:status],
                                labels: defect[:labels],)
    end
  end

end
