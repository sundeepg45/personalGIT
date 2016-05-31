/**
 * This is a test class for Account_ControllerExtension.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-23
 * 2012-01-23 - created
 */
@isTest
private class SendPageByEmailControllerTest {
	static final List<String> TEST_EMAILS = new List<String>{
		'noone@nowhere.com.test0',
		'noone@nowhere.com.test1',
		'noone@nowhere.com.test2' };
	static List<Account> accounts {
		get {
			if(accounts == null) {
				accounts = new List<Account>{
					new Account(
						Name='TestAccount',
						Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
						AccountClassification__c='EMEA - Hosting',
						BillingCity='Testville',
						BillingStreet='1 no where',
						BillingCountry='US',
						Middleware_Supported__c='None',
						OwnerId = UserInfo.getUserId(),
						Ownership = 'Private',
						Total_of_Subsidiaries_if_Parent__c=5,
						VATNumber__c=null,
						What_Markets_are_Targeted__c='Vertical market'),
					new Account(
						Name='TestAccount2',
						Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
						AccountClassification__c='EMEA - Hosting',
						BillingCity='Testville 2',
						BillingStreet='2 no where',
						BillingCountry='US',
						Middleware_Supported__c='None',
						OwnerId = UserInfo.getUserId(),
						Ownership = 'Private',
						Total_of_Subsidiaries_if_Parent__c=5,
						VATNumber__c=null,
						What_Markets_are_Targeted__c='Vertical market') };
			}
			return accounts;
		}
	}

	static Account account {
		get {
			return accounts[0];
		}
	}

	static Id accountId {
		get {
			if(account.Id == null) {
				insert accounts;
			}
			return account.Id;
		}
	}

	static List<Contact> contacts {
		get {
			if(contacts == null) {
				contacts = new List<Contact>{
					new Contact(
						Email=TEST_EMAILS[0],
						FirstName= UserInfo.getFirstName(),
						LastName =UserInfo.getLastName(),
						AccountId = accountId),
					new Contact(
						Email=TEST_EMAILS[1],
						FirstName= UserInfo.getFirstName(),
						LastName =UserInfo.getLastName(),
						AccountId = accounts[1].Id) };
			}
			return contacts;
		}
	}

	static Contact contact {
		get {
			return contacts[0];
		}
	}

	static Id contactId {
		get {
			if(contact.Id == null) {
				insert contacts;
			}
			return contact.Id;
		}
	}

	static AccountContactRole accountContactRole {
		get {
			if(accountContactRole == null) {
				Id x = contactId;
				accountContactRole = new AccountContactRole(
					AccountId=accountId,
					ContactId=contacts[1].Id,
					IsPrimary=true,
					Role='Buyer');
			}
			return accountContactRole;
		}
	}

	static Id accountContactRoleId {
		get {
			if(accountContactRole.Id == null) {
				insert accountContactRole;
			}
			return accountContactRole.Id;
		}
	}

