# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create!(id: 10000,
             email: "a.pehov@bssys.com",
             password: "waaaaa",
             password_confirmation: "waaaaa")
User.create!(email: "test@bssys.com",
             password: "waaaaa",
             password_confirmation: "waaaaa")

Product.create!(id: 10000,
                product_name: "Личные XML")
Product.create!(product_name: "ТИР")
Product.create!(product_name: "Correqts Corporate")
Product.create!(product_name: "Correqts Retail")
Product.create!(product_name: "FRAUD-Анализ")


5.times do |n|
  email = "example-#{n+1}@bssys.com"
  password = "password"
  User.create!(email: email,
               password: password,
               password_confirmation: password)
end
5.times do |n|
  category_name = "Category_name#{n+1}"
  Category.create!(product_id: 10000,
                   category_name: category_name,
                   user_id: 10000)
end
5.times do |n|
  xml_text = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><test:Request 	xmlns:test="http://bssys.com/abs/model/request" 	xmlns:testtest="http://bssys.com/abs/model/request/test" 	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 	dateTimeCreate="2016-10-20T12:32:34" 	receiver="ABS" 	requestId="692b1747-9fa7-412c-8eaa-1bf1725a17ab" 	sender="XGS" 	version="1.0"><test:PayDocRu 	branchExtId="5" 	branchId="00ff10c6-d34e-4d9c-a2f7-1c27fb29fdde" 	dateTimeCreate="2016-10-20T12:32:34" 	docId="f8825aea-379c-4f5c-ad1d-bf1248607306" 	extOrgId="123" firstSign="Серов Фёдор Андреевич" 	orgId="cad9f60e-b721-42fc-8c26-d478b985141e" 	receiptDate="2016-10-20" 	receiptTime="12:28:52.820"><test:AccDoc accDocNo="1" 	docDate="2016-10-20" 	docNum="1" 	docSum="300559.59" 	paytCode="1" 	paytKind="электронно" 	priority="5" 	purpose="Назначение платежа.&#13;&#10;В том числе НДС 18.00 % - 45848.07." 	transKind="01"/><test:Payer inn="111111111111" 	kpp="111111110" 	personalAcc="40780810111111111111"><test:Name>ООО "Парадигма"</test:Name><test:Bank bic="040147781" correspAcc="30101810700000000781"><test:BankName>АО "НАРОДНЫЙ ЗЕМЕЛЬНО-ПРОМЫШЛЕННЫЙ БАНК" Г. БИЙСК</test:BankName><test:Name>АО "НАРОДНЫЙ ЗЕМЕЛЬНО-ПРОМЫШЛЕННЫЙ БАНК"</test:Name><test:BankCity>БИЙСК</test:BankCity><test:SettlementType>Г</test:SettlementType></test:Bank></test:Payer><test:Payee inn="1234567890" 	kpp="123456789" 	personalAcc="40132810304894980189" 	uip="98765432109876543210"><test:Name>Новенький</test:Name><test:Bank bic="040147781" correspAcc="30101810700000000781"><test:BankName>АО "НАРОДНЫЙ ЗЕМЕЛЬНО-ПРОМЫШЛЕННЫЙ БАНК" Г. БИЙСК</test:BankName><test:Name>АО "НАРОДНЫЙ ЗЕМЕЛЬНО-ПРОМЫШЛЕННЫЙ БАНК"</test:Name><test:BankCity>БИЙСК</test:BankCity><test:SettlementType>Г</test:SettlementType></test:Bank></test:Payee><test:DepartmentalInfo 	cbc="39511706040090000180" 	docDate="01.05.2016" 	docNo="1" drawerStatus="01" 	okato="77801241" 	paytReason="ТП" 	taxPeriod="МС.04.2016" 	taxPeriodDay="МС" 	taxPeriodMonth="04" 	taxPeriodYear="2016"/><test:Signs><test:SignDesc 	cryptoProvider="OneTimePassword" 	signDate="2016-10-20T12:27:19" 	signTypeDesc="SINGLE" 	value="Серов Фёдор Андреевич"/></test:Signs></test:PayDocRu></test:Request>'
  xml_name = "Xml_name#{n+1}"
  Xml.create!(xml_name: xml_name,
              xml_text: xml_text,
              category_id: 10000,
              user_id: 10000)
end