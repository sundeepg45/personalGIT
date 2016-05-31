/**
* This class defines the logic for  inserts/updates operation into EBS_Account object
* 
* @version 2015-08-27
* @author Neha Jaiswal <nejaiswal@DELOITTE.com>
* 2015-04-10 - Added start and end dates
* 2014-03-10 - initial version
* Bill C Riemers <briemers@redhat.com>
* 2015-08-27 - Added MasterRecord__r.Status__c to address query
* 2015-05-05 - Avoid breaking this further by resolving the too many DML operations error
* 2015-05-04 - Updated to add program names to the CDH_Party_c.
* Scott Coleman <scoleman@redhat.com>
* 2015-08-13 - Suppressing publishing of test records per US71693
*/
public class PartnerProgram_Trigger_Handler{

	//Static variable to check the status
	public final static String ACTIVE_STATUS = 'Active';
	public final static String APPROVE_STATUS = 'Approved';
	public final static String INACTIVE_STATUS = 'Inactive';

	////map of partner program tier to hold the values of it's record.
	Map<String,Partner_Program_Tier__c> mapOfProgramTier = new Map<String,Partner_Program_Tier__c>();

	//map to hold old record values before update.
	Map<Id,Partner_Program__c> oldpartnerprogram = new Map<Id,Partner_Program__c>();

	//map to hold new record values after update.
	Map<Id,Partner_Program__c> newpartnerprogram = new Map<Id,Partner_Program__c>();

	//map to hold delete record values of the partner program.
	Map<Id,Partner_Program__c> deletdPartnerprogram = new Map<Id,Partner_Program__c>();

	//Boolean to check if the record is inserted or updated.
	Boolean invokeoutbound;

	/**
	*This method will be invoked before when a partner program is created/updated for a partner account.It will assign the value of matched oracle classification code in the oracle classification code custom field of partner program.
	*oracle classification code in definition objects gets assigned to oracle classification code field of partner program.
	*@param : value assigned to the oracle classification code of partner program.
	*@return :
	*/
	public void AssignPartnerDetailsToIntegrationObject(list<partner_program__c> oldpartnerProgramInserted , list<partner_program__c> newPartnerProgramInserted){

		//calling this method to set the map of tier object values.
		getMapOfPartnerProgramAndTier();

		//iterating through all the inserted/updated partner program and assigning the oracle classification field value.
		for(partner_program__c partnerProgramClassifiacationCodeAssignment : newPartnerProgramInserted){
			if(mapOfProgramTier.get(partnerProgramClassifiacationCodeAssignment.program__c+  		partnerProgramClassifiacationCodeAssignment.tier__c) != null ){

				Partner_Program_Tier__c matchedPartnerProgramTier = mapOfProgramTier.get(partnerProgramClassifiacationCodeAssignment.program__c+partnerProgramClassifiacationCodeAssignment.tier__c);

				partnerProgramClassifiacationCodeAssignment.oracle_classification_code__c = matchedPartnerProgramTier.Oracle_Classification_Code__c;
			}
		}
	}

	/**
	*This is the method invoked by trigger on partner when the partner program is created and sent to outbound CDH
	*@param : new created partner program for an account
	*@return : List of partner program updated based on conditions.
	*/
	public  void AfterInsert(map<Id,Partner_Program__c> mapOfPartnerProgram){

		//assigning map of inserted partner programs to a map initialized.
		newpartnerprogram  = mapOfPartnerProgram;

		/*invoking a method to get the tier's oracle classification code based on definition's look up and tier picklist values
		selecting for creating a partner program.*/
		getMapOfPartnerProgramAndTier();

		//set of account to add account for which partner program has been inserted.
		Set<Id> accountIdSet = new Set<Id>();

		//forming set of account for which partner program inserted.
		for(Partner_Program__c partnerprogram :newpartnerprogram.values() ){
			accountIdSet.add(partnerprogram.Account__c);
		}

		//invoking method to invoke outbound service.
		invokeOutboundService(accountIdSet , true, false);
	}