	@isTest
	static void beanTests() {
		Test.startTest();
		SendPageByEmailController controller = new SendPageByEmailController();

		System.assertEquals(null,controller.accountContactRoleWhereConditions);
		controller.accountContactRoleWhereConditions = 'fudge';
		System.assertEquals('fudge',controller.accountContactRoleWhereConditions);
		controller.accountContactRoleWhereConditions = '';
		System.assertEquals(null,controller.accountContactRoleWhereConditions);

		System.assertEquals(null,controller.contactWhereConditions);
		controller.contactWhereConditions = 'fudge';
		System.assertEquals('fudge',controller.contactWhereConditions);
		controller.contactWhereConditions = '';
		System.assertEquals(null,controller.contactWhereConditions);

		System.assertEquals(SendPageByEmailController.PAGE_NAME,controller.displayName);
		controller.displayName = 'fudge';
		System.assertEquals('fudge',controller.displayName);
		controller.displayName = null;
		System.assertEquals(SendPageByEmailController.PAGE_NAME,controller.displayName);

		System.assertEquals(SendPageByEmailController.OBJECT_LABEL,controller.objectLabel);
		controller.objectLabel = 'fudge';
		System.assertEquals('fudge',controller.objectLabel);
		controller.objectLabel = '';
		System.assertEquals(SendPageByEmailController.OBJECT_LABEL,controller.objectLabel);

		System.assertEquals(SendPageByEmailController.PAGE_NAME,controller.pageName);
		controller.pageName = 'fudge';
		System.assertEquals('fudge',controller.pageName);
		controller.pageName = null;
		System.assertEquals(SendPageByEmailController.PAGE_NAME,controller.pageName);

		System.assertEquals(null,controller.pageUrl);
		controller.pageUrl = '/'+UserInfo.getUserId();
		System.assertEquals('/'+UserInfo.getUserId(),controller.pageUrl);
		controller.pageUrl = '';
		System.assertEquals(null,controller.pageUrl);

		System.assertEquals(SendPageByEmailController.PLAIN_TEXT_BODY,controller.getPlainTextBody());
		controller.setPlainTextBody('fudge');
		System.assertEquals('fudge',controller.getPlainTextBody());
		controller.setPlainTextBody(null);
		System.assertEquals(SendPageByEmailController.PLAIN_TEXT_BODY,controller.getPlainTextBody());

		controller.sender = new User(FirstName='cat',LastName='dog');
		System.assertEquals('cat dog',SendPageByEmailController.getSenderDisplayName(controller.sender));
		controller.sender = null;
		System.assertEquals(UserInfo.getUserId(),controller.sender.Id);

		System.assertEquals(SendPageByEmailController.SUBJECT_FOR_EMAIL,controller.getSubjectForEmail());
		controller.setSubjectForEmail('fudge');
		System.assertEquals('fudge',controller.getSubjectForEmail());
		controller.setSubjectForEmail('');
		System.assertEquals(SendPageByEmailController.SUBJECT_FOR_EMAIL,controller.getSubjectForEmail());

		System.assertEquals(SendPageByEmailController.NUMBER_TO_ADD,controller.numberOfBlankEmailLines);
		controller.numberOfBlankEmailLines = SendPageByEmailController.NUMBER_TO_ADD+3;
		System.assertEquals(SendPageByEmailController.NUMBER_TO_ADD+3,controller.numberOfBlankEmailLines);
		System.assertEquals(SendPageByEmailController.NUMBER_TO_ADD+3,controller.toAddressList.size());
		System.assertEquals(false,controller.isToAddressListEmpty);
		controller.toAddressList = null;
		controller.numberOfBlankEmailLines = 0;
		System.assertEquals(0,controller.numberOfBlankEmailLines);
		System.assertEquals(0,controller.toAddressList.size());
		System.assertEquals(true,controller.isToAddressListEmpty);

		System.assertEquals(SendPageByEmailController.NUMBER_TO_ADD,controller.numberOfBlankUserLines);
		controller.numberOfBlankUserLines = SendPageByEmailController.NUMBER_TO_ADD+3;
		System.assertEquals(SendPageByEmailController.NUMBER_TO_ADD+3,controller.numberOfBlankUserLines);
		System.assertEquals(SendPageByEmailController.NUMBER_TO_ADD+3,controller.toUserAddressList.size());
		System.assertEquals(false,controller.isToUserAddressListEmpty);
		controller.toUserAddressList = null;
		controller.numberOfBlankUserLines = 0;
		System.assertEquals(0,controller.numberOfBlankUserLines);
		System.assertEquals(0,controller.toUserAddressList.size());
		System.assertEquals(true,controller.isToUserAddressListEmpty);

		System.assertEquals(null,controller.userWhereConditions);
		controller.userWhereConditions = 'fudge';
		System.assertEquals('fudge',controller.userWhereConditions);
		controller.userWhereConditions = '';
		System.assertEquals(null,controller.userWhereConditions);
		Test.stopTest();
	}

