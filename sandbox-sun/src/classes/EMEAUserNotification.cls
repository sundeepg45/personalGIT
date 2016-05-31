public class EMEAUserNotification{

public static void createMail(User emeauser){ 
try { 
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
    // Assign the addresses for the To and CC lists to the mail object. 

    String[] toAddresses = new String[] {'notify-EMEA-OM@redhat.com' };  
    mail.setToAddresses(toAddresses); 
    
    
    // String[] ccAddresses =new String[] {'prasadkothawade@gmail.com'};  
    // mail.setCcAddresses(ccAddresses);    
    
    // Specify the name used as the display name. 
    mail.setSenderDisplayName('SALES FORCE');
     // Specify the subject line for your email address. 
     mail.setSubject('New EMEA User Created');
     // Set to True if you want to BCC yourself on the email. 
     mail.setBccSender(false); 
     // Optionally append the salesforce.com email signature to the email. 
     // The email address of the user executing the Apex Code will be used. 
     mail.setUseSignature(false); 
     // Specify the text content of the email. 

     string body= 'Hello, \n A new EMEA user has been created in Salesforce. Please click on the following link to view the user record. \n'+ 'https://na4.salesforce.com/'+ emeauser.id +'\n'+'Details of the user are as follows:\n'+ 'Name:' + emeauser.firstname + ' '+emeauser.lastname +'\n' +'User Name:'+ emeauser.username +'\n' +'Email:' +emeauser.Email;
     mail.setPlainTextBody(body);

     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );
 
    } catch(Exception e) { System.debug('Exception is => ' + e.getMessage()); } 
 }

}