	/**
	*This is the method invoked by trigger on partner when the partner program is deleted and sent to outbound CDH
	*@param : new created partner program for an account
	*@return : List of partner program updated based on conditions.
	*/
	public  void AfterDelete(map<Id,Partner_Program__c> mapOfPartnerProgramDeleted){

		//assigning map of inserted partner programs to a map initialized.
		deletdPartnerprogram  = mapOfPartnerProgramDeleted;

		/*invoking a method to get the tier's oracle classification code based on definition's look up and tier picklist values
		selecting for creating a partner program.*/
		getMapOfPartnerProgramAndTier();

		//set of account to add account for which partner program has been inserted.
		Set<Id> accountIdSet = new Set<Id>();

		//forming set of account for which partner program inserted.
		for(Partner_Program__c partnerprogram :deletdPartnerprogram.values() ){
			accountIdSet.add(partnerprogram.Account__c);
		}

		//invoking method to invoke outbound service.
		invokeOutboundService(accountIdSet , false, true);
	}

	/**
	*This method will be invoked when a partner program is updated for a partner account.So either if status of the partner program or
	*oracle classification code in definition objects gets edit, the CDH outbound message will be send.
	*@param : old and new record details of the updated partner program
	*@return : List of partner program updated based on conditions.
	*/
	public void AfterUpdate(map<Id,Partner_Program__c> newmap , map<Id,Partner_Program__c> oldmap){

		//assigning the oldMap of the records of the partnerProgram updated to a map initialized.
		oldpartnerprogram = oldmap;

		//assigning the newMap of the records of the partnerProgram updated to a map initialized.
		newpartnerprogram = newmap;

		/*invoking a method to get the tier's oracle classification code based on definition's look up and tier picklist values
		selecting for creating a partner program.*/
		getMapOfPartnerProgramAndTier();

		//forming set of account for which partner program inserted.
		Set<Id> accountIdSet = new Set<Id>();

		//forming set of account for which partner program inserted.
		for(Partner_Program__c partnerprogram :newpartnerprogram.values() ){
			accountIdSet.add(partnerprogram.Account__c);
		}

		//invoking method to invoke outbound service.
		invokeOutboundService(accountIdSet , false, false);
	}

