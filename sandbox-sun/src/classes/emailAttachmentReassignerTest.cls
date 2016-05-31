/**
* Class Name:emailAttachmentReassignerTest
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/11/2011
* Reason for Modification:@isTest annotation added to test class
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/

@isTest
private class emailAttachmentReassignerTest 
{
   public static testmethod void attachmentTester() 
   {
        Attachment a = new Attachment();
        a.name = 'test attachment';
        a.body = blob.valueof('attachment body');
        
        Case cs = new Case();
        cs.Type = 'SWAT';
        cs.Status = 'New';
        cs.Origin = 'Phone';
        cs.Type_Detail__c = 'NAT';
        insert cs;
        
        EmailMessage emailmsg = new EmailMessage();
        emailmsg.ParentId = cs.Id;
        insert emailmsg;
        
        a.parentid = emailmsg.Id;
        insert a;   

        
        Attachment a1 = new Attachment();
        a1.name ='attachment';
        a1.body = blob.valueof('attachment');     

        try {
        EmailMessage emailmsg1 = new EmailMessage();
        a1.parentid = emailmsg1.Id;
        
        insert a1;
             }
        catch (Exception e) { }     
  
        test.startTest();
         
        Attachment attach = new Attachment();
        attach = [Select ParentId from Attachment where id=:a.Id ];
        System.assertEquals(emailmsg.ParentId,attach.parentid);
        
        test.stopTest();    
   }   
}