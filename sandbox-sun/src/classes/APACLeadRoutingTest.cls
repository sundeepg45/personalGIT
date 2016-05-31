/**
* Class Name: APACLeadRoutingTest
* Description:Test Class created for APACLeadRouting business Class.
* Modificaton History:
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
* Modified date :5/8/2011
*/

@IsTest
private class APACLeadRoutingTest {

//Deployment List

        public static List<LeadAccountRules__c> accrulesList= new List<LeadAccountRules__c>();
        public static List<LeadRules__c> rulesList= new List<LeadRules__c>();
        public static List<Lead> leadList = new List<Lead>();
        public static List<LeadCountryMap__c> countryList= new List<LeadCountryMap__c>();
        public static Map<String,String> deployCompanyMap = new Map<String,String>();
        public static Map<String,String> deployCountryMap = new Map<String,String>();
        public static Map<String,String> deployStateMap = new Map<String,String>();
        public static Map<String,String> deployemailatMap = new Map<String,String>();
        public static Map<String,String> deployemaildotMap = new Map<String,String>();
        public static LeadMap deployLeadMap= new LeadMap();
        public static User u = new user();

        public static testmethod void apacLeadRoute()
        {
            DeactivateAllTestUtil.setDeactivateAll(false);

            LeadMap.dbbyPass = false;
                
            apacLeadCountryMapping();
            apacLeadAccoutRules();
            apacLeadRouting();
            insert countryList;    
            insert  accrulesList;
            insert  rulesList;
            insert leadList;
            deployemailatMap.put('GOV.IN','GOV.IN');
            deployemaildotMap.put('.TESTVALUE','.TESTVALUE');
            //new APACLeadRouting().assignQueue(leadList,deployCompanyMap,deployCountryMap,deployStateMap,deployLeadMap,deployemailatMap,deployemaildotMap);
            
            test.startTest();
        
            Lead newLead = [Select Id, OwnerId from Lead where State =: 'Goa1'];
            
            System.assertEquals(Util.ldUserId,newLead.OwnerId);
            
            test.stopTest();
        }

        public static void apacLeadCountryMapping()
        {
            LeadCountryMap__c countryMap = new LeadCountryMap__c();
            countryMap.Country__c = 'JP1';
            countryMap.Region__c = 'APAC';
            countryMap.ISO_Code__c = 'JP';
            countryList.add(countryMap);
            
            LeadCountryMap__c countryMap1 = new LeadCountryMap__c();
            countryMap1.Country__c = 'JAPAN1';
            countryMap1.Region__c = 'APAC';
            countryMap1.ISO_Code__c = 'JP1';
            countryList.add(countryMap1); 
            
            LeadCountryMap__c countryMap2 = new LeadCountryMap__c();
            countryMap2.Country__c = 'Australia1';
            countryMap2.Region__c = 'APAC';
            countryMap2.ISO_Code__c = 'AU';
            countryList.add(countryMap2);
            
            LeadCountryMap__c countryMap3 = new LeadCountryMap__c();
            countryMap3.Country__c = 'China1';
            countryMap3.Region__c = 'APAC';
            countryMap3.ISO_Code__c = 'CN';
            countryList.add(countryMap3);
            
            LeadCountryMap__c countryMap4 = new LeadCountryMap__c();
            countryMap4.Country__c = 'New Zealand1';
            countryMap4.Region__c = 'APAC';
            countryMap4.ISO_Code__c = 'NZ';
            countryList.add(countryMap4);
            
            LeadCountryMap__c countryMap5 = new LeadCountryMap__c();
            countryMap5.Country__c = 'IN1';
            countryMap5.Region__c = 'APAC';
            countryMap5.ISO_Code__c = 'IN';
            countryList.add(countryMap5);
            
            LeadCountryMap__c countryMap6 = new LeadCountryMap__c();
            countryMap6.Country__c = 'RSW';
            countryMap6.Region__c = 'APAC';
            countryMap6.ISO_Code__c = 'RSW';
            countryList.add(countryMap6);
            
            LeadCountryMap__c countryMap7 = new LeadCountryMap__c();
            countryMap7.Country__c = 'OP';
            countryMap7.Region__c = 'APAC';
            countryMap7.ISO_Code__c = 'OP';
            countryList.add(countryMap7);
            
            LeadCountryMap__c countryMap8 = new LeadCountryMap__c();
            countryMap8.Country__c = 'XYZ';
            countryMap8.Region__c = 'APAC';
            countryMap8.ISO_Code__c = 'XYZ';
            countryList.add(countryMap8);
    
        }
        
