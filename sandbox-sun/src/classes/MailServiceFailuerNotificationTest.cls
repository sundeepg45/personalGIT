/**
* Class Name:MailServiceFailuerNotificationTest
* Author:Accenture
* Date:4/11/2011
* Description:Test Class created for MailServiceFailuerNotification business Class
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :4/11/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/





@isTest
private class MailServiceFailuerNotificationTest
{
    public static testmethod void deployMailServiceFailuerNotification()
    { 
        try
        {
            String name='Prasad';
            name.substring(3,10);
        }
        catch(Exception e)
        {
            new MailServiceFailuerNotification().sendMail(e,'Test Coverage', new Messaging.InboundEmail() );
        }
    }
}