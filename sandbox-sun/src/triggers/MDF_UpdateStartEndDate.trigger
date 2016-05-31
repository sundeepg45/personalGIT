trigger MDF_UpdateStartEndDate on SFDC_Budget__c (before insert,before update) {

    SFDC_Budget__c[] parlist = new List<SFDC_Budget__c>();
    SFDC_Budget__c[] mdflist = new List<SFDC_Budget__c>();
    for (SFDC_Budget__c rec : Trigger.new) {
        if (rec.RecordType.DeveloperName == 'PAR' || rec.Is_PAR__c == true) {
            parlist.add(rec);
        }
        else {
            mdflist.add(rec);
        }
    }
    
    if (!parlist.isEmpty()) {
        // nothing to do here, yet
    }
    
    if (!mdflist.isEmpty()) {
        // This class is crap.
        // new StartEndDateUpdateMDF().updateMDF();
        
        //
        // Determine what is the actual current Fiscal Year
        //
        
        Integer currentFY = MDFTestSupport.getCurrentFiscalYearAsInteger();
        
        //
        // Recalculate the start/end dates.
        //
        
        for(SFDC_Budget__c mdf : mdflist) {
            // If either of the Fiscal Quarter or the Selected Fiscal Year is missing,
            // then remove any start/end dates. 
            
            if (mdf.Select_Fiscal_Year__c == null || mdf.Fiscal_Quarter__c == null) {
                mdf.End_Date__c = null;
                mdf.Start_Date__c = null;
                continue;
            } 
            
            // When the selected fiscal year is present, but the FY is missing, then
            // we have to determine which actual FY this MDF belongs in.
            
            if (mdf.Fiscal_Year__c == null && mdf.Select_Fiscal_Year__c == 'Current Fiscal Year')
                mdf.Fiscal_Year__c = 'FY' + (currentFY + 0);
            else if (mdf.Fiscal_Year__c == null && mdf.Select_Fiscal_Year__c == 'Next Fiscal Year')
                mdf.Fiscal_Year__c = 'FY' + (currentFY + 1);
            else if (mdf.Fiscal_Year__c == null)
                system.assert(false, 'MDF.Fiscal_Year__c is missing and the selected fiscal year field is not a valid option: ' + mdf);
            
            // At this point, we should have (whether calculated here or prefilled):
            // - A valid MDF.Fiscal_Year__c
            // - A valid MDF.Fiscal_Quarter__C
            //
            // Based on this information, we can calculate the start and end dates.
    
            Integer FY = Integer.valueOf(mdf.Fiscal_Year__c.substring(2));      // from FY2010 to 2010
            
            // Red Hat fiscal quarters are as follows:
            // 
            // Q1 : 03-01 to 05-31
            // Q2 : 06-01 to 08-31
            // Q3 : 09-01 to 11-30
            // Q4 : 12-01 to 02-28/29
            
            if (mdf.Fiscal_Quarter__c == 'Q1') {
                mdf.Start_Date__c = Date.newInstance(FY - 1, 3, 1);
                mdf.End_Date__c = Date.newInstance(FY - 1, 5, 31);
            } else if (mdf.Fiscal_Quarter__c == 'Q2') {
                mdf.Start_Date__c = Date.newInstance(FY - 1, 6, 1);
                mdf.End_Date__c = Date.newInstance(FY - 1, 8, 31);
            } else if (mdf.Fiscal_Quarter__c == 'Q3') {
                mdf.Start_Date__c = Date.newInstance(FY - 1, 9, 1);
                mdf.End_Date__c = Date.newInstance(FY - 1, 11, 30);
            } else if (mdf.Fiscal_Quarter__c == 'Q4' && Date.isLeapYear(FY)) {
                mdf.Start_Date__c = Date.newInstance(FY - 1, 12, 1);
                mdf.End_Date__c = Date.newInstance(FY, 2, 29);
            } else if (mdf.Fiscal_Quarter__c == 'Q4') {
                mdf.Start_Date__c = Date.newInstance(FY - 1, 12, 1);
                mdf.End_Date__c = Date.newInstance(FY, 2, 28);
            } else {
                system.assert(false, 'Illegal value for MDF.Fiscal_Quarter__c: ' + mdf);
            }
        }
    }
}