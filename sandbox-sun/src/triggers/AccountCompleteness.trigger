trigger AccountCompleteness on Account (before insert, before update)
{
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
	if(Trigger.isBefore) {
		for(Integer i=0;i<Trigger.new.size();i++)
		{
			Double complete = 
				Util.isNill(trigger.new[i].AccountClassification__c)?0.0:1.0;
			Double count = 1;
			if(! Util.isNill(trigger.new[i].Phone))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Website))
				complete += 1.0;
			count++;
			if(! (Util.isNill(trigger.new[i].BillingStreet)
					|| Util.isNill(trigger.new[i].BillingCity)
					|| Util.isNill(trigger.new[i].BillingState)
					|| Util.isNill(trigger.new[i].BillingPostalCode) )) 
				complete += 1.0;
			count++;
			if(! (Util.isNill(trigger.new[i].ShippingStreet)
					|| Util.isNill(trigger.new[i].ShippingCity)
					|| Util.isNill(trigger.new[i].ShippingState)
					|| Util.isNill(trigger.new[i].ShippingPostalCode) )) 
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Description))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Recent_Major_Events__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].RH_Sales_Strategy__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].D_U_N_S__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Ownership))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Industry))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].NumberOfEmployees))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].AnnualRevenue))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Fiscal_Year_End__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Target_Revenue_for_Red_Hat_yearly__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Revenue_to_Date__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].PreferredHWVendor__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Enrollment_Date__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Accreditation__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Number_of_RHCE__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Number_of_RHCT_Certifications__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Number_of_RHCA_Certifications__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Number_of_RHCSS_Certifications__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Number_of_Trained_JBoss_Professionals__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Partner_Account_Status__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Class_of_Trade__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Num_of_End_Customer_Account__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Key_Contact_Email__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Key_Contact__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Key_Contact_Cell_Phone__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Key_Contact_Primary_Phone__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Service_Area__c))
				complete += 1.0;
			count++;
 //		   if(! Util.isNill(trigger.new[i].certified_employees__c))
 //			   complete += 1.0;
 //		   count++;
			if(! Util.isNill(trigger.new[i].Technology_Solutions_Expertise__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Solution_Partners__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Industry_Vertical_Expertise__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Service_Offerings__c))
				complete += 1.0;
			count++;
			if(! Util.isNill(trigger.new[i].Sweet_Spot__c))
				complete += 1.0;
			count++;
			if( trigger.new[i].Special_Service_Offerings_or_Skills__c ) {
				if(! Util.isNill(trigger.new[i].Describe__c))
					complete += 1.0;
				count++;
			}
			trigger.new[i].Completeness__c = 100.0*complete/count;
		}
	}
}