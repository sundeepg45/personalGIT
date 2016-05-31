/**
 * This is used by the UserRecordAccessFilter component to filter
 * parts of a visual force page based on what access a user has to
 * records.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-09-19
 * 2012-09-19 - created
 */
public with sharing class UserRecordAccessController {
	public Id recordId { get; set; }

	/**
	 * Query the UserRecordAccess for the current user.
	 */
	public UserRecordAccess userRecordAccess {
		get {
			if(userRecordAccess == null || userRecordAccess.RecordId != recordId) {
				userRecordAccess = [
					select
						HasAllAccess,
						HasDeleteAccess,
						HasEditAccess,
						HasTransferAccess,
						HasReadAccess,
						MaxAccessLevel,
						RecordId
					from UserRecordAccess
					where RecordId = :recordId
						and UserId = :UserInfo.getUserId() ];
			}
			return userRecordAccess;
		}
		private set;
	}

	/**
	 * All access is required if true.
	 */
	public Boolean requireAllAccess {
		get {
			return (requireAllAccess == true);
		}
		set;
	}

	/**
	 * Delete access is required if true.
	 */
	public Boolean requireDeleteAccess {
		get {
			return (requireDeleteAccess == true);
		}
		set;
	}

	/**
	 * Edit access is required if true.
	 */
	public Boolean requireEditAccess {
		get {
			return (requireEditAccess == true);
		}
		set;
	}

	/**
	 * Transfer access is required if true.
	 */
	public Boolean requireTransferAccess {
		get {
			return (requireTransferAccess == true);
		}
		set;
	}

	/**
	 * Read access is required if true.
	 */
	public Boolean requireReadAccess {
		get {
			return (requireReadAccess == true);
		}
		set;
	}

	/**
	 * Assign a value of false to invert the access 
	 * requirements.
	 */
	public Boolean requireAccess {
		get {
			return (requireAccess != false);
		}
		set;
	}

	/**
	 * Check access.
	 *
	 * @return True if the user has all the required access.
	 */
	public Boolean getHasAccess() {
		UserRecordAccess ura = userRecordAccess;
		return (ura.HasAllAccess || !requireAllAccess)
			&& (ura.HasDeleteAccess || !requireDeleteAccess)
			&& (ura.HasEditAccess || !requireEditAccess)
			&& (ura.HasTransferAccess || !requireTransferAccess)
			&& (ura.HasReadAccess || !requireReadAccess);
	}

	/**
	 * Check if we should show the component body.
	 *
	 * @return True if getHasAccess() is equal to requireAccess
	 */
	public Boolean getShowBody() {
		return (getHasAccess() == requireAccess);
	}
}