	@isTest(SeeAllData=true)
	static void templateDeveloperNameTest() {
		SendPageByEmailController controller = new SendPageByEmailController();
		System.assertEquals(null,controller.templateDeveloperName);
		for(List<EmailTemplate> templates = [
				select Body, DeveloperName, Subject
				from EmailTemplate
				where Folder.Type = 'Email'
					and IsActive = true
					and TemplateType = 'text'
				limit 10];;)
		{
			EmailTemplate et = templates.remove(0);
			if(templates.isEmpty() || (et.Body != null && et.Subject != null)) {
				Test.startTest();
				controller.templateDeveloperName = et.DeveloperName;
				System.assertEquals(et.DeveloperName,controller.templateDeveloperName);
				if(et.Body != null) {
					System.assertEquals(et.Body,controller.getPlainTextBody());
				}
				if(et.Subject != null) {
					System.assertEquals(et.Subject,controller.getSubjectForEmail());
				}
				controller.setPlainTextBody('1');
				controller.setSubjectForEmail('2');
				if(et.Body != null) {
					System.assertEquals(et.Body,controller.getPlainTextBody());
				}
				if(et.Subject != null) {
					System.assertEquals(et.Subject,controller.getSubjectForEmail());
				}
				Test.stopTest();
				break;
			}
		}
	}

