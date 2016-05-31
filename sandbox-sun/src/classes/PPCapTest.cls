@isTest
private class PPCapTest {
/*
	static testMethod void testContactAssociation() {
    	Contact con = [select Id, AccountId from Contact where Account.IsPartner = true and Account.Global_Region__c = 'NA' limit 1];
    	Account acct = [select Id, Global_Region__c, Finder_Partner_Type__c, Finder_Partner_Tier__c from Account where Id = :con.AccountId];
    	Account acct2 = [select Id, Global_Region__c, Finder_Partner_Type__c, Finder_Partner_Tier__c from Account where Id != :con.AccountId and IsPartner = true and Global_Region__c = 'NA' limit 1];

		delete [select Id from PP_Scores__c where Contact__c = :con.Id];

		PP_Scores__c score = new PP_Scores__c(Contact__c = con.Id, Account__c = acct.Id);
		score.When_Earned__c = System.now().date();
		score.From_ID__c = 'justATest';
		score.Points__c = 5;
		insert score;

		score = new PP_Scores__c(Contact__c = con.Id, Account__c = acct.Id);
		score.When_Earned__c = System.now().date();
		score.From_ID__c = 'justATest2';
		score.Points__c = 2;
		insert score;

		System.debug('++++[debug]++++ old acctid=' + con.AccountId);
 		con.Account = acct2;
 		con.AccountId = acct2.Id;
		update con;

		//con = [select Id, AccountId from Contact where Id = :con.Id];
		//System.debug('++++[debug]++++ new acctid=' + con.AccountId);

		//System.assert(con.AccountId == acct2.Id, 'contact was not reassigned');
		//PP_User_Points__c points = [select Id, Account__c, Current_Points__c, Uncapped_Points__c, IsActive__c from PP_User_Points__c where Contact__c = :con.Id];
		//System.assert(points.Account__c == acct2.Id, 'expected contact to be assigned to new account');
		//System.assert(points.Current_Points__c == 7, 'expected points to be 7, got ' + points.Current_Points__c);
	}

	static testMethod void testContactDelete() {

    	Contact con = [select Id, AccountId from Contact where Account.IsPartner = true and Account.Global_Region__c = 'NA' and LoginName__c = null limit 1];
    	Account acct = [select Id, Global_Region__c, Finder_Partner_Type__c, Finder_Partner_Tier__c from Account where Id = :con.AccountId];

		PP_Cap__c cap = null;
		PP_Cap__c[] caps = [
			select	Id, Cap_Points__c
			from	PP_Cap__c
			where	Global_Region__c = :acct.Global_Region__c
			and		Partner_Type__c = :acct.Finder_Partner_Type__c
			and		Partner_Tier__c = :acct.Finder_Partner_Tier__c
		];
		if (caps.size() > 0) {
			cap = caps.get(0);
			cap.Cap_Points__c = 100000;
			update cap;
		}
		else {
			cap = new PP_Cap__c();
			cap.Global_Region__c = acct.Global_Region__c;
			cap.Partner_Type__c = acct.Finder_Partner_Type__c;
			cap.Partner_Tier__c = acct.Finder_Partner_Tier__c;
			cap.Cap_Points__c = 100000;
			insert cap;
		}

		delete [select Id from PP_Scores__c where Account__c = :acct.Id];
		PP_Scores__c score = new PP_Scores__c(Contact__c = con.Id, Account__c = acct.Id);
		score.When_Earned__c = System.now().date();
		score.From_ID__c = 'justATest';
		score.Points__c = 5;
		
		insert score;

		PP_User_Points__c[] points = [select Id, Current_Points__c, Uncapped_Points__c from PP_User_Points__c where Contact__c = :con.Id];
		PP_Account_Points__c apoints = [select Id, Current_Points__c from PP_Account_Points__c where Account__c = :acct.Id];
		System.assert(points.size() > 0, 'no points found');
		delete con;
		points = [select Id, Current_Points__c, Uncapped_Points__c from PP_User_Points__c where Contact__c = :con.Id];
		System.assert(points.size() == 0, 'Expected points to be removed');

		PP_Account_Points__c apointsAfter = [select Id, Current_Points__c from PP_Account_Points__c where Account__c = :acct.Id];
		System.assert(apointsAfter.Current_Points__c < apoints.Current_Points__c, 'account points not recalculated: found ' + apoints.Current_Points__c + ', expected ' + apointsAfter.Current_Points__c);
		
		undelete con;
		apointsAfter = [select Id, Current_Points__c from PP_Account_Points__c where Account__c = :acct.Id];
		System.assert(apointsAfter.Current_Points__c == apoints.Current_Points__c, 'account points not undeleted');		
	}

    static testMethod void testUserDeactivate() {

		Test.startTest();
    	User user = [select Id, IsActive, ContactId from User where ContactId != null and Contact.Account.isPartner = true and Contact.Account.Global_Region__c = 'NA' and isActive = true limit 1];
    	Contact con = [select Id, AccountId from Contact where Account.IsPartner = true and Account.Global_Region__c = 'NA' and Id = :user.ContactId];
    	Account acct = [select Id, Global_Region__c, Finder_Partner_Type__c, Finder_Partner_Tier__c from Account where Id = :con.AccountId];

		delete [select Id from PP_Scores__c where Contact__c = :con.Id];
		PP_Scores__c score = new PP_Scores__c(Contact__c = con.Id, Account__c = acct.Id);
		score.When_Earned__c = System.now().date();
		score.From_ID__c = 'justATest';
		score.Points__c = 5;
		
		insert score;

		//User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
		//System.runAs(thisUser) {
		//	user.IsActive = false;
		//	update user;
		//}
		//Test.stopTest();
		//PP_User_Points__c points = [select Id, Current_Points__c, Uncapped_Points__c, IsActive__c from PP_User_Points__c where Contact__c = :con.Id];
		//System.assert(points.IsActive__c == false, 'expected user to be inactive');
    }

    static testMethod void testCaps() {

		Contact c = new Contact();

		Account acct = [select Id, Global_Region__c, Finder_Partner_Type__c, Finder_Partner_Tier__c from Account where isPartner = true and Global_Region__c = 'NA' and Is_Partner_Published__c = true limit 1];		
		Contact con = PartnerTestUtils.makeContact(acct.Id, 'slartibartfast');
		insert con;

		PP_Cap__c cap = null;
		PP_Cap__c[] caps = [
			select	Id, Cap_Points__c
			from	PP_Cap__c
			where	Global_Region__c = :acct.Global_Region__c
			and		Partner_Type__c = :acct.Finder_Partner_Type__c
			and		Partner_Tier__c = :acct.Finder_Partner_Tier__c
		];
		if (caps.size() > 0) {
			cap = caps.get(0);
			cap.Cap_Points__c = 20;
			update cap;
		}
		else {
			cap = new PP_Cap__c();
			cap.Global_Region__c = acct.Global_Region__c;
			cap.Partner_Type__c = acct.Finder_Partner_Type__c;
			cap.Partner_Tier__c = acct.Finder_Partner_Tier__c;
			cap.Cap_Points__c = 20;
			insert cap;
		}

		PP_Scores__c score = new PP_Scores__c(Contact__c = con.Id, Account__c = acct.Id);
		score.When_Earned__c = System.now().date();
		score.From_ID__c = 'justATest';
		score.Points__c = 5;
		insert score;
		
		// trigger should have now recorded a new row and score total for contact
		PP_User_Points__c points = [select Id, Current_Points__c, Uncapped_Points__c from PP_User_Points__c where Contact__c = :con.Id];
		
		System.assert(points.Current_Points__c == 5, 'Current point mismatch, got ' + points.Current_Points__c);
		System.assert(points.Uncapped_Points__c == 5, 'Uncapped point mismatch');

		// record a new score to bump over the cap		
		score = new PP_Scores__c(Contact__c = con.Id, Account__c = acct.Id);
		score.When_Earned__c = System.now().date();
		score.From_ID__c = 'justATest2';
		score.Points__c = 50;
		insert score;
		
		// trigger now has updated the user_points record
		points = [select Id, Current_Points__c, Uncapped_Points__c from PP_User_Points__c where Contact__c = :con.Id];
		System.assert(points.Current_Points__c == 20, 'Current points not capped, currently ' + points.Current_Points__c);
		System.assert(points.Uncapped_Points__c == 55, 'Uncapped points incorrect');
		
    }
*/
}