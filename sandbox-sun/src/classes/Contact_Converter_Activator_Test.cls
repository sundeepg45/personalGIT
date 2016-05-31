/**
 * Class Name:Contact_Converter_Activator_Test
 * Description:Test Class created for Contact_Converter_Activator Trigger.
 * Modificaton History:
 * Modified By :Abhijeet Anand
 * Reason for Modification:Enhanced code coverage and added assert statements.
 */

@IsTest
private class Contact_Converter_Activator_Test 
{

    public static testmethod void testConversion() 
    {
        Account acc = new Account();
        acc.Name='TestAccNew';    
        acc.CurrencyIsoCode='USD';
        acc.Global_Region__c='xyz';
        insert acc;
          
        Account accNew = new Account();
        accNew.Name='TestAccNew';    
        accNew.CurrencyIsoCode='USD';
        //accNew.Global_Region__c='';
        insert accNew ;
          
        Account accNew1 = new Account();
        accNew1.Name='TestAccNew';    
        accNew1.CurrencyIsoCode='USD';
        accNew1.Global_Region__c='NA';        
        insert accNew1 ;          
          
        List<Contact>contactList = new List<Contact>();
                 
        Contact c1 = new Contact();
        c1.LastName ='ABC';
        c1.FirstName ='YED';
        c1.LoginName__c='Y';
        c1.Email='abc1@gmail.com';
        contactList.add(c1);
          
        Contact c2 = new Contact();
        c2.LastName ='CDE';
        c2.FirstName='HANNA'; 
        c2.LoginName__c='X';
        c2.Email='abc2@gmail.com';
        c2.AccountId =accNew.Id;
        contactList.add(c2);

        Contact c3 = new Contact();
        c3.FirstName='OP'; 
        c3.LastName ='FG';
        c3.Email='abc3@gmail.com';
        c3.AccountId =acc.Id;
        contactList.add(c3);
          
        Contact c4 = new Contact();
        c4.LastName ='GH';
        c4.LoginName__c='RS';
        c4.Email='abc4@gmail.com';
        c4.AccountId =acc.Id;
        contactList.add(c4);
        
        Contact c5 = new Contact();
        c5.FirstName='RS';
        c5.LastName ='HI';
        c5.LoginName__c='XY';
        c5.AccountId =acc.Id;
        contactList.add(c5 );         
          
        Contact c6 = new Contact();
        c6.FirstName='RY';
        c6.LastName='UU';
        c6.LoginName__c='JJ';
        c6.Email='abc6@gmail.com';
        c6.AccountId =acc.Id;
        contactList.add(c6);
          
        Contact c7 = new Contact();
        c7.FirstName='RZ';
        c7.LastName='VV';
        c7.LoginName__c='JJ';
        c7.Email='abc7@gmail.com';
        c7.AccountId =accNew1.Id;
        contactList.add(c7 );        
          
        Contact c8 = new Contact();
        c8.LastName ='ABC';
        c8.FirstName='XYZ';
        c8.Email='abc8@gmail.com';
        c8.LoginName__c='NN';
        c8.AccountId =accNew1.Id;
        contactList.add(c8);
          
        Contact c9 = new Contact();
        c9.LastName ='ABC';
        c9.FirstName='XYZ';
        c9.Email='abc9@gmail.com';
        c9.LoginName__c='MM';
        c9.AccountId =accNew1.Id;
        contactList.add(c9);
          
        Contact c10 = new Contact();
        c10.LastName ='CDE';
        c10.FirstName='YZT';
        c10.Email='abc10@gmail.com';
        c10.LoginName__c='CC';
        c10.AccountId =acc.Id;
        contactList.add(c10 );
        
        insert contactList;
          
        User partnerusr = [Select Id, FederationIdentifier from User where ContactId != null limit 1];
        partnerusr.FederationIdentifier  = c9.LoginName__c;
        update partnerusr;
           
        List<Contact_Converter__c> contactCnvtr = new List<Contact_Converter__c>();
        Contact_Converter__c cvt1 = new Contact_Converter__c();
        cvt1.ContactId__c = c1.Id;
        contactCnvtr.add(cvt1);
          
        Contact_Converter__c cvt2 = new Contact_Converter__c();
        cvt2.ContactId__c = c2.Id;
        contactCnvtr.add(cvt2);
          
        Contact_Converter__c cvt3 = new Contact_Converter__c();
        cvt3.ContactId__c = c3.Id;
        contactCnvtr.add(cvt3);
          
        Contact_Converter__c cvt4 = new Contact_Converter__c();
        cvt4.ContactId__c = c4.Id;
        contactCnvtr.add(cvt4);
         
        Contact_Converter__c cvt5 = new Contact_Converter__c();
        cvt5.ContactId__c = c5.Id;
        contactCnvtr.add(cvt5);
     
        Contact_Converter__c cvt6 = new Contact_Converter__c();
        cvt6.ContactId__c =partnerusr.contactId ;
        contactCnvtr.add(cvt6);
          
        Contact_Converter__c cvt7 = new Contact_Converter__c();
        cvt7.ContactId__c =c6.Id ;
        contactCnvtr.add(cvt7);         
           
        Contact_Converter__c cvt8 = new Contact_Converter__c();
        cvt8.ContactId__c =c7.Id ;
        contactCnvtr.add(cvt8); 
          
        Contact_Converter__c cvt9 = new Contact_Converter__c();
        cvt9.ContactId__c =c8.Id ;
        contactCnvtr.add(cvt9);          
          
        Contact_Converter__c cvt10 = new Contact_Converter__c();
        cvt10.ContactId__c =c9.Id;
        contactCnvtr.add(cvt10); 
  
        Contact_Converter__c cvt11 = new Contact_Converter__c();
        cvt11.ContactId__c =c10.Id;
        contactCnvtr.add(cvt11 ); 
         
        insert contactCnvtr;   
          
        Test.startTest(); 
        
        Contact_Converter__c cvt12 = new Contact_Converter__c();
        cvt12=[Select UserActivationResult__c  from Contact_Converter__c where id=:cvt4.id];  
        System.assertEquals('Error: First Name is blank',cvt12.UserActivationResult__c );
          
        Test.stopTest();          
    }
}