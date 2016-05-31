/**
* Class Name:RequestTrackerOperationTest
* Description: Test Class created for RequestTrackerOperation business Class
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/15/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Nitesh Dokania
* Modified date :6/13/2011
* Reason for Modification: Enhanced test class code coverage.
*/

@isTest
private class RequestTrackerOperationTest
{
    public static testmethod void deployRT(){
        
        Messaging.InboundEmail resolved_email = new Messaging.InboundEmail();
        Messaging.InboundEmail new_email = new Messaging.InboundEmail();
        Messaging.InboundEmail new_email1 = new Messaging.InboundEmail();
        Messaging.InboundEmail new_email2 = new Messaging.InboundEmail();
        Messaging.InboundEmail new_email3 = new Messaging.InboundEmail();
        Messaging.InboundEmail new_email4 = new Messaging.InboundEmail();
        Messaging.InboundEmail status_email = new Messaging.InboundEmail();
        Messaging.InboundEmail status_emailObj = new Messaging.InboundEmail();
    
        String rt_no='00'; 

        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = '012300000000NBG';
        insert acc;
        
        Opportunity  oppNew = new Opportunity(name='Test Request Tracker',closedate=System.today(),stageName='Unqualified',Country_of_Order__c ='India');
        insert oppNew;
        
        Contact con = new Contact(FirstName='Test',LastName='Contact',Email='test@test.com',AccountId=acc.Id);
        insert con;
        
        String sfdcurl='https://na4.salesforce.com/' + acc.Id;
        String sfdcurl1='https://na4.salesforce.com/' + oppNew.Id;
        String sfdcurl2='https://na4.salesforce.com/' + con.Id;
        
        // Resolved 
        String subject='RE: [redhat.com #'+rt_no+'] Resolved: TEST Call GPS-Other: TUI Infotec GmbH & Co. KG-, Germany - 11.04.2008 ';
        String plainTextBody='According to our records, your request regarding "TEST Call GPS-Other: TUI Infotec GmbH & Co. KG-, Germany - 11.04.2008" (ticket # 11111) has been resolved by clasohm@redhat.com.\n'+
        'If you have any further questions or concerns, please respond to this message.\n'+
        'Thank you,\n'+
        'your Red Hat Presales Team EMEA \n'+
        'presales-emea@redhat.com \n'+
        'sfdcURL: '+ sfdcurl;

        resolved_email.PlainTextBody=plainTextBody;
        resolved_email.Subject=subject;


        //New
        subject='[redhat.com #'+rt_no+'] AutoReply: TEST Call Qualification1: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST';
        plainTextBody='Thank you for your message to presales-emea@redhat.com regarding: \n'+
        '"TEST Call Qualification: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST" \n'+
        'This ticket has been created to follow up on your request.\n'+
        'There is no need to reply to this message right now. Your ticket has been\n'+
        'assigned an ID of #13.\n'+
        'Please include the string:\n'+
        '         [redhat.com #13]\n'+
        'in the subject line of all future correspondence about this issue. To do so,\n'+
        'you may reply to this message.\n'+
        'We will keep you informed about the progress on your request by automatically\n'+
        'created email messages.\n'+
        'Thank you,\n'+
        'your Red Hat Presales Team EMEA\n'+
        'presales-emea@redhat.com \n'+
        '-------------------------------------------------------------------------\n'+
        'OriginalRecipient: presales-ce@redhat.com\n'+
        'SFObject: account \n'+
        'URL:' + sfdcurl + ' \n'+
        'Requester: jschrode@redhat.com \n'+
        'Account: Metro Group Information Technology MGI \n'+
        'AccountType: Sales - Customer \n'+
        'SalesOwner: nstankau@redhat.com.qa \n'+
        'PresalesOwner: jschrode@redhat.com \n'+
        'AddressCountry: Germany \n'+
        'AddressCity: Düsseldorf \n'+
        'AddressStreet: MGI \n'+
        'Metro Group Information Technology GmbH \n'+
        'Metro Strasse 12 \n'+
        'Task: TEST \n'+
        'Mission: TEST \n'+
        'Region: CE \n'+
        'JBoss: nonJBoss \n'+
        'RegionCountry: Germany \n'+
        'Audience: Customer \n'+
        'AudienceBackground: TEST \n'+
        'RequestType: Call \n'+
        'Location: Düsseldorf, MGI \n'+ 
        'Metro Group Information Technology GmbH \n'+
        'Metro Strasse 12 \n'+ 
        'Contact: TEST \n'+
        'Deliverable: Qualification \n'+
        'DateDueDate: TEST\n';

        new_email.PlainTextBody=plainTextBody;
        new_email.Subject=subject;

        subject='[redhat.com #'+rt_no+'] AutoReply: TEST Call Qualification2: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST';
        plainTextBody='T'+ sfdcurl;
        
        new_email1.PlainTextBody=plainTextBody;
        new_email1.Subject=subject;
        
        subject='[redhat.com #'+rt_no+'] AutoReply: TEST Call Qualification3: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST';
        plainTextBody='Thank'+ sfdcurl;
        
        new_email2.PlainTextBody=plainTextBody;
        new_email2.Subject=subject;
        
        subject='[redhat.com #'+rt_no+'] AutoReply: TEST Call Qualification4: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST';
        plainTextBody='Thank you for your message to presales-emea@redhat.com regarding: \n'+
        '"TEST Call Qualification: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST" \n'+
        'This ticket has been created to follow up on your request.\n'+
        'There is no need to reply to this message right now. Your ticket has been\n'+
        'assigned an ID of #13.\n'+
        'Please include the string:\n'+
        '         [redhat.com #13]\n'+
        'in the subject line of all future correspondence about this issue. To do so,\n'+
        'you may reply to this message.\n'+
        'We will keep you informed about the progress on your request by automatically\n'+
        'created email messages.\n'+
        'Thank you,\n'+
        'your Red Hat Presales Team EMEA\n'+
        'presales-emea@redhat.com \n'+
        '-------------------------------------------------------------------------\n'+
        'OriginalRecipient: presales-ce@redhat.com\n'+
        'SFObject: account \n'+
        'URL:' + sfdcurl1 + ' \n'+
        'Requester: jschrode@redhat.com \n';
        
        new_email3.PlainTextBody=plainTextBody;
        new_email3.Subject=subject;
        
        subject='[redhat.com #'+rt_no+'] AutoReply: TEST Call Qualification5: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST';
        plainTextBody='Thank you for your message to presales-emea@redhat.com regarding: \n'+
        '"TEST Call Qualification: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST" \n'+
        'This ticket has been created to follow up on your request.\n'+
        'There is no need to reply to this message right now. Your ticket has been\n'+
        'assigned an ID of #13.\n'+
        'Please include the string:\n'+
        '         [redhat.com #13]\n'+
        'in the subject line of all future correspondence about this issue. To do so,\n'+
        'you may reply to this message.\n'+
        'We will keep you informed about the progress on your request by automatically\n'+
        'created email messages.\n'+
        'Thank you,\n'+
        'your Red Hat Presales Team EMEA\n'+
        'presales-emea@redhat.com \n'+
        '-------------------------------------------------------------------------\n'+
        'OriginalRecipient: presales-ce@redhat.com\n'+
        'SFObject: account \n'+
        'URL:' + sfdcurl2 + ' \n'+
        'Requester: jschrode@redhat.com \n';
        
        new_email4.PlainTextBody=plainTextBody;
        new_email4.Subject=subject;
        
        //Status changed 
        subject='[redhat.com #] TEST Call Qualification6: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST - open/Nobody';
        plainTextBody='Fri Apr 18 11:57:04 2008: Request 615039 was acted upon.\n'+
        'Transaction: Status changed from new to open by RT_System \n'+
        '       Queue: Sales_ENG_EMEA \n'+
        '     Subject: TEST Call Qualification: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST \n'+
        '       Owner: Nobody \n'+
        '  Requestors: joachim.schroeder@redhat.com \n'+
        '      Status: open \n'+
        ' Ticket <URL: https://rt.corp.redhat.com:443/rt3/Ticket/Display.html?id='+rt_no+'>  SelfService <URL: https://rt.corp.redhat.com:443/rt3/SelfService/Display.html?id='+rt_no+'> \n'+
        ' sfdcURL: '+ sfdcurl + '\n'+
        'Status changed from new to open by RT_System\n'+
        '-------------------------------------------------------\n'+
        'If you reply to this message, please dont quote the whole content of this mail! \n';
        
        status_email.PlainTextBody=plainTextBody;
        status_email.Subject=subject;
        
        subject='[redhat.com #'+rt_no+'] TEST Call Qualification6: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST - open/Nobody';
        plainTextBody='Fri Apr 18 11:57:04 2008: Request 615039 was acted upon.\n'+
        'Transaction: Status changed from new to open by RT_System \n'+
        '       Queue: Sales_ENG_EMEA \n'+
        '     Subject: TEST Call Qualification: Metro Group Information Technology "MGI-Düsseldorf," Germany - TEST \n'+
        '       Owner: Nobody \n'+
        '  Requestors: joachim.schroeder@redhat.com \n'+
        '      Status: open \n'+
        ' Ticket <URL: https://rt.corp.redhat.com:443/rt3/Ticket/Display.html?id='+rt_no+'>  SelfService <URL: https://rt.corp.redhat.com:443/rt3/SelfService/Display.html?id='+rt_no+'> \n'+
        ' sfdcURL: '+ sfdcurl + '\n'+
        'Status changed from new to open by RT_System\n'+
        '-------------------------------------------------------\n'+
        'If you reply to this message, please dont quote the whole content of this mail! \n';
        
        status_emailObj.PlainTextBody=plainTextBody;
        status_emailObj.Subject=subject;

        test.startTest();
        
        //Messaging.sendEmail(new Messaging.InboundEmail[] { new_email,resolved_email,status_email  } );    
        RequestTrackerOperation  RT=new RequestTrackerOperation ();
        
        RT.handleInboundEmail(new_email, new Messaging.InboundEnvelope() );
        
        Request_Tracker__c reqTrack = new Request_Tracker__c();
        reqTrack = [Select Id, Name from Request_Tracker__c where Account__c =: acc.Id limit 1];
        
        System.assertEquals('00', reqTrack.Name);
        
        RT.handleInboundEmail(status_email, new Messaging.InboundEnvelope() );
        Request_Tracker__c reqTrck = new Request_Tracker__c();
        reqTrck = [Select Id, Name,Status__c from Request_Tracker__c where Account__c =: acc.Id limit 1];
        
        System.assertEquals('New', reqTrck.Status__c);
        
        RT.doEventStatusChange(status_email);
        RT.doEventStatusChange(status_emailObj);
        
        RT.handleInboundEmail(resolved_email, new Messaging.InboundEnvelope() );
        
        RT.handleInboundEmail(status_emailObj, new Messaging.InboundEnvelope() );
        
        RT.handleInboundEmail(new_email1, new Messaging.InboundEnvelope() );
        RT.handleInboundEmail(new_email2, new Messaging.InboundEnvelope() );
        RT.handleInboundEmail(new_email3, new Messaging.InboundEnvelope() );
        RT.handleInboundEmail(new_email4, new Messaging.InboundEnvelope() );
        
        RequestTrackerOperation  newRTObj = new RequestTrackerOperation ();
        newRTObj.doEventCloseRequest(status_email);
        
        test.stopTest();
    }
}