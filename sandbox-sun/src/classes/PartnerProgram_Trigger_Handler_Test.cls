@isTest
private class PartnerProgram_Trigger_Handler_Test
{
	@isTest
	static void testAddRemoveProgramToPartner()
	{
                CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('1999');
                insert cdhParty;
                Account acct = IntegrationObjectsTestUtil.getSFAccount(cdhParty, cdhParty.CDH_Party_Name__c);
                insert acct;
                Address__c addr = IntegrationObjectsTestUtil.getSFAddress(acct, 'East Davie Street', 'Raleigh', 'NC');
                insert addr;

                BooleanSetting__c bs = new BooleanSetting__c(Name='PartnerProgram_Trigger',Value__c=true);
                insert bs;

                //insert partner program definition where oracle code is not null.
                Partner_Program_Definition__c progDef = new Partner_Program_Definition__c(
                    Is_Internal_Only__c = false,
                    Is_Primary_Eligible__c = true,
                    Oracle_Classification_Code__c = '0100',
                    Program_Category__c = 'Solution Provider',
                    Program_Status__c = 'Active',
                    Partner_Type__c = 'Reseller');
                insert progDef;
                Partner_Program_Tier__c tierDef = new Partner_Program_Tier__c();
                tierDef.Oracle_Classification_Code__c = '0123';
                tierDef.Partner_Program_Definition__c = progDef.Id;
                tierDef.CDH_Mastered__c = False;
                tierDef.Is_Active__c = True;
                tierDef.Order__c = 1;
                tierDef.Tier__c = 'Ready';
                insert tierDef;
                tierDef = new Partner_Program_Tier__c();
                tierDef.Oracle_Classification_Code__c = '0124';
                tierDef.Partner_Program_Definition__c = progDef.Id;
                tierDef.CDH_Mastered__c = False;
                tierDef.Is_Active__c = True;
                tierDef.Order__c = 2;
                tierDef.Tier__c = 'Advanced';
                insert tierDef;

                test.starttest();

                List<Outbound_Event__c> events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after create: ' + events.size());
                System.assertEquals(1, events.size());

                Account partnerAccount = PartnerTestUtils.makeAccount('PartnerProgram Trigger Test', PartnerTestUtils.getAdminUser());
                partnerAccount.CDH_Party_Name__c = cdhParty.Id;
                Id partnerAccountId = partnerAccount.Id;

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events before add program: ' + events.size());
                System.assertEquals(1, events.size());

                update partnerAccount;

                /* insert partner program record when program partner's status is active and it's related definition object has oracle classification code
                value, so outbound service is called and CDH will flow.*/
                Partner_Program__c progMembership = new Partner_Program__c();
                progMembership.Status__c = 'Active';
                progMembership.Account__c = partnerAccount.id;
                progMembership.Tier__c = 'Ready';
                progMembership.Program__c = progDef.id;
                insert progMembership;

                Account xaccount = [select CDH_Party_Name__r.PartnerPrograms__c from Account where Id = :acct.Id];
                System.assertEquals('Reseller-Ready',xaccount.CDH_Party_Name__r.PartnerPrograms__c);

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after add program: ' + events.size());
                System.assertEquals(2, events.size());

                progMembership.Tier__c = 'Advanced';
                update progMembership;

                xaccount = [select CDH_Party_Name__r.PartnerPrograms__c from Account where Id = :acct.Id];
                System.assertEquals('Reseller-Advanced',xaccount.CDH_Party_Name__r.PartnerPrograms__c);

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after change tier on program: ' + events.size());
                System.assertEquals(3, events.size());

                delete progMembership;

                xaccount = [select CDH_Party_Name__r.PartnerPrograms__c from Account where Id = :acct.Id];
                System.assertEquals(null,xaccount.CDH_Party_Name__r.PartnerPrograms__c);

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after delete program: ' + events.size());
                System.assertEquals(4, events.size());

                progMembership = new Partner_Program__c();
                progMembership.Status__c = 'Active';
                progMembership.Account__c = partnerAccount.id;
                progMembership.Tier__c = 'Ready';
                progMembership.Program__c = progDef.id;
                insert progMembership;
                test.stoptest();

                xaccount = [select CDH_Party_Name__r.PartnerPrograms__c from Account where Id = :acct.Id];
                System.assertEquals('Reseller-Ready',xaccount.CDH_Party_Name__r.PartnerPrograms__c);

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after add program: ' + events.size());
                System.assertEquals(5, events.size());

	}

        @isTest
        static void testInactivateProgramOnPartner()
        {
                CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('1999');
                insert cdhParty;
                Account acct = IntegrationObjectsTestUtil.getSFAccount(cdhParty, cdhParty.CDH_Party_Name__c);
                insert acct;
                Address__c addr = IntegrationObjectsTestUtil.getSFAddress(acct, 'East Davie Street', 'Raleigh', 'NC');
                insert addr;

                BooleanSetting__c bs = new BooleanSetting__c(Name='PartnerProgram_Trigger',Value__c=true);
                insert bs;

                //insert partner program definition where oracle code is not null.
                Partner_Program_Definition__c progDef = new Partner_Program_Definition__c();
                progDef.Program_Category__c = 'Solution Provider';
                progDef.Program_Status__c = 'Active';
                progDef.Is_Primary_Eligible__c = true;
                insert progDef;
                Partner_Program_Tier__c tierDef = new Partner_Program_Tier__c();
                tierDef.Oracle_Classification_Code__c = '0123';
                tierDef.Partner_Program_Definition__c = progDef.Id;
                tierDef.CDH_Mastered__c = False;
                tierDef.Is_Active__c = True;
                tierDef.Order__c = 1;
                tierDef.Tier__c = 'Ready';
                insert tierDef;
                tierDef = new Partner_Program_Tier__c();
                tierDef.Oracle_Classification_Code__c = '0124';
                tierDef.Partner_Program_Definition__c = progDef.Id;
                tierDef.CDH_Mastered__c = False;
                tierDef.Is_Active__c = True;
                tierDef.Order__c = 2;
                tierDef.Tier__c = 'Advanced';
                insert tierDef;

                test.starttest();

                List<Outbound_Event__c> events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after create: ' + events.size());
                System.assertEquals(1, events.size());

                Account partnerAccount = PartnerTestUtils.makeAccount('PartnerProgram Trigger Test', PartnerTestUtils.getAdminUser());
                partnerAccount.CDH_Party_Name__c = cdhParty.Id;
                Id partnerAccountId = partnerAccount.Id;

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events before add program: ' + events.size());
                System.assertEquals(1, events.size());

                update partnerAccount;

                /* insert partner program record when program partner's status is active and it's related definition object has oracle classification code
                value, so outbound service is called and CDH will flow.*/
                Partner_Program__c progMembership = new Partner_Program__c();
                progMembership.Status__c = 'Active';
                progMembership.Account__c = partnerAccount.id;
                progMembership.Tier__c = 'Ready';
                progMembership.Program__c = progDef.id;
                insert progMembership;

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after add program: ' + events.size());
                System.assertEquals(2, events.size());

                progMembership.Status__c = 'Inactive';
                update progMembership;

                events = [Select Id, Event_Type__c, Record_Id__c from Outbound_Event__c where Record_Id__c = :acct.Id];
                System.debug('Number of events after change tier on program: ' + events.size());
                System.assertEquals(3, events.size());

                test.stoptest();
        }
}