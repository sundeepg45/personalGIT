@IsTest
private class MDF_DownloadProgramGuideTest {
    public static MDF_DownloadProgramGuide instance {
        set;
        get;
    }
    
    public static List<MDF_DownloadProgramGuide.Partner_Attachment_Wrapper> downloadList {
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
        
        instance = new MDF_DownloadProgramGuide(new ApexPages.StandardController(mdf));
        downloadList = instance.partnerAttachmentList;
        
        system.assert(downloadList != null);
        system.assertEquals(0, downloadList.size());
    }

    public static testmethod void testDownloadAPACGreaterChina() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'APAC';
        account1.Subregion__c = 'Greater China';
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

        instance = new MDF_DownloadProgramGuide(new ApexPages.StandardController(mdf));
        downloadList = instance.partnerAttachmentList;
        
        system.assert(downloadList != null);
        system.assertEquals(2, downloadList.size());

        // Localized version
        system.assertEquals('APAC', downloadList[0].partnerAttachment.Global_Region__c);
        system.assertEquals('Greater China', downloadList[0].partnerAttachment.Subregion__c);
        system.assertEquals('Chinese (Simplified)', downloadList[0].partnerAttachment.Language__c);
        system.assert(null != downloadList[0].partnerAttachmentUrl);

        // Master version
        system.assertEquals('APAC', downloadList[1].partnerAttachment.Global_Region__c);
        system.assertEquals(null, downloadList[1].partnerAttachment.Subregion__c);
        system.assertEquals('English', downloadList[1].partnerAttachment.Language__c);
        system.assert(null != downloadList[1].partnerAttachmentUrl);
    }

    public static testmethod void testDownloadAPACJapan() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'APAC';
        account1.Subregion__c = 'Japan';
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
        
        instance = new MDF_DownloadProgramGuide(new ApexPages.StandardController(mdf));
        downloadList = instance.partnerAttachmentList;
        
        system.assert(downloadList != null);
        system.assertEquals(2, downloadList.size());

        // Localized version
        system.assertEquals('APAC', downloadList[0].partnerAttachment.Global_Region__c);
        system.assertEquals('Japan', downloadList[0].partnerAttachment.Subregion__c);
        system.assertEquals('Japanese', downloadList[0].partnerAttachment.Language__c);
        system.assert(null != downloadList[0].partnerAttachmentUrl);

        // Master version
        system.assertEquals('APAC', downloadList[1].partnerAttachment.Global_Region__c);
        system.assertEquals(null, downloadList[1].partnerAttachment.Subregion__c);
        system.assertEquals('English', downloadList[1].partnerAttachment.Language__c);
        system.assert(null != downloadList[1].partnerAttachmentUrl);
    }

    public static testmethod void testDownloadAPACKorea() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'APAC';
        account1.Subregion__c = 'Korea';
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

        instance = new MDF_DownloadProgramGuide(new ApexPages.StandardController(mdf));
        downloadList = instance.partnerAttachmentList;
        
        system.assert(downloadList != null);
        system.assertEquals(2, downloadList.size());

        // Localized version
        system.assertEquals('APAC', downloadList[0].partnerAttachment.Global_Region__c);
        system.assertEquals('Korea', downloadList[0].partnerAttachment.Subregion__c);
        system.assertEquals('Korean', downloadList[0].partnerAttachment.Language__c);
        system.assert(null != downloadList[0].partnerAttachmentUrl);

        // Master version
        system.assertEquals('APAC', downloadList[1].partnerAttachment.Global_Region__c);
        system.assertEquals(null, downloadList[1].partnerAttachment.Subregion__c);
        system.assertEquals('English', downloadList[1].partnerAttachment.Language__c);
        system.assert(null != downloadList[1].partnerAttachmentUrl);
    }

    public static testmethod void testDownloadNAFedSled() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'NA';
        account1.Subregion__c = 'Fed Sled';
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
        
        instance = new MDF_DownloadProgramGuide(new ApexPages.StandardController(mdf));
        downloadList = instance.partnerAttachmentList;
        
        system.assert(downloadList != null);
        system.assertEquals(1, downloadList.size());

        // Master version
        system.assertEquals('NA', downloadList[0].partnerAttachment.Global_Region__c);
        system.assertEquals('Fed Sled', downloadList[0].partnerAttachment.Subregion__c);
        system.assertEquals('English', downloadList[0].partnerAttachment.Language__c);
        system.assert(null != downloadList[0].partnerAttachmentUrl);
    } 

}