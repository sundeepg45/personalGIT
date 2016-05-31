/**
 * This class is intended as a way to limit the selections available for lookup fields
 * that cannot be completely locked for editing.  In particular the initial use of
 * this class it to lock down a field we are copying the the cloned record id to.
 *
 * We cannot block the user from editing the field, as it needs to be editable for
 * the value to be copied in a standard clone.  But we can use a trigger to at least
 * check if the Id value they save matches one they have tried to clone recently.
 * 
 * @version 2013-08-21
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * 2013-08-21 - Added fix for regex parsing of hashes
 * 2013-07-26 - Created
 */
public without sharing class HashIdControllerExtension {
	/** 
	 * Divide the millisecondsGMT of the current time by this value
	 * to define the time value we hash with the record id.
	 */
	public static final Integer TIME_BLOCK = 3600;
	Id recordId;

	/**
	 * Standard controller extension constructor.
	 */
	public HashIdControllerExtension(ApexPages.StandardController stdController) {
		recordId = stdController.getId();
	}

	/**
	 * Lookup the Hashes__c value for the current user.
	 */
	public static Hashes__c hashesForCurrentUser {
		get {
			if(hashesForCurrentUser == null) {
				hashesForCurrentUser = new Hashes__c(OwnerId=UserInfo.getUserId(),RecentCloneHashes__c='');
				for(Hashes__c h : [
					select RecentCloneHashes__c
					from Hashes__c
					where OwnerId = :hashesForCurrentUser.OwnerId
					order by LastModifiedDate desc
					limit 1])
				{
					hashesForCurrentUser = h;
				}
			}
			return hashesForCurrentUser;
		}
		set;
	}

	/**
	 * Calculate the hash of the recordId for the specified date time.
	 *
	 * @param recordId - object id to hash
	 * @param DateTime - the date time to hash for
	 * @return a 24 character MD5 base 64 hash string
	 */
	private static String hashId(Id recordId,DateTime t) {
		String retval = '';
		if(recordId != null) {
			String sessionId = UserInfo.getSessionId();
			Integer hours = t.millisecondGmt()/(1000*TIME_BLOCK);
			retval = EncodingUtil.base64Encode(Crypto.generateDigest('MD5',Blob.valueOf(recordId+''+hours))).replaceAll('\\+','_');
			System.debug('hashId='+retval+' from Id='+recordId+' and hours='+hours);
		}
		return retval;
	}

	/**
	 * Returns true if the page has the parameter for a standard clone.
	 *
	 * @return true if clone with a record type
	 */
	public Boolean isClone {
		get {
			if(isClone == null) {
				isClone = (ApexPages.currentPage().getParameters().get('clone') == '1');
			}
			return isClone;
		}
		set;
	}
	
	/**
	 * Returns true if the page has the parameter for a standard clone without a record type.
	 *
	 * @return true if clone without a record type
	 */
	public Boolean isCloneWithoutRecordType {
		get {
			if(isCloneWithoutRecordType == null) {
				isCloneWithoutRecordType = (ApexPages.currentPage().getParameters().get('clonewort') == '1');
			}
			return isCloneWithoutRecordType;
		}
		set;
	}

	/**
	 * Finds out if this Id has been hashed in the current or previous time
	 * block.
	 *
	 * @return true if there is a clone hash within the current or previous timeblock.
	 */
	public static Boolean hasHashForId(Id recordId) {
		Boolean retval = null;
		if(hashesForCurrentUser.RecentCloneHashes__c != null) {
			DateTime t = DateTime.now();
			String hash1 = hashId(recordId,t);
			String hash2 = hashId(recordId,t.addSeconds(-TIME_BLOCK));
			retval = (hashesForCurrentUser.RecentCloneHashes__c.indexOf(hash1) >= 0)
				|| (hashesForCurrentUser.RecentCloneHashes__c.indexOf(hash2) >= 0);
		}
		return retval;
	}

	/**
	 * Store an md5 hash of the recordId with the current session Id.  This allows us to
	 * check clone from fields in triggers to find out if at least they are an id value we are
	 * currently cloning.
	 * 
	 * @return null
	 */
	public PageReference hashIdIfClone() {
		try {
			DateTime t = DateTime.now();
			if(isClone || isCloneWithoutRecordType) {
				// ignore portal users
				User u = [select IsPortalEnabled from User where Id = :UserInfo.getUserId()];
				if(! u.IsPortalEnabled) {
					String base64Hash = hashesForCurrentUser.RecentCloneHashes__c;
					if(base64Hash == null) {
						base64Hash = '';
					}
					String hash1 = hashId(recordId,t);
					String hash2 = hashId(recordId,t.addSeconds(-TIME_BLOCK));
					base64Hash = hash1 + base64Hash.replaceAll(hash1,'').replaceAll(hash2,'');
					if(base64Hash.length() > 240) {
						base64Hash = base64Hash.substring(0,240);
					}
					hashesForCurrentUser.RecentCloneHashes__c = base64Hash;
					System.debug(base64Hash);
					upsert hashesForCurrentUser;
				}
			}
		}
		// This is not critical functionality, so we will ignore exceptions.
		catch(Exception ex) {}
		return null;
	}
}