        public static void apacLeadAccoutRules()
        {
            Account TestAcc=new Account();
            TestAcc.Name='Test';
            TestAcc.Named_Account__c=true;
            TestAcc.isAccountActive__c=true;
            insert TestAcc;
            
            LeadAccountRules__c namedApacAccountRules= new LeadAccountRules__c();
            namedApacAccountRules.Type__c='Named Account';
            namedApacAccountRules.Value__c='Accenture';
            //namedApacAccountRules.Account__c=Util.ldAccount;
            namedApacAccountRules.Account__c=TestAcc.Id;
            namedApacAccountRules.Assign_To_Account_Team_Role__c = 'Account Owner';
            namedApacAccountRules.Assign_To_Account_Owner__c = true;
            namedApacAccountRules.SuperRegion__c='APAC';
            accrulesList.add(namedApacAccountRules);


            LeadAccountRules__c jpnApacAccountRules= new LeadAccountRules__c();
            jpnApacAccountRules.Type__c='Japan Commercial';
            jpnApacAccountRules.Value__c='Accenture Japan';
            //jpnApacAccountRules.Account__c=Util.ldAccount;
            jpnApacAccountRules.Account__c=TestAcc.Id;
            jpnApacAccountRules.User__c=Util.ldUserId;
            jpnApacAccountRules.SuperRegion__c='APAC';
            jpnApacAccountRules.Country__c='JP1';
            accrulesList.add(jpnApacAccountRules);
                
              
            LeadAccountRules__c anzApacAccountRules= new LeadAccountRules__c();
            anzApacAccountRules.Type__c='ANZ Commercial Named Account';
            anzApacAccountRules.Value__c='Accenture AUS';
            //anzApacAccountRules.Account__c=Util.ldAccount;
            anzApacAccountRules.Account__c=TestAcc.Id;
            anzApacAccountRules.User__c=Util.ldUserId;
            anzApacAccountRules.SuperRegion__c='APAC';
            accrulesList.add(anzApacAccountRules);       

            LeadRules__c countryrule1 =new LeadRules__c();
            countryrule1.Type__c='Country';
            countryrule1.Value__c='XYZ';
            countryrule1.User__c=Util.ldUserId;
            countryrule1.SuperRegion__c='APAC';
            rulesList.add(countryrule1);
                
                
            LeadRules__c countryrule =new LeadRules__c();
            countryrule.Type__c='Country';
            countryrule.Value__c='RSW';
            countryrule.User__c=Util.ldUserId;
            countryrule.SuperRegion__c='APAC';
            rulesList.add(countryrule );
             
                
            LeadRules__c chinarule=new LeadRules__c();
            chinarule.Type__c='China Province';
            chinarule.Value__c='Twan';
            chinarule.User__c=Util.ldUserId;
            chinarule.SuperRegion__c='APAC';
            rulesList.add(chinarule);


            LeadRules__c anzrule=new LeadRules__c();
            anzrule.Type__c='ANZ Province';
            anzrule.Value__c='Aukland';
            anzrule.User__c=Util.ldUserId;
            anzrule.SuperRegion__c='APAC';
            rulesList.add(anzrule);


            LeadRules__c indiarule=new LeadRules__c();
            indiarule.Type__c='India Province';
            indiarule.Value__c='Goa1';
            indiarule.User__c=Util.ldUserId;
            indiarule.SuperRegion__c='APAC';
            rulesList.add(indiarule);


            LeadRules__c japanrule=new LeadRules__c();
            japanrule.Type__c='Japan Province';
            japanrule.Value__c='Tokyo';
            japanrule.User__c=Util.ldUserId;
            japanrule.SuperRegion__c='APAC';
            rulesList.add(japanrule);
               
              
            LeadRules__c emailrule=new LeadRules__c();
            emailrule.Type__c='Email Domain';
            emailrule.Value__c='.testvalue';
            emailrule.User__c=Util.ldUserId;
            emailrule.SuperRegion__c='APAC';
            emailrule.Country__c='';
            emailrule.Email_Overide__c=true;
            rulesList.add(emailrule);
                
            LeadRules__c emailApacrule=new LeadRules__c();
            emailApacrule.Type__c='Email Domain';
            emailApacrule.Value__c='GOV.IN';
            emailApacrule.User__c=Util.ldUserId;
            emailApacrule.SuperRegion__c='APAC';
            emailApacrule.Country__c='';
            rulesList.add(emailApacrule);

        }

