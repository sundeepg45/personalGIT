public class MailServiceFailuerNotification
{   

    public void sendMail(Exception e,String Source,Messaging.InboundEmail email){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses =new String[] {'brijesh.bohidar@accenture.com','prasad.s.kothawade@accenture.com'};

        mail.setToAddresses(toAddresses);
        //mail.setCcAddresses(ccAddresses);

        // Specify the address used when the recipients reply to the email.
        // mail.setReplyTo('pras');

        // Specify the name used as the display name.
        mail.setSenderDisplayName('SALES FORCE');

        // Specify the subject line for your email address.
        mail.setSubject('Exception in Mail Service for '+source);

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);
        // Optionally append the salesforce.com email signature to the email.
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);
        // Specify the text content of the email.
        String body='Error Occured in '+ source +' as ' + e;
        body=body + '\n The Mail u send is as \n'+'Subject: '+email.subject+'\n' + email.plainTextBody;
        mail.setPlainTextBody(body);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );
    }
    
}