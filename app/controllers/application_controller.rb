class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  include XmlSenderHelper
  #require 'rubygems'
  require 'java'
  # Библиотеки AMQ
  $CLASSPATH << "lib/activemq-all-5.11.1.jar"
  $CLASSPATH << "lib/log4j-1.2.17.jar"
  # Библиотеки WMQ
  $CLASSPATH << "lib/javax.jms-3.1.2.2.jar"
  $CLASSPATH << "lib/com.ibm.mqjms.jar"
  $CLASSPATH << "lib/com.ibm.mq.jar"
  $CLASSPATH << "lib/dhbcore.jar"
  $CLASSPATH << "lib/javax.resource.jar"
  $CLASSPATH << "lib/javax.transaction.jar"
  $CLASSPATH << "com.ibm.msg.client.osgi.wmq_7.0.1.3.jar"
end
