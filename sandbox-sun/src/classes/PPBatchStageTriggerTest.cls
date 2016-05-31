@isTest
private class PPBatchStageTriggerTest {


    static testmethod void newContactTest() {
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Weyland-Yutani Corp');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Dallas_Nostromo');
        c.Point_Accrual_Start__c = System.now();
        insert c;

        //delete [select Id from Partner_Points_Course__c];

        PP_Catalog__c cat = new PP_Catalog__c(Category__c = 'Bulk Uploads');
        insert cat;

        PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 76, Partial_Points__c = 10, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Red Hat Summit');
        insert batch;

        PP_InboundBatchStage__c ib = new PP_InboundBatchStage__c(Batch__c = batch.Id, Super_Region__c = 'NA');
        insert ib;

        PP_InboundBatchItemStage__c item = new PP_InboundBatchItemStage__c(InboundBatch__c = ib.Id);
        item.Federation_Id__c = c.LoginName__c;
        item.First_Name__c = 'Malcolm';
        item.Last_Name__c = 'Reynolds';
        item.Company_Name__c = 'Browncoats';
        item.InboundBatch__c = ib.Id;
        item.Partner_Type__c = 'ISV';
        item.Units_of_Credit__c = batch.Max_Units__c;
        item.Partner__c = c.AccountId;
        item.Status__c = 'Partial Matched';
        item.Create_Contact__c = true;
        item.When_Earned__c = System.now();
        insert item;

        ib.Status__c = 'Ready';
        update ib;

        PP_Scores__c score = [select Points__c from PP_Scores__c where BatchItemStageRef__c = :item.Id];

        System.assert(score.Points__c == batch.Full_Points__c);

    }

    static testmethod void fullCreditTest() {
        Contact c = [select Id, AccountId, LoginName__c from Contact where Account.IsPartner = True and LoginName__c != null limit 1];

        PP_Catalog__c cat = new PP_Catalog__c(Category__c = 'Bulk Uploads');
        insert cat;

        PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 76, Partial_Points__c = 10, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Red Hat Summit');
        insert batch;

        PP_InboundBatchStage__c ib = new PP_InboundBatchStage__c(Batch__c = batch.Id, Super_Region__c = 'NA');
        insert ib;

        PP_InboundBatchItemStage__c item = new PP_InboundBatchItemStage__c(InboundBatch__c = ib.Id);
        item.Federation_Id__c = c.LoginName__c;
        item.First_Name__c = 'Malcolm';
        item.Last_Name__c = 'Reynolds';
        item.Company_Name__c = 'Browncoats';
        item.InboundBatch__c = ib.Id;
        item.Partner_Type__c = 'ISV';
        item.Units_of_Credit__c = batch.Max_Units__c;
        item.Contact__c = c.Id;
        item.Partner__c = c.AccountId;
        item.Status__c = 'Matched';
        insert item;

        ib.Status__c = 'Ready';
        update ib;
//      PPBatchPlugin p = new PPBatchPlugin();
//      p.scoreBatch(ib.Id);

//        PP_Scores__c score = [select Points__c from PP_Scores__c where Contact__c = :c.Id and BatchItemStageRef__c = :item.Id];

//        System.assert(score.Points__c == batch.Full_Points__c);

    }

    static testmethod void partialCreditTest() {
        Contact c = [select Id, LoginName__c, AccountId from Contact where Account.IsPartner = True and LoginName__c != null limit 1];

        PP_Catalog__c cat = new PP_Catalog__c(Category__c = 'Bulk Uploads');
        insert cat;

        PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 76, Partial_Points__c = 10, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Red Hat Summit');
        insert batch;

        PP_InboundBatchStage__c ib = new PP_InboundBatchStage__c(Batch__c = batch.Id, Super_Region__c = 'NA');
        insert ib;

        PP_InboundBatchItemStage__c item = new PP_InboundBatchItemStage__c(InboundBatch__c = ib.Id);
        item.Federation_Id__c = c.LoginName__c;
        item.First_Name__c = 'Malcolm';
        item.Last_Name__c = 'Reynolds';
        item.Company_Name__c = 'Browncoats';
        item.InboundBatch__c = ib.Id;
        item.Partner_Type__c = 'ISV';
        item.Units_of_Credit__c = batch.Max_Units__c - 1;
        item.Contact__c = c.Id;
        item.Partner__c = c.AccountId;
        item.Status__c = 'Matched';
        insert item;

        ib.Status__c = 'Ready';
        update ib;

//      PPBatchPlugin p = new PPBatchPlugin();
//      p.scoreBatch(ib.Id);

//        PP_Scores__c score = [select Points__c from PP_Scores__c where Contact__c = :c.Id and BatchItemStageRef__c = :item.Id];

//        System.assert(score.Points__c == batch.Partial_Points__c * item.Units_of_Credit__c);

    }}