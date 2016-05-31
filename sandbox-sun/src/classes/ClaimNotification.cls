public class ClaimNotification
{

public static void createClaimMail(SFDC_MDF_Claim__c Budgetclaim)
{ 
 try 
    { 
        SFDC_MDF_Claim__c claim;
        List<Attachment> attachment1 = new List<Attachment>();
        Red_Hat_Attachment__c rhatt;
        List<Attachment> attachment2 = new List<Attachment>();
        User User_name;

        try {
                claim=[Select Id,Account__c,Fund_Request__c,Fund_Claim_Number_new__c,Name,Claim_Description__c,Requested_Amount__c,Approved_Date__c,CreatedById,CurrencyIsoCode from SFDC_MDF_Claim__c where Id =:Budgetclaim.Id];
                
                User_name=[Select Id,Name from User where Id=:claim.CreatedById];
                
                attachment1=[Select Id, Name,Body,ParentId from Attachment where ParentId =:claim.Id];

                rhatt=[Select Fund_Claim__c, Id from Red_Hat_Attachment__c where Fund_Claim__c=:claim.Id];
                
                attachment2=[Select Id, Name,Body,ParentId from Attachment where ParentId =:rhatt.Id];

          }
        Catch(Exception e )
            {
                 System.debug('e '+ e);
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  

            Account acc=[Select Id, Global_Region__c, Subregion__c, Name from Account where Id=:claim.Account__c];
            
            if(acc.Global_Region__c == 'NA'){
                System.debug('if statement');
            
                SFDC_MDF__c req_claim=[Select Id,Name,Estimated_Red_Hat_Funding_Requested__c,Activity_Type__c,Accounting_Type__c,Activity_End_Date__c,Activity_Start_Date__c  from SFDC_MDF__c where Id=:claim.Fund_Request__c];
    
                Organization Org_name= [Select Id,Name from Organization];
               
                if(claim.Claim_Description__c=='null'||claim.Claim_Description__c==' '){claim.Claim_Description__c=' ';}
                if(req_claim.Activity_Type__c=='null'||req_claim.Activity_Type__c==' '){req_claim.Activity_Type__c=' ';}
    
                // String[] toAddresses = new String[] {'MDF-Approved-Claims@redhat.com' };  
	            // String[] toAddresses = new String[] {'nbrown@redhat.com' };   
                String[] toAddresses = new String[] {'ap@redhat.com' }; // as directed by Finance.
                mail.setToAddresses(toAddresses); 
            
    
                    List<Messaging.EmailFileAttachment> arrFileAttachment= new List<Messaging.EmailFileAttachment>();
    
                    if(attachment1.size()>0)
                    {
                        for (Attachment objAttachment:attachment1)
                        {
                             Messaging.EmailFileAttachment mailAttachment= new Messaging.EmailFileAttachment();
                             mailAttachment.setFileName(objAttachment.Name);
                             mailAttachment.setBody(objAttachment.Body);
                             arrFileAttachment.add(mailAttachment);
                        } 
                    }   
                     if(attachment2.size()>0)
                    {
                        for (Attachment objAttachment:attachment2)
                        {
                             Messaging.EmailFileAttachment mailAttachment= new Messaging.EmailFileAttachment();
                             mailAttachment.setFileName(objAttachment.Name);
                             mailAttachment.setBody(objAttachment.Body);
                             arrFileAttachment.add(mailAttachment);
                        } 
                    }
                    
                    if(attachment1.size()>0 || attachment2.size()>0)
                    {
                       // System.debug('arrFileAttachment........'+arrFileAttachment);
                        mail.setFileAttachments(arrFileAttachment);
                    }
                   
                    // Specify the name used as the display name. 
                     mail.setSenderDisplayName('SALES FORCE');
                     // Specify the subject line for your email address. 
                     mail.setSubject('Fund Claim Approval Requested - '+ acc.Name);
                     // Set to True if you want to BCC yourself on the email. 
                     mail.setBccSender(false); 
                     mail.setUseSignature(false); 
                     
                     system.debug('did I get here?');
                     
                    String approver = 'Channel Operations';
                 
                    if(acc.Subregion__c == 'Fed Sled')
                        approver = 'Fed Sled Marketing Management';
                        
                    system.debug('approver');
                    
                     String body= ''+approver+' has approved the Fund Claim, invoice and proof of performance for '+req_claim.Activity_Type__c+ '.'+
                            '\n \n You have been assigned this Fund Claim for final approval.'+
                            '\n \n Account Name:'+acc.Name+
                            '\n Account Global Region:'+ acc.Global_Region__c+ 
                            '\n Account Subregion:'+ acc.Subregion__c + 
                            '\n Accounting Type:'+req_claim.Accounting_Type__c+
                            '\n Activity Type:'+req_claim.Activity_Type__c+
                            '\n Activity Start Date:'+ req_claim.Activity_Start_Date__c+
                            '\n Activity End Date:'+ req_claim.Activity_End_Date__c+
                            '\n Claim Amount Requested:'+claim.Requested_Amount__c+claim.CurrencyIsoCode+
                            '\n Claim Description:'+claim.Claim_Description__c+
                            '\n \n Follow this link for more information on the Fund Claim: https://na4.salesforce.com/'+claim.Id+
                            '\n \n Thanks, \n \n'+Org_name.Name+' Channel Sales';
    
                     mail.setPlainTextBody(body);
                     //System.Debug('mail body is added to email....'+mail);
                     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );
                     //System.Debug('mail sent....');
    
         } 
        }
         catch(Exception e) 
            { 
                 System.debug('Exception is =>' + e.getMessage()); } 
            }
  
}