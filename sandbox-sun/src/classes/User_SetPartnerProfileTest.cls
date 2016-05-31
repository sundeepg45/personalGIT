@isTest
public class User_SetPartnerProfileTest{
    @isTest (seeAllData = true)
	public static void testSetPartnerProfileAsAPIUser()
    {
    	Account account = PartnerTestUtils.quickGenericAccountSetup('Most Amazing 13th Partner of the World');
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'loginusertestnumber13@redhat.com');
        insert contact;

        Id profileId = [Select Id from profile where name like 'EMEA Partner%Deal Registration'].Id;
        
        User pcmu = [select Id from user where username like 'partnercenter_migration@redhat.com%'];
        User sampleUser = [select TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey from user where id = :UserInfo.getUserId()];
        
        // Run as API User
        System.RunAs(pcmu) {
            User sfUser = new User();
            sfUser.Username = 'RandomStringUserCreate' + contact.Email;
            sfUser.ProfileId = profileId;
            sfUser.FederationIdentifier = contact.LoginName__c;
            sfUser.FirstName = contact.FirstName;
            String alias = contact.FirstName.trim();
            if (alias.length() > 4) {
                alias = alias.substring(0, 4);
            }
            alias = alias + contact.LastName.trim();
            if (alias.length() > 8) {
                alias = alias.substring(0, 8);
            }
            sfUser.Alias = alias.toLowerCase();
            String nick = contact.FirstName.trim();
            if (nick.length() > 20) {
                nick = nick.substring(0, 20);
            }
            nick = nick + contact.LastName.trim();
            if (nick.length() > 40) {
                nick = nick.substring(0, 40);
            }
            sfUser.CommunityNickname = nick;
            sfUser.LastName = contact.LastName;
            sfUser.Street = contact.MailingStreet;
            sfUser.City = contact.MailingCity;
            sfUser.PostalCode = contact.MailingPostalCode;
            sfUser.State = contact.MailingState;
            sfUser.Country = contact.MailingCountry;
            sfUser.Email = contact.Email;
            sfUser.Phone = contact.Phone;
            sfUser.IsPartnerAdmin__c = true;
            sfUser.IsActive = true;
            
            //Stuff
            sfUser.ContactId = contact.id;
            sfUser.TimeZoneSidKey = sampleuser.timeZoneSidKey;
            sfUser.LocaleSidKey = sampleuser.LocaleSidKey;
            sfUser.EmailEncodingKey = sampleuser.EmailEncodingKey;
            sfUser.LanguageLocaleKey = sampleuser.LanguageLocaleKey;
           //End stuff     
            insert sfUser;
        }
    }
}