        public static void apacLeadRouting()
            {
                        
                Lead namedAccountApacLead= new Lead();
                populateLead(namedAccountApacLead);
                namedAccountApacLead.Company='Accenture';
                namedAccountApacLead.Country='JAPAN1';
                namedAccountApacLead.Email = 'test@rh.com';
                deployCompanyMap.put('one',namedAccountApacLead.Company);
                leadList.add(namedAccountApacLead);

                Lead jpnAccountApacLead= new Lead();
                populateLead(jpnAccountApacLead);
                jpnAccountApacLead.Company='Accenture Japan';
                jpnAccountApacLead.Country='JP1';
                //jpnAccountApacLead.Iso_Country_Code__c='JP';
                jpnAccountApacLead.Email='abc@gmail.com';
                deployCompanyMap.put('two',jpnAccountApacLead.Company);
                leadList.add(jpnAccountApacLead);               
            
                Lead anzAccountApacLead= new Lead();
                populateLead(anzAccountApacLead);
                anzAccountApacLead.Company='Accenture AUS';
                anzAccountApacLead.Country='Australia1';
                anzAccountApacLead.Email='xyz@gmail.com';
                //anzAccountApacLead.Iso_Country_Code__c='AU';
                deployCompanyMap.put('three',anzAccountApacLead.Company);
                leadList.add(anzAccountApacLead);
            
                Lead partnerAccountApacLead= new Lead();
                populateLead(partnerAccountApacLead);
                partnerAccountApacLead.Company='IBM';
                partnerAccountApacLead.Country='JAPAN1';
                partnerAccountApacLead.Email='def@gmail.com';
                deployCompanyMap.put('four',partnerAccountApacLead.Company);
                leadList.add(partnerAccountApacLead);             
                
                Lead partnerAccountApacLead1= new Lead();
                populateLead(partnerAccountApacLead1);
                partnerAccountApacLead1.Company='CTS';
                partnerAccountApacLead1.Country='JAPAN1';
                partnerAccountApacLead1.Email='def@gmail.com';
                deployCompanyMap.put('four',partnerAccountApacLead1.Company);
                leadList.add(partnerAccountApacLead1);
                
                Lead chinaproLead= new Lead();
                populateLead(chinaproLead);
                chinaproLead.Company='Y';
                chinaproLead.Country='China1';
                chinaproLead.State='Twan';
                chinaproLead.Email='def@gmail.com';
                //chinaproLead.Iso_Country_Code__c='CN';
                deployStateMap.put('one',chinaproLead.State);
                leadList.add(chinaproLead);
              
                Lead anzproLead= new Lead();
                populateLead(anzproLead);
                anzproLead.Company='Y1';
                anzproLead.Country='New Zealand1';
                anzproLead.State='Aukland';
                //anzproLead.Iso_Country_Code__c='AU';
                anzproLead.Email='123@gmail.com';
                deployStateMap.put('five',anzproLead.State);
                leadList.add(anzproLead);
              
                
                Lead apacCountryLead= new Lead();
                populateLead(apacCountryLead);
                apacCountryLead.Company='Y2';
                apacCountryLead.Country='IN1';
                apacCountryLead.State='Goa1';
                //apacCountryLead.Iso_Country_Code__c='IN';
                apacCountryLead.Email='456@gmail.com';
                deployStateMap.put('six',apacCountryLead.State); 
                leadList.add(apacCountryLead);
                
                Lead indproLead= new Lead();
                populateLead(indproLead);
                indproLead.Company='Y5';
                indproLead.Country='XYZ';
                //indproLead.Iso_Country_Code__c='XYZ';
                indproLead.Email='789@gmail.com';
                deployCountryMap.put('nine',indproLead.Country);
                leadList.add(indproLead);
                
                Lead indproLead1= new Lead();
                populateLead(indproLead1);
                indproLead1.Company='Y6';
                indproLead1.Country='RSW';
                //indproLead1.Iso_Country_Code__c='RSW';
                indproLead1.Email='111@gmail.com';
                deployCountryMap.put('ten',indproLead1.Country);
                leadList.add(indproLead1);
     
                Lead japanproLead= new Lead();
                populateLead(japanproLead);
                japanproLead.Company='Y3';
                japanproLead.Country='JP1';
                //japanproLead.Iso_Country_Code__c='JP';
                japanproLead.State='Tokyo';
                japanproLead.Email='789@gmail.com';
                deployStateMap.put('two',japanproLead.State);
                leadList.add(japanproLead);
                
                Lead nomatchLead = new Lead();
                populateLead(nomatchLead );
                nomatchLead.Company='QW';
                nomatchLead.Country='OP';
                //nomatchLead .Iso_Country_Code__c='OP';
                nomatchLead.State='abcd';
                nomatchLead.Email='222@gmail.com';
                deployStateMap.put('nine1',nomatchLead .State);
                leadList.add(nomatchLead );
                  
                Lead emailDomainLead= new Lead();
                populateLead(emailDomainLead);
                emailDomainLead.Company='Y4';
                emailDomainLead.Country='Australia1';
                emailDomainLead.Email='us@gov.in';
                leadList.add(emailDomainLead);
                
                Lead apacEmailDomainLead= new Lead();
                populateLead(apacEmailDomainLead);
                apacEmailDomainLead.Company='Y4';
                apacEmailDomainLead.Country='Australia1';
                apacEmailDomainLead.Email='us@gmail.testvalue';
                leadList.add(apacEmailDomainLead);

            }


        public static void populateLead(Lead objLead)
            {
                objLead.OwnerId=Util.globalLeadRoutingQueue;
                objLead.LastName ='TestR4DeployLead';
                objLead.Title='R4';
                objLead.LeadSourceDetail__c='APAC World Tour';
                objLead.Status='New';
                objLead.Products_of_Interest__c='JBoss';
                objLead.Partner_Opt_In__c=true;
                //ObjLead.Email='Paresh@gmail.testvalue';
                //populateemailMap(ObjLead.Email);

            }
        
        public static void populateemailMap(String email)
            {
                String atemailId;
                String dotemailId;
                String[] dotEmail=null;
                String objemailId=email;
                String[] atEmail=objemailId.split('@',2);
                
                if(atEmail.size() >1)
                {
                    atemailId = atEmail[1].toUpperCase();
                    deployemailatMap.put('GOV.IN','GOV.IN');
                    dotEmail = atemailId.split('\\.',-1);
                    if(dotEmail.size()>1)
                    {
                        dotemailId=dotEmail[dotEmail.size()-1].toUpperCase();
                        deployemaildotMap.put('.'+dotemailId,'.'+dotemailId);
                    }
                
                }

            }

        }