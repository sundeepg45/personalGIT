trigger Anti_Corruption_Delgate on Anti_corruption__c (after update) {

	if (Trigger.IsUpdate) {
		Account[] accountUpdates = new List<Account>();
		Partner_Program__c[] programUpdates = new List<Partner_Program__c>();

		for (Anti_Corruption__c ac : Trigger.new) {
			Anti_Corruption__c oldac = Trigger.oldMap.get(ac.Id);
			System.debug('*****[debug]***** Origin=' + ac.Origin__c);
			System.debug('*****[debug]***** Review_Status=' + ac.Review_Status__c);

			//
			// ONBOARDING
			//
			if (ac.Origin__c == 'Onboarding' && ac.Review_Status__c != oldac.Review_Status__c && (ac.Review_Status__c == 'Approved and Archived' || ac.Review_Status__c == 'Rejected')) {
				//
				// remove from holding queue
				//
				if (ac.Lead__c != null) {

					ProcessInstanceWorkItem[] wilist = [
						select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
						from	ProcessInstanceWorkitem p
						where	p.ProcessInstance.TargetObjectId = :ac.Lead__c
						and		p.ProcessInstance.Status = 'Pending'
					];
					if (wilist.isEmpty()) {
						System.debug('*****[debug]***** Expected to find an approval process item for Lead ' + ac.Lead__c);
						continue;
					}
					ProcessInstanceWorkItem wi = wilist.get(0);
					Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        			if (ac.Review_Status__c == 'Approved and Archived') {
				        req.setAction('Approve');
	        			req.setComments('Approving request to continue onboarding workflow');
        			}
				    else {
				    	req.setAction('Reject');
	        			req.setComments('Lead rejected');
					}
	        		req.setWorkitemId(wi.Id);
        			Approval.ProcessResult result =  Approval.process(req);
        			System.assert(result.isSuccess(), 'Unable to ' + req.getAction() + ' Lead for onboarding');

        			System.debug('*****[debug]***** Onboarding ' + req.getAction());
				}
				else if (ac.Partner_Onboarding__c != null) {
                    ProcessInstanceWorkItem[] wilist = [
                        select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
                        from    ProcessInstanceWorkitem p
                        where   p.ProcessInstance.TargetObjectId = :ac.Partner_Onboarding__c
                        and     p.ProcessInstance.Status = 'Pending'
                    ];
                    if (wilist.isEmpty()) {
                        System.debug('*****[debug]***** Expected to find an approval process item for Onboarding ' + ac.Partner_Onboarding__c);
                        continue;
                    }
                    ProcessInstanceWorkItem wi = wilist.get(0);
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    if (ac.Review_Status__c == 'Approved and Archived') {
                        req.setAction('Approve');
                        req.setComments('Approving request to continue onboarding workflow');
                    }
                    else {
                        req.setAction('Reject');
                        req.setComments('Lead rejected');
                    }
                    req.setWorkitemId(wi.Id);
					OnboardingUtils.APPROVED_BY_API = true;
                    Approval.ProcessResult result =  Approval.process(req);
                    System.assert(result.isSuccess(), 'Unable to ' + req.getAction() + ' Onboarding Request');
                    System.debug('*****[debug]***** Onboarding ' + req.getAction());
				}
                else {
                    System.debug('*****[debug]***** Required Partner_Onboarding__c is missing');
                }

				if (ac.Partner_Account__c != null) {
					accountUpdates.add(new Account(Id = ac.Partner_Account__c, Anti_Corruption_Status__c = 'Approved'));
				}
			}
			//
			// REQUALIFICATION
			//
			if (ac.Origin__c == 'Requalification' && ac.Review_Status__c != oldac.Review_Status__c && (ac.Review_Status__c == 'Approved and Archived' || ac.Review_Status__c == 'Rejected')) {
				// the approval process takes care of updating the account requalstatus to 'Complete'

				//
				// remove from holding queue
				//
				if (ac.Partner_Account__c != null) {

					ProcessInstanceWorkItem[] wilist = [
						select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
						from	ProcessInstanceWorkitem p
						where	p.ProcessInstance.TargetObjectId = :ac.Partner_Account__c
						and		p.ProcessInstance.Status = 'Pending'
					];
					if (!wilist.isEmpty()) {
						ProcessInstanceWorkItem wi = wilist.get(0);
				        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
	        			if (ac.Review_Status__c == 'Approved and Archived') {
					        req.setAction('Approve');
		        			req.setComments('Approving request to continue requalification workflow');
	        			}
					    else {
					    	req.setAction('Reject');
		        			req.setComments('Requalification rejected');
					    }
		        		req.setWorkitemId(wi.Id);
						AccountControllerExt.APPROVED_BY_API = true;
						Approval.ProcessResult result =  Approval.process(req);
	        			System.assert(result.isSuccess(), 'Unable to ' + req.getAction() + ' Requalification');

	        			System.debug('*****[debug]***** Requalification ' + req.getAction());
					}

                    String govt_pos = ac.Government_position__c ? 'Yes' : 'No';
        			if (ac.Review_Status__c == 'Rejected') {
        				System.debug('*****[debug]***** disabling account');
        				//
        				// disable the account
        				//
        				Partner_Program__c currentProgram = [
        					select	Id
        					from	Partner_Program__c
        					where	Account__c = :ac.Partner_Account__c
        					and		Is_Primary__c = true
        				];
						currentProgram.Tier__c = PartnerConst.UNAFFILIATED;
						programUpdates.add(currentProgram);
                        accountUpdates.add(new Account(Id = ac.Partner_Account__c, Anti_Corruption_Status__c = 'Rejected', Do_they_act_in_any_government_position__c = govt_pos));
                        Partner_State_Wrapper.setLegalBlocked(ac.Partner_Account__c, ac.Legal_Rejection__c);
        			}
                    else {
                        accountUpdates.add(new Account(Id = ac.Partner_Account__c, Anti_Corruption_Status__c = 'Approved', Do_they_act_in_any_government_position__c = govt_pos));
                    }
				}
				else {
					System.debug('*****[debug]***** Required Partner_Account__c is missing');
				}

			}
			//
			// TIER UPGRADE
			//
			if (ac.Origin__c == 'Tier Upgrade' && ac.Review_Status__c != oldac.Review_Status__c &&
                (ac.Review_Status__c.contains('Approved and Archived') || ac.Review_Status__c == 'Rejected')) {
				//
				// remove from holding queue
				//
				if (ac.Partner_Program_Approval__c != null) {

					ProcessInstanceWorkItem[] wilist = [
						select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
						from	ProcessInstanceWorkitem p
						where	p.ProcessInstance.TargetObjectId = :ac.Partner_Program_Approval__c
						and		p.ProcessInstance.Status = 'Pending'
					];
					if (wilist.isEmpty()) {
						System.debug('*****[debug]***** Expected to find an approval process item for Partner Program ' + ac.Partner_Program_Approval__c);
						return;
					}

					ProcessInstanceWorkItem wi = wilist[0];
			        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        			if (ac.Review_Status__c.contains('Approved and Archived')) {
				        req.setAction('Approve');
	        			req.setComments('Approving request to continue tier upgrade workflow');
						accountUpdates.add(new Account(Id = ac.Partner_Account__c, Anti_Corruption_Status__c = 'Approved'));
        			}
				    else {
				    	req.setAction('Reject');
	        			req.setComments('Tier upgrade rejected');
						accountUpdates.add(new Account(Id = ac.Partner_Account__c, Anti_Corruption_Status__c = 'Rejected'));
                        Partner_State_Wrapper.setLegalBlocked(ac.Partner_Account__c, true);

						Partner_Program__c currentProgram = [
        					select	Id
        					from	Partner_Program__c
        					where	Account__c = :ac.Partner_Account__c
        					and		Is_Primary__c = true
        				];
						currentProgram.Tier__c = PartnerConst.UNAFFILIATED;
						programUpdates.add(currentProgram);
				    }
	        		req.setWorkitemId(wi.Id);
					PartnerTierControllerExt.APPROVED_BY_API = true;
        			Approval.ProcessResult result =  Approval.process(req);
        			System.assert(result.isSuccess(), 'Unable to ' + req.getAction() + ' Tier Upgrade');
        			System.debug('*****[debug]***** Tier Upgrade ' + req.getAction());

				}
				else {
					System.debug('*****[debug]***** Required Partner_Status__c is missing');
				}
			}
		}
		if (!accountUpdates.isEmpty()) {
			update accountUpdates;
		}
		if (!programUpdates.isEmpty()) {
			update programUpdates;
		}
        Partner_State_Wrapper.commitCache();
	}
}