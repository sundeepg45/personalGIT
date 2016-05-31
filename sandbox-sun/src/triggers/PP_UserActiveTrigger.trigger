trigger PP_UserActiveTrigger on User (after insert, after update) {

	if (Trigger.isInsert) {
		// onboarding lead conversion is already a @future method, so we can't call our @future method

		if (!System.isFuture()) {
			//
			// Inserting a new User - could be associating to an existing Points contact.
			//
			Map<String, Boolean> contactIdMap = new Map<String, Boolean>();
			for (User u : Trigger.new) {
				System.debug('+++++[debug]+++++ inserted user status is ' + u.IsActive);
				if (u.ContactId != null) {
					contactIdMap.put(u.ContactId, u.IsActive);
				}
			}
			PPScoringUtil.handleUserInserts(contactIdMap);
		}
	}
	else {
		//
		// Handle 4 scenarios: activated user, deactivated user, disabled user, contact associated to user
		//
		Map<String, Boolean> contactIdMap = new Map<String, Boolean>();
		for (User u : Trigger.new) {
			System.debug('++++[debug]++++ user is ' + u.Id);
			User old = Trigger.oldMap.get(u.Id);

			if (u.IsPortalEnabled != old.IsPortalEnabled) {
				// status changed
				contactIdMap.put(u.ContactId, u.IsPortalEnabled);
			}
			else
			if (u.ContactId == old.ContactId && u.IsActive != old.IsActive) {
				// status changed
				contactIdMap.put(u.ContactId, u.IsActive);
			}
			else if (u.ContactId != old.ContactId && u.ContactId == null) {
				// contact linkage to user broken
				contactIdMap.put(old.ContactId, false);
			}
			else if (u.ContactId != old.ContactId && u.ContactId != null) {
				// contact gets associated to a user
				contactIdMap.put(u.ContactId, true);
			}
		}
		
		PPScoringUtil.handleUserUpdates(contactIdMap);
	}


}