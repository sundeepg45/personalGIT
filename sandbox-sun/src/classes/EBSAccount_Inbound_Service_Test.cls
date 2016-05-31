/*****************************************************************************************
    Name    : EBSInterfaceInboundTest
    Desc    : This class defines the logic for test class for EBSInboundInterface class        
                            
Modification Log : 
---------------------------------------------------------------------------
Developer              Date            Description
---------------------------------------------------------------------------
Pankaj Banik        12 June 2014          Created
******************************************************************************************/

@isTest
private class EBSAccount_Inbound_Service_Test {

    static testMethod void EBSServiceTest() {
        
        
        // TO DO: implement EBSInboundInterface unit test
        //Create Party
        List<CDH_Party__c> partyList = new List<CDH_Party__c>();
        CDH_Party__c cdhPartyNumber1 = new CDH_Party__c();
        cdhPartyNumber1.Name = '77777';
        partyList.add(cdhPartyNumber1);   
        
        CDH_Party__c cdhPartyNumber2 = new CDH_Party__c();
        cdhPartyNumber2.Name = '88888';
        partyList.add(cdhPartyNumber2);
        
        Insert partyList;
        
        //Create Sales Account
        Account salesAccountNumber1 = new Account();
        Account salesAccountNumber2 = new Account();
        Account salesAccountNumber3 = new Account();
        Account salesAccountNumber4 = new Account();
        List<Account> salesAccountList = new List<Account>();   
        
        //Fetch record type Id for Sales Account
        string recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId(); 
        
        //Defining Sales Account attributes
        salesAccountNumber1.CDH_Party_Name__c = cdhPartyNumber1.Id;
        salesAccountNumber1.CDH_Party_Number__c= cdhPartyNumber1.Name;
        salesAccountNumber1.Name = 'Test Sales Account1';
        salesAccountNumber1.CurrencyIsoCode = 'USD';
        salesAccountNumber1.RecordTypeId = recordTypeId;
        salesAccountList.add(salesAccountNumber1);  //++ Give a space for readability
        
        salesAccountNumber2.CDH_Party_Name__c = cdhPartyNumber1.Id;
        salesAccountNumber2.CDH_Party_Number__c= cdhPartyNumber1.Name;
        salesAccountNumber2.Name = 'Test Sales Account2';
        salesAccountNumber2.CurrencyIsoCode = 'USD';
        salesAccountNumber2.RecordTypeId = recordTypeId;
        salesAccountList.add(salesAccountNumber2); 
        
        salesAccountNumber3.CDH_Party_Name__c = cdhPartyNumber1.Id;
        salesAccountNumber3.Name = 'Test Sales Account3';
        salesAccountNumber3.CDH_Party_Number__c= cdhPartyNumber1.Name;
        salesAccountNumber3.CurrencyIsoCode = 'USD';
        salesAccountNumber3.RecordTypeId = recordTypeId;
        salesAccountList.add(salesAccountNumber3); 
        
        salesAccountNumber4.CDH_Party_Name__c = cdhPartyNumber1.Id;
        salesAccountNumber4.Name = 'Test Sales Account4';
        salesAccountNumber4.CurrencyIsoCode = 'USD';
        salesAccountNumber4.CDH_Party_Number__c= cdhPartyNumber1.Name;
        salesAccountNumber4.RecordTypeId = recordTypeId;
        salesAccountList.add(salesAccountNumber4);    
        
        //Inserting Sales Account  
        Insert salesAccountList;         
        system.assertNotEquals(null,[select CDH_Party_Number__c from Account where Id =:salesAccountNumber1.Id].CDH_Party_Number__c);
        system.assertNotEquals(null,[select CDH_Party_Number__c from Account where Id =:salesAccountNumber2.Id].CDH_Party_Number__c);
        system.assertNotEquals(null,[select CDH_Party_Number__c from Account where Id =:salesAccountNumber3.Id].CDH_Party_Number__c);
        system.assertNotEquals(null,[select CDH_Party_Number__c from Account where Id =:salesAccountNumber4.Id].CDH_Party_Number__c);
        
        //Generate sample EBS Account 
        EBS_Account__c ebsAccountObjectNumber1 = new EBS_Account__c(Name='1234',Sales_Account__c = salesAccountList[0].Id,CDH_Party_Number__c='77777',Credit_Hold__c=false,EBS_Account_Description__c='test account',EBS_Party_Name__c='test ebs party',EBS_Party_Number__c='1233',Last_Credit_Review_Date__c=System.Today(),Next_Credit_Review_Date__c=System.Today(),Primary_EBS_Account__c=false,Status__c='Active');
        EBS_Account__c ebsAccountObjectNumber2 = new EBS_Account__c(Name='1234',Sales_Account__c = salesAccountList[1].Id,CDH_Party_Number__c='77777',Credit_Hold__c=false,EBS_Account_Description__c='test account',EBS_Party_Name__c='test ebs party',EBS_Party_Number__c='1233',Last_Credit_Review_Date__c=System.Today(),Next_Credit_Review_Date__c=System.Today(),Primary_EBS_Account__c=false,Status__c='Active');        
        List<EBS_Account__c> ebsAccountList = new List<EBS_Account__c>(); 
        //Inserting EBS Account
        ebsAccountList.add(ebsAccountObjectNumber1);
        ebsAccountList.add(ebsAccountObjectNumber2);
        Insert ebsAccountList;
        system.assertNotEquals(null,[select CDH_Party_Number__c from EBS_Account__c where Id =:ebsAccountObjectNumber1.Id].CDH_Party_Number__c);
        system.assertNotEquals(null,[select CDH_Party_Number__c from EBS_Account__c where Id =:ebsAccountObjectNumber2.Id].CDH_Party_Number__c);
        
        
        //Initializing Test
        test.startTest();  
        
        IntegrationObjects.TransactionalAccount ebsAccountRecord = new IntegrationObjects.TransactionalAccount();
        EBSAccount_Inbound_Service ebs = new EBSAccount_Inbound_Service();
        
        //  Test case for Positive insert and update
        ebsAccountRecord.Account_Number = '1234';
        ebsAccountRecord.Sales_Account = '77777';
        ebsAccountRecord.Credit_Hold = true;
        ebsAccountRecord.Credit_Review_Cycle = 'ANUALLY';
        ebsAccountRecord.Classification = 'Federal';
        ebsAccountRecord.Account_Description ='test again';
        ebsAccountRecord.Sales_channel ='DIRECT END CUSTOMER';
        ebsAccountRecord.Status = 'Inactive';
        ebsAccountRecord.Account_Type = 'External';
        ebsAccountRecord.EBS_Party_Name = 'test1';
        ebsAccountRecord.EBS_Party_Number = '1234';
        ebsAccountRecord.Last_Credit_Review_Date = System.today() ;
        ebsAccountRecord.Next_Credit_Review_Date = System.today();
        ebsAccountRecord.Primary_EBS_Account =true;
        
        ebs.EbsAccountSync(ebsAccountRecord);
        system.assertEquals(4,[select id from EBS_Account__c where Name = '1234' and CDH_Party_Number__c= '77777'].size());
        system.assertEquals(true,[select Credit_Hold__c from EBS_Account__c where Name = '1234'][3].Credit_Hold__c);
        system.assertEquals(true,[select Credit_Hold__c from EBS_Account__c where Name = '1234'][0].Credit_Hold__c);
                
        //   Test Case where Party Exists but Sales Account doesn't exists
        try
        {
            ebsAccountRecord.Account_Number = '1234';
            ebsAccountRecord.Sales_Account = '88888';
            ebsAccountRecord.Credit_Hold = true;
            ebsAccountRecord.Credit_Review_Cycle = 'ANUALLY';
            ebsAccountRecord.Classification = 'Federal';
            ebsAccountRecord.Account_Description ='test again';
            ebsAccountRecord.Sales_channel ='DIRECT END CUSTOMER';
            ebsAccountRecord.Status = 'Inactive';
            ebsAccountRecord.Account_Type = 'External';
            ebsAccountRecord.EBS_Party_Name = 'test1';
            ebsAccountRecord.EBS_Party_Number = '1234';
            ebsAccountRecord.Last_Credit_Review_Date = System.today() ;
            ebsAccountRecord.Next_Credit_Review_Date = System.today();
            ebsAccountRecord.Primary_EBS_Account =true;
            
            ebs.EbsAccountSync(ebsAccountRecord);
        }
        catch(exception e){
            system.assertequals('No Sales account under this CDH Party#',e.getmessage());
        }
        
        // Test Case where Party and  account doesn't exists
        try
        {
            ebsAccountRecord.Account_Number = '1234';
            ebsAccountRecord.Sales_Account = '99999';
            ebsAccountRecord.Credit_Hold = true;
            ebsAccountRecord.Credit_Review_Cycle = 'ANUALLY';
            ebsAccountRecord.Classification = 'Federal';
            ebsAccountRecord.Account_Description ='test again';
            ebsAccountRecord.Sales_channel ='DIRECT END CUSTOMER';
            ebsAccountRecord.Status = 'Inactive';
            ebsAccountRecord.Account_Type = 'External';
            ebsAccountRecord.EBS_Party_Name = 'test1';
            ebsAccountRecord.EBS_Party_Number = '1234';
            ebsAccountRecord.Last_Credit_Review_Date = System.today() ;
            ebsAccountRecord.Next_Credit_Review_Date = System.today();
            ebsAccountRecord.Primary_EBS_Account =true;
            
            ebs.EbsAccountSync(ebsAccountRecord);
        }
        catch(exception e){
            system.assertequals('CDH Party does not exist',e.getmessage());
        }
        
        //End of Test
        test.stopTest();   
    }
          
    
}