	@isTest
	static void addressListTests() {
		insert accountContactRole;

		Test.startTest();
		SendPageByEmailController controller = new SendPageByEmailController();
		controller.accountIdForLookup = accountId;

		// check the e-mail list
		Set<String> emails = new Set<String>(controller.addToAddresses(new List<String>()));
		System.assertEquals(0,emails.size());

		// Address tests (adding)
		controller.numberOfBlankEmailLines = 1;
		SendPageByEmailController.Address ea = controller.toAddressList[0];
		System.assertEquals(1,controller.toAddressList.size());
		System.assertEquals(false,ea.getIsValid());
		System.assertEquals(null,ea.email);
		ea.email = TEST_EMAILS[2];
		System.assertEquals(TEST_EMAILS[2],ea.email);
		System.assertEquals(true,ea.getIsValid());
		System.assertEquals(2,controller.toAddressList.size());

		// check the e-mail list
		emails = new Set<String>(controller.addToAddresses(new List<String>()));
		System.assert(emails.contains(TEST_EMAILS[2]),'Expecting '+TEST_EMAILS[2]);
		System.assertEquals(1,emails.size());

		// Users tests (adding)
		controller.userWhereConditions = 'Id = \''+controller.sender.Id+'\'';
		controller.numberOfBlankUserLines = 1;
		controller.toUserAddressList = null;
		System.assertEquals(2,controller.toUserAddressList.size());
		SendPageByEmailController.UserAddress currentUserAddress = null;
		SendPageByEmailController.UserAddress blankUserAddress = null;
		for(SendPageByEmailController.UserAddress a : controller.toUserAddressList) {
			if(a.getUseLookup()) {
				System.assertEquals(null,blankUserAddress);
				blankUserAddress = a;
				System.assertNotEquals(null,a.getLookup());
				System.assertEquals(null,a.user);
				System.assertEquals(true,a.isDeleted);
				a.getLookup().User__c = UserInfo.getUserId();
			}
			else {
				System.assertEquals(null,currentUserAddress);
				currentUserAddress = a;
				System.assertEquals(null,a.getLookup());
				System.assertEquals(true,a.isDeleted);
				a.addAddress();
			}
			System.assertEquals(UserInfo.getUserId(),a.user.Id);
			System.assertEquals(controller.sender.Email,a.getEmail());
			System.assertEquals(false,a.isDeleted);
		}

		// check the e-mail list
		emails = new Set<String>(controller.addToAddresses(new List<String>()));
		System.assert(emails.contains(TEST_EMAILS[2]),'Expecting '+TEST_EMAILS[2]);
		System.assert(emails.contains(controller.sender.Email),'Expecting '+controller.sender.Email);
		System.assertEquals(2,emails.size());

		// contact tests (adding)
		controller.contactWhereConditions = 'AccountId = :accountId';
		controller.toContactAddressList = null;
		SendPageByEmailController.ContactAddress ca = controller.toContactAddressList[0];
		System.assertEquals(1,controller.toContactAddressList.size());
		System.assertEquals(contact.Id,ca.getContact().Id);
		System.assertEquals(contact.Email,ca.getEmail());
		System.assertEquals(true,ca.isDeleted);
		ca.addAddress();
		System.assertEquals(false,ca.isDeleted);

		// check the e-mail list
		emails = new Set<String>(controller.addToAddresses(new List<String>()));
		System.assert(emails.contains(TEST_EMAILS[0]),'Expecting '+TEST_EMAILS[0]);
		System.assert(emails.contains(TEST_EMAILS[2]),'Expecting '+TEST_EMAILS[2]);
		System.assert(emails.contains(controller.sender.Email),'Expecting '+controller.sender.Email);
		System.assertEquals(3,emails.size());

		// account contact role tests (adding)
		controller.accountContactRoleWhereConditions = 'AccountId = :accountId';
		controller.toAccountContactRoleAddressList = null;
		SendPageByEmailController.AccountContactRoleAddress acra = controller.toAccountContactRoleAddressList[0];
		System.assertEquals(1,controller.toAccountContactRoleAddressList.size());
		System.assertEquals(accountContactRole.ContactId,acra.getAccountContactRole().Contact.Id);
		System.assertEquals(contacts[1].Email,acra.getEmail());
		System.assertEquals(true,acra.isDeleted);
		acra.addAddress();
		System.assertEquals(false,acra.isDeleted);

		// check the e-mail list
		emails = new Set<String>(controller.addToAddresses(new List<String>()));
		System.assert(emails.contains(TEST_EMAILS[0]),'Expecting '+TEST_EMAILS[0]);
		System.assert(emails.contains(TEST_EMAILS[1]),'Expecting '+TEST_EMAILS[1]);
		System.assert(emails.contains(TEST_EMAILS[2]),'Expecting '+TEST_EMAILS[2]);
		System.assert(emails.contains(controller.sender.Email),'Expecting '+controller.sender.Email);
		System.assertEquals(4,emails.size());

		// email tests (deleting)
		ea.email = null;
		// check the e-mail list
		emails = new Set<String>(controller.addToAddresses(new List<String>()));
		System.assert(! emails.contains(TEST_EMAILS[2]),'Not Expecting '+TEST_EMAILS[2]);
		System.assertEquals(3,emails.size());

		// user tests (deleting)
		currentUserAddress.deleteAddress();
		System.assertEquals(true,currentUserAddress.isDeleted);
		System.assertEquals(UserInfo.getUserId(),currentUserAddress.user.Id);
		System.assertEquals(3,controller.addToAddresses(null).size());

		blankUserAddress.deleteAddress();
		System.assertNotEquals(null,blankUserAddress.getLookup());
		System.assertEquals(null,blankUserAddress.user);
		System.assertEquals(true,blankUserAddress.isDeleted);
		emails = new Set<String>(controller.addToAddresses(new List<String>()));
		System.assert(! emails.contains(controller.sender.Email),'Not Expecting '+controller.sender.Email);
		System.assertEquals(2,emails.size());

		currentUserAddress.addAddress();
		emails = new Set<String>(controller.addToAddresses(null));
		System.assert(emails.contains(controller.sender.Email),'Expecting '+controller.sender.Email);
		System.assertEquals(3,emails.size());
		currentUserAddress.deleteAddress();
		emails = new Set<String>(controller.addToAddresses(null));
		System.assert(! emails.contains(controller.sender.Email),'Not Expecting '+controller.sender.Email);
		System.assertEquals(2,emails.size());

		// contact tests (deleting)
		ca.deleteAddress();
		System.assertEquals(true,ca.isDeleted);
		System.assertEquals(1,controller.addToAddresses(null).size());

		// account contact role tests (deleting)
		acra.deleteAddress();
		System.assertEquals(true,acra.isDeleted);
		System.assertEquals(0,controller.addToAddresses(null).size());

		// test resetting the list
		controller.numberOfBlankEmailLines = 0;
		controller.numberOfBlankUserLines = 0;
		controller.userWhereConditions = null;
		controller.contactWhereConditions = null;
		controller.accountContactRoleWhereConditions = null;
		controller.resetToAddresses();
		System.assertEquals(true,controller.isToAddressListEmpty);
		System.assertEquals(true,controller.isToUserAddressListEmpty);
		System.assertEquals(true,controller.isToContactAddressListEmpty);
		System.assertEquals(true,controller.isToAccountContactRoleAddressListEmpty);
		Test.stopTest();
	}

