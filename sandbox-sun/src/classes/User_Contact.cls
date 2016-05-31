/* 
 * This class is used to create contact everytime a new internal user gets inserted in the system or any user gets
 * reactivated and does not associated with any contact.
 *
 * @author: Nitesh Dokania
 * 2012-10-26 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2015-10-07 - Updated to only use a single account from String Setting UserContact.DefaultAccountId
 */
public without sharing class User_Contact
{
	static final Id DEFAULT_ACCOUNT_ID = '00130000009XNXFAA4';
	static final String DEFAULT_ACCOUNT_NAME = 'Red Hat (Internal Use Only)';
	static final String ACCOUNT_ID_SETTING = 'UserContact.DefaultAccountId';

	@TestVisible
	static Boolean isUserContactRunningTest = false;

	@TestVisible
	static Id accountId {
		get {
			if(accountId == null && ( isUserContactRunningTest || ! Test.isRunningTest()) )
			{
				List<Account> accounts = new List<Account>();
				try {
					accounts.addAll([select Id from Account where Name = :DEFAULT_ACCOUNT_NAME order by CreatedDate limit 1]);
					accounts.addAll([select Id from Account where Id = :DEFAULT_ACCOUNT_ID order by CreatedDate limit 1]);
					accounts.addAll([select Id from Account where Id = :StringSetting__c.getInstance(ACCOUNT_ID_SETTING).Value__c ]);
				}
				catch(Exception ex) {}
				System.assert(! accounts.isEmpty(),'No Red Hat Accounts found!  Check the StringSetting__c value of : '+ACCOUNT_ID_SETTING);
				accountId = accounts[accounts.size()-1].Id;
			}
			return accountId;
		}
		set;
	}

	@future
	public static void associatedContact(List<String> userIds, List<String> emails)
	{
		List<User> users = [
			select 
				LastName,
				Email,
				FirstName,
				Name,
				Contact__c,
				Contact_Id__c,
				Associated_Contact__c,
				UserType
			from User
			where id in : userIds];

		Map<Id,Contact> contactMap = new Map<Id,Contact>();
		for(User u : users) {
			if(String.isBlank(u.Contact_Id__c) && accountId != null) {
				System.debug('inside iff');
				Contact c = new Contact(
					LastName = u.LastName,
					FirstName = u.FirstName,
					Email = u.Email,
					AccountId = accountId);
				contactMap.put(u.Id,c);
			}
		}

		if(! contactMap.isEmpty()) {
			List<Contact> contacts = new List<Contact>(contactMap.values());
			for(Database.SaveResult sr : Database.insert(contacts,false)) {
				Contact c = contacts.remove(0);
				if(! sr.isSuccess()) {
					System.debug('Failed to insert contact: '+c+'\n'+sr.getErrors());
				}
			}
			List<User> updateUsers = new List<User>();
			for(User u : users) {
				Contact c = contactMap.get(u.Id);
				if(c != null && c.Id != null) {
					u.Contact_Id__c = c.Id;
					u.Associated_Contact__c = c.FirstName+' '+c.LastName;
					updateUsers.add(u);
				}
			}
			if(! updateUsers.isEmpty()) {
				for(Database.SaveResult sr : Database.update(updateUsers,false)) {
					User u = updateUsers.remove(0);
					if(! sr.isSuccess()) {
						System.debug('Failed to update user: '+u+'\n'+sr.getErrors());
					}
				}
			}
		}
	}
}