del /F /Q "C:\IntegrationTools\tmp\pids\server.pid"
jruby rails server -b 0.0.0.0 -p 3000 -e production