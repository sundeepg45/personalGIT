public without sharing class PP_ContactReassignment {

	static public void reassignContacts() {
	    Set<String> contactIdList = new Set<String>();
	    Set<String> accountIdList = new Set<String>();
	    Contact[] contactList = (Contact[]) Trigger.new;
	    Map<ID,Contact> newMap = (Map<ID,Contact>) Trigger.newMap;
	    for (Contact c : contactList) {
	    	Contact old = (Contact) Trigger.oldMap.get(c.Id);
	        if (c.AccountId != null && c.AccountId != old.AccountId) {
	            contactIdList.add(c.Id);
	            accountIdList.add(c.AccountId);
	        }
	    }
	    Map<ID,Account> partnermap = new Map<ID,Account>([select Id from Account where Id in :accountIdList and IsPartner = true]);
	
	    if (!partnermap.isEmpty()) {
	    	Set<ID> keyset = partnermap.keySet();
	        //String soql = PartnerUtil.getWritableFieldsSOQL('PP_Scores__c', 'Contact__c in :contactIdList and Account__c in :keyset');
	        //System.debug('++++[debug]++++ soql=' + soql);
	        //PP_Scores__c[] scores = (PP_Scores__c[]) Database.query(soql);
	        PP_Scores__c[] scores = [
	        	select	Account__c,
	        			BatchItemStageRef__c,
	        			Category__c,
	        			Contact__c,
	        			ContentRef__c,
	        			Expiring_Soon__c,
	        			From_ID__c,
	        			LMS_Ref__c,
	        			Points__c,
	        			Points_Status__c,
	        			Subcategory__c //,
	        			//When_Earned__c
	        	from	PP_Scores__c
	        	where	Contact__c in :contactIdList
//	        	and		Account__c in :keyset
	        ];
	
	        PP_Scores__c[] newscores = new List<PP_Scores__c>();
	
	        for (PP_Scores__c up : scores) {
	        	
	        	PP_Scores__c ns = new PP_Scores__c();
	        	ns.BatchItemStageRef__c = up.BatchItemStageref__c;
	        	ns.Category__c = up.Category__c;
	        	ns.Contact__c = up.Contact__c;
	        	ns.ContentRef__c = up.ContentRef__c;
	        	ns.Expiring_Soon__c = up.Expiring_Soon__c;
	        	ns.From_ID__c = up.From_ID__c;
	        	ns.LMS_Ref__c = up.LMS_Ref__c;
	        	ns.Points__c = up.Points__c;
	        	ns.Points_Status__c = up.Points_Status__c;
	        	ns.Subcategory__c = up.Subcategory__c;
	        	//ns.When_Earned__c = up.When_Earned__c; 	        	
	            ns.Account__c = newMap.get(up.Contact__c).AccountId;
	            newscores.add(ns);
	            System.debug('++++[debug]++++ inserting ' + ns.Points__c);
	        }
	        if (!newscores.isEmpty()) {
	            delete scores;
	            delete [select Id from PP_User_Points__c where Contact__c in :contactIdList];
	            insert newscores;
	        }
	
	    }
	}
}