	@isTest
	static void templateSubstituteTest() {
		final String testString='{FileName} {Label} {Name} {SenderName} {SenderName} {Name} {Label} {FileName}';
		final SendPageByEmailController controller = new SendPageByEmailController();
		final String senderName = SendPageByEmailController.getSenderDisplayName(controller.sender);

		Test.startTest();
		controller.pageName='1';
		controller.objectLabel='2';
		controller.displayName='3';
		final String results = controller.templateSubstitute(testString);
		System.assertEquals('1 2 3 '+senderName+' '+senderName+' 3 2 1',results);
		Test.stopTest();
	}

	@isTest
	static void attachmentTest() {
		Test.startTest();
		List<Messaging.EmailFileAttachment> attachments = SendPageByEmailController.addPdfAttachment(null,Blob.valueOf('fudge'),'foo');
		Test.stopTest();
		System.assertEquals(1,attachments.size());
		Messaging.EmailFileAttachment attach = attachments[0];
		System.assertEquals('fudge',attach.getBody().toString());
		System.assertEquals('foo',attach.getFileName());
	}

	@isTest
	static void messageTest() {
		SendPageByEmailController controller = new SendPageByEmailController();
		// test creating a message
		Test.startTest();
		controller.setPlainTextBody('1');
		controller.setSubjectForEmail('2');
		Messaging.SingleEmailMessage message = controller.createMessage();
		Test.stopTest();
		System.assertEquals('1',message.getPlainTextBody());
		System.assertEquals('2',message.getSubject());
	}

	@isTest
	static void sendBlobAsPdfTests() {
		SendPageByEmailController controller = new SendPageByEmailController();

		controller.numberOfBlankEmailLines = 1;
		SendPageByEmailController.Address ea = controller.toAddressList[0];
		ea.email = TEST_EMAILS[2];

		// test creating a message
		controller.setPlainTextBody('1');
		controller.setSubjectForEmail('2');
		controller.pageName = 'foo';
		Test.startTest();
		Messaging.SingleEmailMessage message = controller.sendBlobAsPdf(Blob.valueOf('fudge'));
		System.assertEquals('1',message.getPlainTextBody());
		System.assertEquals('2',message.getSubject());
		List<Messaging.EmailFileAttachment> attachments = message.getFileAttachments();
		System.assertEquals(1,attachments.size());
		Messaging.EmailFileAttachment attach = attachments[0];
		System.assertEquals('fudge',attach.getBody().toString());
		System.assertEquals('foo',attach.getFileName());
		List<String> toAddresses = message.getToAddresses();
		System.assertEquals(1,toAddresses.size());
		System.assertEquals(0,controller.addToAddresses(null).size());

		// the following is strictly for test coverage
		controller.pageUrl='/'+UserInfo.getUserId();
		controller.sendPageAsPdf();
		controller.addMoreToAddresses();
		Test.stopTest();
	}
}