	/**
	 * This method will be invoked when a new partner program is inserted or updated, and results in the 
	 * outbound service for CDH to be invoked.  The relevent CDH_Party__c objects will also be updated with
	 * the names of active primary eligible partner program members.
	 * 
	 * @param accountIdSet sot of the updated/Created partner program whose status is changes as 'Active' or vice versa.
	 * @param insertevent true if insert
	 * @param deleteevent true if delete
	 */
	public void invokeOutboundService(Set<Id> accountIdSet, Boolean insertevent, Boolean deleteevent){

		// Retrieve all of the active partner programs for all the accounts passed in
		Set<String> cdhPartyNumbers = new Set<String>();
		if(! accountIdSet.isEmpty()) {
			for (AggregateResult ar : [
				SELECT Name 
				FROM CDH_Party__c WHERE Id in (select CDH_Party_Name__c from Account where Id in :accountIdSet)
				GROUP BY Name ] )
			{
				cdhPartyNumbers.add(String.valueOf(ar.get('Name')));
			}
		}
		if (cdhPartyNumbers.isEmpty()) {
			return;
		}

		Map<Id,Account> accountMap = new Map<Id,Account>([
			select
				All_NAICS_Codes__c,
				AnnualRevenue,
				CDH_Party_Name__c,
				CDH_Party_Name__r.Name,
				CDH_Party_Name__r.PartnerPrograms__c,
				CDHPartyNumber__c,
				CDH_Party_Type__c,
				Count_Of_Identifying_Address__c,
				Domestic_Ultimate__c,
				Do_Not_Do_Business_with__c,
				DunsNumber,
				D_U_N_S__c,
				Fax,
				Global_Ultimate__c,
				Headquarters__c,
				Headquarters_CDH_Party_Number__c,
				Linkedin_URL__c,
				Name,
				NumberOfEmployees,
				Phone,
				RecordType.Name,
				Sic,
				SicDesc,
				SEA_Concern__c,
				Status__c,
				Tradestyle,
				VATNumber__c,
				Website,
				YearStarted,
				Zip_Postal_Code__c,
				Do_Not_Publish_To_Bus__c,
				(	select
						Active__c,
						CreatedDate,
						Id,
						Is_Primary__c,
						Name,
						Oracle_Classification_Code__c,
						Program__c,
						Program__r.Name,
						Program__r.Oracle_Classification_Code__c,
						Account__r.CDHPartyNumber__c,
						Program__r.Program_Category__c,
						Program__r.Partner_Type__c,
						Status__c,
						Tier__c
					From Partner_Programs__r
					where Program__r.Is_Primary_Eligible__c = true ),
				(	select
						Address_Line1__c,
						Address_Line2__c,
						Address_Line3__c,
						Address_Line4__c,
						Bill_To_Address__c,
						CDH_Party__c,
						CDH_Party_Site_Number__c,
						City__c,
						Country__c,
						County__c,
						Entitle_To_Address__c,
						Identifying_Address__c,
						Name,
						Province__c,
						Sales_Account__c,
						Ship_To_Address__c,
						Sold_To_Address__c,
						State__c,
						MasterRecord__r.Status__c,
						Status__c,
						Zip_Postal_Code__c
					from Addresses__r
					where Sales_Account__r.RecordType.Name not in ('NA Partner', 'EMEA Partner', 'APAC Partner', 'LATAM Partner') )
				from Account
				where CDH_Party_Name__r.Name in :cdhPartyNumbers
			]);

		// Build a map to lookup all of the programs for a given CDH Party Number
		Map<String,List<Partner_Program__c>> cdhNumberPartnerProgramMap = new Map<String,List<Partner_Program__c>>();
		// map of all relevant cdh parties
		Map<Id,CDH_Party__c> cdhPartyMap = new Map<Id,CDH_Party__c>();
		// map of the relevant party program names for each cdh party
		Map<Id,Set<String>> cdhPartyNamesMap = new Map<Id,Set<String>>();

		// populate the maps
		for(Account a : accountMap.values()) {
			String cdhPartyNumber = a.CDH_Party_Name__r.Name;
			List<Partner_Program__c> ppl = cdhNumberPartnerProgramMap.get(cdhPartyNumber);
			if (ppl == null){
				ppl = new List<Partner_Program__c>();
				cdhNumberPartnerProgramMap.put(cdhPartyNumber, ppl);
			}
			if(a.Partner_Programs__r != null) {
				for (Partner_Program__c ppMember : a.Partner_Programs__r) {
					System.debug('Adding ' + ppMember.Program__r.Program_Category__c + '-' + ppMember.Tier__c + ' for CDH Party # ' + cdhPartyNumber);
				}
				ppl.addAll(a.Partner_Programs__r);
				for(Partner_Program__c pp : a.Partner_Programs__r) {
					if( pp.Program__r != null 
						&& pp.Active__c 
						&& ! (deleteEvent && deletdPartnerprogram.containsKey(pp.Id)) )
					{
						Set<String> names = cdhPartyNamesMap.get(a.CDH_Party_Name__c);
						if(names == null) {
							names = new Set<String>();
							cdhPartyNamesMap.put(a.CDH_Party_Name__c,names);
						}
						List<String> types = new List<String>{''};
						if(pp.Program__r.Partner_Type__c != null) {
							types = pp.Program__r.Partner_Type__c.split(';');
						}
						for(String t : types) {
							String name = t + '-'+pp.Tier__c;
							if(pp.Is_Primary__c == true) {
								name += '*';
							}
							names.add(name);
						}
					}
				}
			}
			cdhPartyMap.put(a.CDH_Party_Name__c,a.CDH_Party_Name__r);
		}

		// create a list of all cdh parties that need updating
		List<CDH_Party__c> updateCDHParties = new List<CDH_Party__c>();
		for(Id id : cdhPartyMap.keySet()) {
			CDH_Party__c party = cdhPartyMap.get(id);
			String partnerPrograms = null;
			// concat the names into a single string
			List<String> names = new List<String>(cdhPartyNamesMap.get(id));
			if(names != null) {
				names.sort();
				partnerPrograms = '';
				String sep = '';
				Boolean tooMany = false;
				for(String name : names) {
					String s = partnerPrograms + sep + name;
					Boolean tooLong = (s.length() > 251); 
					if(! tooLong) {
						partnerPrograms = s;
						sep = '\n';
					}
					tooMany = (tooMany || tooLong);
				}
				if(tooMany) {
					partnerPrograms += sep + '...';
				}
			}
			if(party.PartnerPrograms__c != partnerPrograms) {
				party.PartnerPrograms__c = partnerPrograms;
				updateCDHParties.add(party);
			}
		}

		// update the cdh parties
		if(! updateCDHParties.isEmpty()) {
			// throw errors...
			Database.update(updateCDHParties,true);
		}

		List<IntegrationObjects.SalesAccount> ioAccountUpdates = new List<IntegrationObjects.SalesAccount>();
		for(Account account : accountMap.values() ) {
			if(account.Count_Of_Identifying_Address__c > 0 && ! account.Addresses__r.isEmpty()) {
				// US71693
				OutboundService.DoNotPublish = (OutboundService.DoNotPublish || account.Do_Not_Publish_To_Bus__c);

				//invoking method from integration object to call the structure of account cdh outbound.
				IntegrationObjects.SalesAccount ioAccount = new IntegrationObjects.SalesAccount();

				//list of classification of partner program to be send in CDH outbound.
				List<IntegrationObjects.classification> ioclassificationList = new List<IntegrationObjects.classification>();

				// Get the partner programs for this account from the map
				List<Partner_Program__c> programList = cdhNumberPartnerProgramMap.get(account.CDH_Party_Name__r.Name);
				System.debug('We have ' + programList.size() + ' partner program memberships for CDH Party # ' + account.CDH_Party_Name__r.Name);


				//iterating through the account's partner program to sent in cdh outbound.
				for(Partner_Program__c partnerProgram : programList){

					//getting the value of tier's record according to the combination of tier & definition look up.
					System.debug('Partner Program: ' + partnerProgram.Id + ' Name: ' + partnerProgram.Name);
					System.debug('Program Tier map: ' + mapOfProgramTier);
					Partner_Program_Tier__c  programTier = mapOfProgramTier.get(partnerProgram.Program__c+partnerProgram.Tier__c);

					/*checking if a partner program is getting inserted.Performing checks on partner tier and oracle classification code if not null.*/

					//CDH will not get flow if the inserted record is Active or Approved.
					if(insertevent == true &&
						(partnerProgram.Status__c == ACTIVE_STATUS ||
							partnerProgram .Status__c== APPROVE_STATUS) &&
							programTier !=Null &&
							programTier.Oracle_Classification_Code__c!=Null)
					{
						System.debug('IN INSERT!!!! ' + partnerProgram.Program__r.Program_Category__c + partnerProgram.Tier__c + partnerProgram.Status__c);


						//adding in a list of classification
						IntegrationObjects.classification classification = new IntegrationObjects.classification();
						classification.Status = ACTIVE_STATUS ;
						classification.Code = programTier.Oracle_Classification_Code__c;
						classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
						classification.EndDate = null;
						ioclassificationList.add(classification);
						if(newpartnerprogram.containskey(partnerProgram.id)) {
							invokeoutbound = true;
						}

						// add classification for the partner type
						classification = new IntegrationObjects.Classification();
						classification.Status = ACTIVE_STATUS;
						classification.Code = partnerProgram.Program__r.Oracle_Classification_Code__c;
						classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
						classification.EndDate = null;
						ioclassificationList.add(classification);
					}

					/*checking if a partner program is getting updating.Performing checks on partner tier and oracle classification code if not null.*/

					//CDH will not get flow if the updated record is Active or Approved.

					else if(insertevent == false &&
						deleteevent == false &&
						!oldpartnerprogram.containsKey(partnerProgram.Id) &&
						 (partnerProgram.Status__c == ACTIVE_STATUS ||
						 partnerProgram .Status__c== APPROVE_STATUS) &&
						(programTier!=null &&  programTier.Oracle_Classification_Code__c!=Null))
					{
						System.debug('IN UPDATE 1!!!! ' + partnerProgram.Program__r.Program_Category__c + partnerProgram.Tier__c + partnerProgram.Status__c);


						if ((trigger.isdelete == false  ) ||
							(trigger.isdelete && deletdPartnerprogram != null && deletdPartnerprogram.keyset().isempty() == false &&
							deletdPartnerprogram.containskey(partnerProgram.id) == false))
						{

							 //adding in a list of classification
							IntegrationObjects.classification classification = new IntegrationObjects.classification();
							classification.Status = ACTIVE_STATUS;
							classification.Code = programTier.Oracle_Classification_Code__c;
							classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
							classification.EndDate = null;
							ioclassificationList.add(classification);

							// add classification for the partner type
							classification = new IntegrationObjects.Classification();
							classification.Status = ACTIVE_STATUS;
							classification.Code = partnerProgram.Program__r.Oracle_Classification_Code__c;
							classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
							classification.EndDate = null;
							ioclassificationList.add(classification);
						}
					}

					//CDH will get flow if the record updated from Active or Approved status.
					else if(insertevent == false && deleteevent == false && oldpartnerprogram.containsKey(partnerProgram.Id)) {

						System.debug('IN UPDATE 2!!!! ' + partnerProgram.Program__r.Program_Category__c + partnerProgram.Tier__c + partnerProgram.Status__c);

						//getting old value of the record when updated.
						Partner_Program__c oldvalue= oldpartnerprogram.get(partnerProgram.Id);
						//getting new value of the record when updated.
						Partner_Program__c newvalue= newpartnerprogram.get(partnerProgram.Id);
						//getting  value of the record of tier before updated.
						Partner_Program_Tier__c oldprogramTier =  mapOfProgramTier.get(oldvalue.Program__c+oldvalue.Tier__c);
						//getting  value of the record of tier after updated.
						Partner_Program_Tier__c newprogramTier = mapOfProgramTier.get(newvalue.Program__c+newvalue.Tier__c);

						if(oldvalue.Status__c != newvalue.Status__c || oldvalue.tier__c != newvalue.tier__c) {
							System.debug('Status changed from ' + oldvalue.Status__c + ' to ' + newvalue.Status__c);

							//if old status is active or approved and getting changed to some other status.
							if((oldvalue.Status__c == ACTIVE_STATUS ||
								oldvalue.Status__c == APPROVE_STATUS) &&
								oldprogramTier!= Null &&
								oldprogramTier.Oracle_Classification_Code__c != Null &&
								oldprogramTier != newprogramTier)
							{
								IntegrationObjects.classification classification = new IntegrationObjects.classification();
								classification.Status = INACTIVE_STATUS;
								classification.Code = oldprogramTier.Oracle_Classification_Code__c;
								classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
								classification.EndDate = IntegrationObjectsUtils.formatDatetime(System.now());
								invokeoutbound = true;
								ioclassificationList.add(classification);

								// tier change - don't deactivate the program itself
							}

							//condition to check if the old value of program has null value and getting changed to the program with value.
							if(( oldvalue!= null && ( oldvalue.Status__c == ACTIVE_STATUS ||
								oldvalue.Status__c == APPROVE_STATUS)  )&&
								oldprogramTier == null &&
								newProgramTier != null &&
								oldprogramTier != newprogramTier)
							{
								IntegrationObjects.classification classification = new IntegrationObjects.classification();
								classification.Status = ACTIVE_STATUS;
								classification.Code = newprogramTier.Oracle_Classification_Code__c;
								classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
								classification.EndDate = null;
								invokeoutbound = true;
								ioclassificationList.add(classification);

								// add classification for the partner type
								IntegrationObjects.Classification clfnType = new IntegrationObjects.Classification();
								clfnType.Status = ACTIVE_STATUS;
								clfnType.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
								clfnType.EndDate = null;
								clfnType.Code = partnerProgram.Program__r.Oracle_Classification_Code__c;
								ioclassificationList.add(clfnType);
							}

							//if new status is active or approved and getting changed to some other status.
							if((newvalue.Status__c == ACTIVE_STATUS ||
								newvalue.Status__c == APPROVE_STATUS) &&
								newprogramTier!=Null &&
								newprogramTier.Oracle_Classification_Code__c!=Null &&
								oldprogramTier!=Null &&
								oldprogramTier.Oracle_Classification_Code__c != newprogramTier.Oracle_Classification_Code__c)
							{
								IntegrationObjects.classification classification = new IntegrationObjects.classification();
								classification.Status = ACTIVE_STATUS;
								classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
								classification.EndDate = null;
								classification.Code = newprogramTier.Oracle_Classification_Code__c;
								invokeoutbound = true;
								ioclassificationList.add(classification);

								// add classification for the partner type
								IntegrationObjects.Classification clfnType = new IntegrationObjects.Classification();
								clfnType.Status = ACTIVE_STATUS;
								clfnType.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
								clfnType.EndDate = null;
								clfnType.Code = partnerProgram.Program__r.Oracle_Classification_Code__c;
								ioclassificationList.add(clfnType);
							}

							//if old status is active/approved not changes to active/approved.
							if(newprogramTier != Null &&
								newprogramTier.Oracle_Classification_Code__c != Null &&
								oldprogramTier != Null &&
								newprogramTier.Oracle_Classification_Code__c == oldprogramTier.Oracle_Classification_Code__c &&
								newvalue.Active__c != oldvalue.Active__c)
							{
								IntegrationObjects.classification classification = new IntegrationObjects.classification();
								classification.Status = newvalue.Active__c==True ? ACTIVE_STATUS:INACTIVE_STATUS;
								classification.Code = newprogramTier.Oracle_Classification_Code__c;
								classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
								if(classification.status == ACTIVE_STATUS) {
									classification.EndDate = null;
								}
								else {
									classification.EndDate = IntegrationObjectsUtils.formatDatetime(System.now());
								}
								invokeoutbound = true;
								ioclassificationList.add(classification);

								// add classification for the partner type
								IntegrationObjects.Classification clfnType = new IntegrationObjects.Classification();
								clfnType.Status = classification.Status;
								clfnType.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
								clfnType.EndDate = classification.EndDate;
								clfnType.Code = partnerProgram.Program__r.Oracle_Classification_Code__c;
								ioclassificationList.add(clfnType);
							}
						}
					}

					//this else will get executed if partner program is getting deleted for an account.
					else if(insertevent == false &&
						deletdPartnerprogram.containskey(partnerProgram.id) &&
						(partnerProgram.Status__c == ACTIVE_STATUS ||
						partnerProgram .Status__c == APPROVE_STATUS) &&
						programTier !=Null &&
						programTier.Oracle_Classification_Code__c != Null)
					{

						System.debug('IN DELETE!!!! ' + partnerProgram.Program__r.Program_Category__c + partnerProgram.Tier__c + partnerProgram.Status__c);

						//adding in a list of classification
						IntegrationObjects.classification classification = new IntegrationObjects.classification();
						classification.Status = INACTIVE_STATUS ;
						classification.Code = programTier.Oracle_Classification_Code__c;
						classification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
						classification.EndDate = IntegrationObjectsUtils.formatDatetime(System.now());
						ioclassificationList.add(classification);
						if(deletdPartnerprogram.containskey(partnerProgram.id)) {
							invokeoutbound = true;
						}

						// add classification for the partner type
						IntegrationObjects.Classification clfnType = new IntegrationObjects.Classification();
						clfnType.Status = INACTIVE_STATUS;
						clfnType.Code = partnerProgram.Program__r.Oracle_Classification_Code__c;
						clfnType.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
						clfnType.EndDate = IntegrationObjectsUtils.formatDatetime(System.now());
						ioclassificationList.add(clfnType);
					}

					// The program didn't fall in any of the buckets above, so simply add it
					else {

						System.debug('IN ELSE!!!! ' + partnerProgram.Program__r.Program_Category__c + partnerProgram.Tier__c + partnerProgram.Status__c);

						IntegrationObjects.Classification ioClassification = IntegrationObjectConverter.convertClassification(partnerProgram);
						if(programTier == null) {
							System.debug('program tier is null');
							continue;
						}
						ioClassification.Code = programTier.Oracle_Classification_Code__c;
						ioClassification.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
						if(ioClassification.status == ACTIVE_STATUS) {
							ioClassification.EndDate = null;
						}
						else {
							ioClassification.EndDate = IntegrationObjectsUtils.formatDatetime(System.now());
						}
						system.debug('lisioClassification'+ioClassification);
						ioClassificationList.add(ioClassification);

						// add classification for the partner type
						IntegrationObjects.Classification clfnType = new IntegrationObjects.Classification();
						clfnType.Status = ioClassification.Status;
						clfnType.Code = partnerProgram.Program__r.Oracle_Classification_Code__c;
						clfnType.StartDate = IntegrationObjectsUtils.formatDatetime(partnerProgram.CreatedDate);
						if(clfnType.status == ACTIVE_STATUS) {
							clfnType.EndDate = null;
						}
						else {
							clfnType.EndDate = IntegrationObjectsUtils.formatDatetime(System.now());
						}
						ioclassificationList.add(clfnType);

					}
				}

				List<IntegrationObjects.Address> ioAddressList = new List<IntegrationObjects.Address>();
				//Assigning the value of account iterating to an instance of outbound account.
				ioAccount.IDs = account.Id;
				ioAccount.CDH_Party_Number = account.CDHPartyNumber__c;
				ioAccount.Name = account.Name;
				ioAccount.CDH_Party_Type = account.CDH_Party_Type__c;
				ioAccount.VATNumber = account.VATNumber__c;
				ioAccount.D_U_N_S = account.DunsNumber;
				ioAccount.Status = account.Status__c;
				ioAccount.Sic = account.Sic;
				ioAccount.SicDesc = account.SicDesc;
				ioAccount.All_NAICS_Codes = account.All_NAICS_Codes__c;
				ioAccount.Do_Not_Do_Business_with = account.Do_Not_Do_Business_With__c;
				ioAccount.SEA_Concern = account.SEA_Concern__c;
				ioAccount.Trade_Style = account.Tradestyle;
				ioAccount.YearStarted = account.YearStarted;
				ioAccount.NumberOfEmployees = account.NumberOfEmployees;
				ioAccount.AnnualRevenue = account.AnnualRevenue;
				ioAccount.Website = account.Website;
				ioAccount.Phone = account.Phone;
				ioAccount.Fax = account.Fax;
				ioAccount.Head_Quarters = account.Headquarters_CDH_Party_Number__c;
				ioAccount.Domestic_Ultimate = account.Domestic_Ultimate__c;
				ioAccount.Global_Ultimate = account.Global_Ultimate__c;
				ioAccount.Linkedin_URL = account.Linkedin_URL__c;

				if (account.Addresses__r != null && account.Addresses__r.size() > 0){
					ioAccount.addresses = new List<IntegrationObjects.Address>();
					for(Address__c address : account.Addresses__r)
					{
						//Generating the Integration object of address using , Integration object converter class
						// Invoke QueueAddressMessage method of OutBoundService class.
						IntegrationObjects.Address ioAddress  = new IntegrationObjects.Address();
						ioAddress = IntegrationObjectConverter.convertAddress(address);
						ioAddressList.add(ioAddress);
					}
				}

				ioAccount.PartnerClassifications = ioclassificationList;
				ioAccount.addresses = ioAddressList;

				//Checking if partner program list is updated/inserted is not null.
				if(!ioclassificationList.isempty() && ((insertevent == False && invokeoutbound == True) || (insertevent == True && invokeoutbound == True)))
				{
					//queue invoking outbound service to outbound CDH of Account.
					ioAccountUpdates.add(ioAccount);
				}
			}
		}
		//invoking outbound service to outbound CDH of Account.
		OutboundService.queueAccountMessages(ioAccountUpdates,'UPDATE');
	}

	/**
	*This is the method invoked by to get the detail of the record of tier object.
	*@param :
	*@return : List of tier records in a map.   */
	public void getMapOfPartnerProgramAndTier(){

		//iterating through the program tier object record and assigning them in map.
		for(Partner_Program_Tier__c programTier : [Select CDH_Mastered__c,
			Oracle_Classification_Code__c,
			Partner_Program_Definition__c,
			Tier__c
			from Partner_Program_Tier__c]){

				//checking if the record of tier has definition value.
				if(programTier.Partner_Program_Definition__c!=Null &&
				  programTier.Tier__c!= Null){
						//inserting the values of record of map.
						mapOfProgramTier.put(programTier.Partner_Program_Definition__c+programTier.Tier__c,programTier);
				}
			}
	}
}