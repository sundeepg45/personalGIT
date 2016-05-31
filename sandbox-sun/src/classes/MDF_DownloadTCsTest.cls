@IsTest
private class MDF_DownloadTCsTest {
    public static MDF_DownloadTCs instance {
        set;
        get;
    }
    
    public static List<MDF_DownloadTCs.Partner_Attachment_Wrapper> downloadList {
        set;
        get;
    }
    
    public static testmethod void testDownloadNonExistant() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'Unknown';
        account1.Subregion__c = 'Unknown';
        insert account1;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account1.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100.00;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = 'Q3';
        mdf.Start_Date__c = Date.newInstance(2009, 9, 1);
        mdf.End_Date__c = Date.newInstance(2009, 11, 30);
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;
        
        instance = new MDF_DownloadTCs(new ApexPages.StandardController(mdf));
        downloadList = instance.partnerAttachmentList;
        
        system.assert(downloadList != null);
        system.assertEquals(0, downloadList.size());
    }
}