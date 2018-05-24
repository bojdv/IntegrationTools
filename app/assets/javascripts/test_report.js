function download_link_reports(log_file_name) {

    link = document.getElementById('download-link');
    link.setAttribute('href', '/test_reports/download_log_reports?filename='+log_file_name);
    link.style.display = 'inline';
}