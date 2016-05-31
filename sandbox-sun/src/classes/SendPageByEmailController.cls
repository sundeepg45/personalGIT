/**
 * This is a controller that may be used to send a page
 * as PDF via e-mail.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-21
 * 2013-01-21 - Created
 */
public with sharing class SendPageByEmailController {
	/** The default number of blank lines to add for e-mail and users. */
	public static final Integer NUMBER_TO_ADD = 0;
	/** The default value for the object label string. */
	public static final String OBJECT_LABEL = 'Salesforce Object';
	/** The default body for the e-mail. */
	public static final String PLAIN_TEXT_BODY = 'The {Label} for "{Name}" has been sent to you on behalf of:\n\n{SenderName}\n\n\n';
	/** The default filename for the PDF. */
	public static final String PAGE_NAME = 'CurrentPage.pdf';
	/** The default subject for the e-mail. */
	public static final String SUBJECT_FOR_EMAIL = '{Label} for: {Name}';
	// used to prevent updates to subject and body
	private transient EmailTemplate emailTemplate = null;
	private String subjectForEmail = null;
	private String plainTextBody = null;

	/** 
	 * String of where conditions for AccountContactRole queries.
	 * If null, no AccountContactRoles will be queried.
	 */
	public String accountContactRoleWhereConditions {
		get;
		set {
			accountContactRoleWhereConditions = trim(value,null,null);
		}
	}

	/** A parameter that can be used in queries as ":accountId". */
	public String accountIdForLookup {
		get;
		set {
			value = (Id)trim(value,null,null);
			if(accountIdForLookup != value) {
				accountIdForLookup = value;
				toAccountContactRoleAddressList = null;
			}
		}
	}

	/** 
	 * String of where conditions for Contact queries.
	 * If null, no Contacts will be queried.
	 */
	public String contactWhereConditions {
		get;
		set {
			contactWhereConditions = trim(value,null,null);
		}
		
	}

	/** Normally the name of the object. */
	public String displayName {
		get {
			return trim(displayName,pageName,pageName);
		}
		set;
	}

	/** Normally the object label. */
	public String objectLabel {
		get {
			return trim(objectLabel,OBJECT_LABEL,OBJECT_LABEL);
		}
		set;
	}

	/** Number of blank e-mail lines that should be available. */
	public Integer numberOfBlankEmailLines {
		get {
			if(numberOfBlankEmailLines == null) {
				numberOfBlankEmailLines = NUMBER_TO_ADD;
			}
			return numberOfBlankEmailLines;
		}
		set;
	}

	/** Number of blank User lookup lines that should be available. */
	public Integer numberOfBlankUserLines {
		get {
			if(numberOfBlankUserLines == null) {
				numberOfBlankUserLines = NUMBER_TO_ADD;
			}
			return numberOfBlankUserLines;
		}
		set;
	}

	/** The name of the file attachment. */
	public String pageName {
		get {
			return trim(pageName,PAGE_NAME,PAGE_NAME);
		}
		set;
	}

	/** The url of the page to convert and send. */
	public String pageUrl {
		get;
		set {
			pageUrl = trim(value,null,null);
		}
	}

	/** 
	 * Get the plain text body used for the e-mail.
	 *
	 * @return plainTextBody
	 */
	public String getPlainTextBody() {
		return trim(plainTextBody,PLAIN_TEXT_BODY,PLAIN_TEXT_BODY);
	}

	/** 
	 * Set the plain text body used for the e-mail.
	 *
	 * @param value to assign to plainTextBody
	 */
	public void setPlainTextBody(String value) {
		if(emailTemplate == null) {
			plainTextBody = value;
		}
	}

	/** The current user. */
	public User sender {
		get {
			if(sender == null) {
				sender = [
					select 
						FirstName, 
						LastName, 
						Email
					from User
					where Id = :UserInfo.getUserId()];
			}
			return sender;
		}
		set;
	}

	/** 
	 * Sender First Name followed by Last Name.
	 * 
	 * @param sender user to display name for
	 * @return full name
	 */
	public static String getSenderDisplayName(User sender) {
		return trim(
			trim(sender.FirstName,'','')+' '+trim(sender.LastName,'',''),
			sender.Email,
			sender.Email);
	}

	/** 
	 * Get the subject that will be used for the email.
	 *
	 * @return subjectForEmail
	 */
	public String getSubjectForEmail() {
		return trim(subjectForEmail,SUBJECT_FOR_EMAIL,SUBJECT_FOR_EMAIL);
	}

	/** 
	 * Set the subject that will be used for the email.
	 *
	 * @param value to assign to subjectForEmail
	 */
	public void setSubjectForEmail(String value) {
		if(emailTemplate == null) {
			subjectForEmail = value;
		}
	}

	/**
	 * The Template Unique Name for the template which will
	 * be used for sending the e-mail.  This value overrides subjectForEmail 
	 * and plainTextBody.
	 */
	public String templateDeveloperName {
		get;
		set {
			value = trim(value,null,null);
			if(value != templateDeveloperName) {
				for(EmailTemplate et : [
					select Name, Body, Subject, Description
					from EmailTemplate
					where Folder.Type = 'Email'
						and DeveloperName = :value
						and IsActive = true
					order by LastModifiedDate desc
					limit 1] )
				{
					emailTemplate = et;
					templateDeveloperName = value;
					subjectForEmail = et.Subject;
					plainTextBody = et.Body;
				}
			}
		}
	}

	/** List of AccountContactRoleAddress instances. */
	public List<AccountContactRoleAddress> toAccountContactRoleAddressList {
		get {
			if(toAccountContactRoleAddressList == null) {
				toAccountContactRoleAddressList = new List<AccountContactRoleAddress>();
				if(accountContactRoleWhereConditions != null) {
					final String accountId = accountIdForLookup;
					for(AccountContactRole acr : Database.query(
						'select'
						+'	Contact.Email,'
						+'	Contact.FirstName,'
						+'	Contact.LastName,'
						+'	Contact.HasOptedOutOfEmail,'
						+'	Contact.Name,'
						+'	Contact.Title,'
						+'	IsPrimary,'
						+'	Role '
						+' from AccountContactRole'
						+' where '+accountContactRoleWhereConditions
						+' order by' 
						+'	Contact.LastName,' 
						+'	Contact.FirstName,' 
						+'	Contact.Title,'
						+'	Contact.Name,'
						+'	Contact.Email,'
						+'	Role,'
						+'	IsPrimary') )
					{
						if(acr.Contact != null && acr.Contact.HasOptedOutOfEmail == false) {
							toAccountContactRoleAddressList.add(
								new AccountContactRoleAddress(this,acr) );
						}
					}
				}
			}
			return toAccountContactRoleAddressList;
		}
		set;
	}

	/** Test if the list of AccountContactRoleAddress instances is empty. */
	public Boolean isToAccountContactRoleAddressListEmpty {
		get { return toAccountContactRoleAddressList.isEmpty(); }
	}

	/** List of ContactAddress instances. */
	public List<ContactAddress> toContactAddressList {
		get {
			if(toContactAddressList == null) {
				toContactAddressList = new List<ContactAddress>();
				if(contactWhereConditions != null) {
					final String accountId = accountIdForLookup;
					for(Contact c : Database.query(
						+'select'
						+'	Email,'
						+'	FirstName,'
						+'	HasOptedOutOfEmail,'
						+'	LastName,'
						+'	Name,'
						+'	Title'
						+' from Contact'
						+' where '+contactWhereConditions
						+' order by' 
						+'	LastName,'
						+'	FirstName,'
						+'	Title,'
						+'	Name,'
						+'	Email' ) )
					{
						if(c.HasOptedOutOfEmail == false) {
							toContactAddressList.add(
								new ContactAddress(this,c));
						}
					}
				}
			}
			return toContactAddressList;
		}
		set;
	}

	/** Test if the list of ContactAddress instances is empty. */
	public Boolean isToContactAddressListEmpty {
		get { return toContactAddressList.isEmpty(); }
	}

	/** List of UserAddress instances. */
	public List<UserAddress> toUserAddressList {
		get {
			if(toUserAddressList == null) {
				toUserAddressList = new List<UserAddress>();
				if(userWhereConditions != null) {
					final String accountId = accountIdForLookup;
					for(User u : Database.query(
						+'select'
						+'	Contact.HasOptedOutOfEmail,'
						+'	Email,'
						+'	FirstName,'
						+'	IsActive,'
						+'	LastName'
						+' from User'
						+' where '+userWhereConditions
						+' order by' 
						+'	LastName,'
						+'	FirstName,'
						+'	Email' ) )
					{
						if(u.IsActive == true && (u.Contact == null || u.Contact.HasOptedOutOfEmail == false)) {
							toUserAddressList.add(new UserAddress(this,u));
						}
					}
				}
			}
			Integer n = numberOfBlankUserLines;
			for(Integer i = toUserAddressList.size();i-- > 0;) {
				if(toUserAddressList[i].user == null) {
					n--;
				}
			}
			for(Integer i = n;i-- > 0;) {
				toUserAddressList.add(new UserAddress(this));
			}
			return toUserAddressList;
		}
		set;
	}

	/** Test if the list of UserAddress instances is empty. */
	public Boolean isToUserAddressListEmpty {
		get { return toUserAddressList.isEmpty(); }
	}

	/** List of Address instances. */
	public List<Address> toAddressList {
		get {
			if(toAddressList == null) {
				toAddressList = new List<Address>();
			}
			Integer n = numberOfBlankEmailLines;
			for(Integer i = toAddressList.size();i-- > 0;) {
				if(toAddressList[i].email == null) {
					n--;
				}
			}
			for(Integer i = n;i-- > 0;) {
				toAddressList.add(new Address(this));
			}
			return toAddressList;
		}
		set;
	}

	/** Test if the list of Address instances is empty. */
	public Boolean isToAddressListEmpty {
		get { return toAddressList.isEmpty(); }
	}

	/** 
	 * String of where conditions for User queries.
	 * If null, no User will be queried.
	 */
	public String userWhereConditions {
		get;
		set {
			userWhereConditions = trim(value,null,null);
		}
	}

	/** 
	 * Dummy method called so more empty records can be appended
	 * to the list.
	 *
	 * @return null
	 */
	public PageReference addMoreToAddresses() {
		return null;
	}

	/** 
	 * Dummy method called to reset all the lists to their initial
	 * state.
	 *
	 * @return null
	 */
	public PageReference resetToAddresses() {
		toAddressList = null;
		toUserAddressList = null;
		toContactAddressList = null;
		toAccountContactRoleAddressList = null;
		return null;
	}

	/**
	 * Method to substitute values {FileName}, {Label}, {Name}, 
	 * and {SenderName} into a string.
	 *
	 * @param value to parse
	 * @return value with values substituted
	 */
	public String templateSubstitute(String value) {
		if(value != null) {
			value = value
				.replace('{FileName}',pageName)
				.replace('{Label}',objectLabel)
				.replace('{Name}',displayName)
				.replace('{SenderName}',getSenderDisplayName(sender));
		}
		return value;
	}

	/**
	 * Called to add all the e-mail addresses that are
	 * not marked deleted to a set.
	 *
	 * @param toAddresses set to add to
	 * @return list of e-mail addresses in the set
	 */
	public List<String> addToAddresses(List<String> toAddresses) {
		if(toAddresses == null) {
			toAddresses = new List<String>();
		}
		for(Address ea : toAddressList) {
			System.debug('testing:'+ ea.email);
			if(ea.getIsValid()) {
				toAddresses.add(ea.email);
				System.debug('adding:'+ ea.email);
			}
		}
		for(UserAddress ea : toUserAddressList) {
			if(! ea.isDeleted) {
				toAddresses.add(ea.getEmail());
				System.debug('adding:'+ ea.getEmail());
			}
		}
		for(ContactAddress ea : toContactAddressList) {
			if(! ea.isDeleted) {
				toAddresses.add(ea.getEmail());
				System.debug('adding:'+ ea.getEmail());
			}
		}
		for(AccountContactRoleAddress ea : toAccountContactRoleAddressList) {
			if(! ea.isDeleted) {
				toAddresses.add(ea.getEmail());
				System.debug('adding:'+ ea.getEmail());
			}
		}
		// remove duplicates
		Set<String> toAddressesSet = new Set<String>(toAddresses);
		toAddresses.clear();
		toAddresses.addAll(toAddressesSet);
		return toAddresses;
	}

	/**
	 * Called to convert a page to PDF and add it to a list
	 * of attachments.
	 *
	 * @param attachments list to append to
	 * @param body the blob to attach
	 * @param fileName for the attachment
	 * @return the update list
	 */
	public static List<Messaging.EmailFileAttachment> addPdfAttachment(List<Messaging.EmailFileAttachment> attachments,Blob body,String fileName) {
		if(attachments == null) {
			attachments = new List<Messaging.EmailFileAttachment>();
		}
		Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
		attach.setContentType('application/pdf');
		attach.setFileName(fileName);
		attach.setInline(false);
		attach.Body = body;
		attachments.add(attach);
		return attachments;
	}

	/**
	 * Builds the e-mail message.
	 *
	 * @param emailTemplate plain text template to use
	 * @return e-mail message
	 */
	public Messaging.SingleEmailMessage createMessage() {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSenderDisplayName(getSenderDisplayName(sender));
		mail.setSubject(templateSubstitute(subjectForEmail));
		mail.setUseSignature(true);
		mail.setPlainTextBody(templateSubstitute(plainTextBody));
		mail.setReplyTo(sender.Email);
		return mail;
	}

	/**
	 * Called to send the specified blob as a PDF attachment.
	 *
	 * @param attachmentBody the PDF blob to attach
	 * @return the message sent
	 */
	public Messaging.SingleEmailMessage sendBlobAsPdf(Blob attachmentBody) {
		Messaging.SingleEmailMessage message = createMessage();
		Messaging.SingleEmailMessage [] messages = 
			new Messaging.SingleEmailMessage [] { message };
		message.setToAddresses( addToAddresses( message.getToAddresses() ) );
		message.setFileAttachments( addPdfAttachment( message.getFileAttachments(), attachmentBody, pageName ) );
		Messaging.sendEmail( messages );
		resetToAddresses();
		return message;
	}

	/**
	 * Called to send the current page as a PDF file.
	 *
	 * @return null
	 */
	public PageReference sendPageAsPDF() {
		try {
			PageReference page = new PageReference(pageUrl);
			sendBlobAsPDF(page.getContentAsPDF());
		}
		catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
		return null;
	}

	/**
	 * Simple function to trim a string.
	 *
	 * @param nillValue value to substitute for nill
	 * @param nullValue value to substitute for null
	 */
	public static String trim(String value,String nillValue,String nullValue) {
		if(value != null) {
			value = value.trim();
			if(value == '') {
				value = nillValue;
			}
		}
		else {
			value = nullValue;
		}
		return value;
	}

	/**
	 * Class used for inputing e-mail addresses.
	 */
	public Class Address {
		SendPageByEmailController parent;

		/**
		 * Constructor.
		 *
		 * @param parent
		 */
		Address(SendPageByEmailController parent) {
			this.parent = parent;
		}

		/** Return true if the email contains an @ character. */
		public Boolean getIsValid() {
			return ((''+email).indexOf('@') >= 0);
		}

		/** The E-mail address. */
		public String email {
			get;
			set {
				System.debug('Setting email = '+value);
				email = trim(value,null,null);
			}
		}
	}

	/**
	 * Class used for User lookups and selecting queried users.
	 */
	public Class UserAddress {
		RecordLookup__c lookup;
		SendPageByEmailController parent;

		/**
		 * Constructor for User Lookups.
		 *
		 * @param parent
		 */
		UserAddress(SendPageByEmailController parent) {
			this.parent = parent;
			this.lookup = new RecordLookup__c();
		}

		/**
		 * Constructor queried Users.
		 *
		 * @param parent
		 * @param user
		 */
		UserAddress(SendPageByEmailController parent,User user) {
			this.parent = parent;
			this.user = user;
			this.lookup = null;
		}

		/** True if marked deleted or has a blank e-mail. */
		public Boolean isDeleted {
			get {
				return (getEmail() == null)||(isDeleted != false);
			}
			set;
		}

		/** 
		 * Test if this is a User lookup.
		 *
		 * @return true if a user lookup
		 */
		public Boolean getUseLookup() {
			return (lookup != null);
		}

		/**
		 * Query the record for the User lookup.
		 */
		public RecordLookup__c getLookup() {
			return lookup;
		}

		/** Queried or looked up user record. */
		public User user { 
			get {
				if(lookup != null && lookup.User__c != null && (user == null || user.Id != lookup.User__c)) {
					user = null;
					for(User u : [
						select 
							FirstName,
							LastName,
							Email
						from User
						where Id = :lookup.User__c
							and IsActive = true])
					{
						user = u;
						isDeleted = false;
					}
				}
				return user;
			}
			private set;
		}

		/**
		 * Find out the e-mail address for this record.
		 *
		 * @return e-mail address to send to
		 */
		public String getEmail() {
			String retval = null;
			if(user != null) {
				retval = user.Email;
			}
			return retval;
		}

		/**
		 * Called to set isDelete to false.
		 *
		 * @return null
		 */
		public PageReference addAddress() {
			isDeleted = false;
			return null;
		}

		/**
		 * Called to set isDelete to true and clear the record.
		 *
		 * @return null
		 */
		public PageReference deleteAddress() {
			isDeleted = true;
			if(lookup != null) {
				lookup.User__c = null;
				user = null;
			}
			return null;
		}
	}

	/**
	 * Class used for selecting queried contacts.
	 */
	public Class ContactAddress {
		SendPageByEmailController parent;
		Contact contact;

		/**
		 * Constructor queried Contacts.
		 *
		 * @param parent
		 * @param contact
		 */
		ContactAddress(SendPageByEmailController parent,Contact contact) {
			this.parent = parent;
			this.contact = contact;
		}

		/** True if marked deleted or has a blank e-mail. */
		public Boolean isDeleted {
			get {
				return (isDeleted != false)||(getEmail() == null);
			}
			set;
		}

		/**
		 * The queried Contact record.
		 * 
		 * @return contact
		 */
		public Contact getContact() {
			return contact;
		}

		/**
		 * Find out the e-mail address for this record.
		 *
		 * @return e-mail address to send to
		 */
		public String getEmail() {
			return contact.Email;
		}

		/**
		 * Called to set isDelete to false.
		 *
		 * @return null
		 */
		public PageReference addAddress() {
			isDeleted = false;
			return null;
		}

		/**
		 * Called to set isDelete to true.
		 *
		 * @return null
		 */
		public PageReference deleteAddress() {
			isDeleted = true;
			return null;
		}
	}

	/**
	 * Class used for selecting queried AccountContactRoles.
	 */
	public Class AccountContactRoleAddress {
		SendPageByEmailController parent;
		AccountContactRole accountContactRole;

		/**
		 * Constructor queried AccountContactRols.
		 *
		 * @param parent
		 * @param accountContactRole
		 */
		private AccountContactRoleAddress(SendPageByEmailController parent,AccountContactRole accountContactRole) {
			this.parent = parent;
			this.accountContactRole = accountContactRole;
		}

		/** True if marked deleted or has a blank e-mail. */
		public Boolean isDeleted {
			get {
				return (isDeleted != false)||(getEmail() == null);
			}
			set;
		}


		/**
		 * The queried AccountContactRole record.
		 * 
		 * @return accountcontactrole
		 */
		public AccountContactRole getAccountContactRole() { 
			return accountContactRole;
		}

		/**
		 * Find out the e-mail address for this record.
		 *
		 * @return e-mail address to send to
		 */
		public String getEmail() {
			String retval = null;
			if(accountContactRole.Contact != null) {
				retval = accountContactRole.Contact.Email;
			}
			return retval;
		}

		/**
		 * Called to set isDelete to false.
		 *
		 * @return null
		 */
		public PageReference addAddress() {
			isDeleted = false;
			return null;
		}

		/**
		 * Called to set isDelete to true.
		 *
		 * @return null
		 */
		public PageReference deleteAddress() {
			isDeleted = true;
			return null;
		}
	}
}