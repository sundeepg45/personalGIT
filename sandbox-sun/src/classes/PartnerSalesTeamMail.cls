global class PartnerSalesTeamMail
{
webservice static void createMail(String msg, String email, String sub)
{
try 
{
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
// Assign the addresses for the To and CC lists to the mail object.
String[] toAddresses = new String[] {email}; 
mail.setToAddresses(toAddresses);


mail.setSenderDisplayName('no-reply @redhat.com');

mail.setSubject(sub);
mail.setBccSender(false);


mail.setUseSignature(false); 

mail.setPlainTextBody(msg);
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );
} catch(Exception e)
{
//System.debug('Exception is => ' + e.getMessage());
}
}


public static testmethod void test1()
{
String msg='You have been added to the Sales Team';
String email='biswa.ranjan.ray@accenture.com';
String sub='Partner Addition to Sales Team';
createMail(msg, email, sub);
}



}