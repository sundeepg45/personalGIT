global class PPContentSchedulable implements Schedulable {

    static String[] expiringContentLibraries = new List<String> {
        'Red Hat Cloud Microsite',
        'Red Hat RHEL Microsite',
        'Red Hat RHEV Microsite',
        'System Integrators',
        'Asia Pacific',
        'North America',
        'Latin America',
        'Europe, Middle East and Africa',
        'Video Library',
        'Partner Presales/Technical',
        'Distributors'
    };
    
    global void execute(SchedulableContext context) {
        run();
    }
    
    public void run() {
        processContentDownloads();
        expireDocuments();
    }
    
    public void processContentDownloads() {

        DateTime prevMaxDate = null;        
        try {
            AggregateResult[] ar = [select Max(CreatedDate)maxdate from PP_ContentStage__c];
            if (!ar.isEmpty()) {
                prevMaxDate = (DateTime) ar[0].get('maxdate');
            }
        }
        catch (System.Exception ex) {
            // just default to the initialized value for prevMaxDate
        }
        if (prevMaxDate == null) {
            prevMaxDate = System.now().addDays(-1);     
        }
        System.debug('***[debug]**** prevMaxDate=' + prevMaxDate);

        //
        // get all history since last check.
        // note: this list will include non-partner activity so we must filter appropriately.
        //
        ContentVersionHistory[] history = [
            select  Id,
                    ContentVersion.ContentDocumentId,
                    ContentVersion.Title,
                    CreatedById,
                    CreatedDate,
                    ContentVersion.Expiration_Date__c
            from    ContentVersionHistory
            where   CreatedDate > :prevMaxDate
            and     isDeleted = false
            and     Field = 'contentVersionDownloaded'
            order by CreatedDate desc
            limit	500
        ];
        
        System.debug('***[debug]**** history count=' + history.size());
        
        Set<ID> userIdList = new Set<Id>();
        for (ContentVersionHistory h : history) {
            userIdList.add(h.CreatedById);
        }
        
        //
        // create a contact/user map and FILTER OUT non-partner users
        //
        User[] users = [select Id, ContactId, Contact.Account.Global_Region__c from User where Id in :userIdList and Contact.Account.isPartner = True];
        Map<ID,User> userContactMap = new Map<ID,User>();
        for (User u : users) {
            userContactMap.put(u.Id, u);
        }
        
        Set<String> documentIdList = new Set<String>();
        for (ContentVersionHistory h : history) documentIdList.add(h.ContentVersion.ContentDocumentId);
        PP_ContentStage__c[] priors = [
            select  Contact__c, ContentID__c
            from    PP_ContentStage__c
            where   ContentID__c in :documentIdList
            and     Contact__c in :PartnerUtil.getStringFieldSet(users, 'ContactId')
        ];
        
        //
        // Get the scoring associations for the documents downloaded
        //
        PP_Content__c[] scoreitems = [
            select  Id, DocumentId__c, Global_Region__c
            from    PP_Content__c
            where   DocumentId__c in :documentIdList
            and     IsActive__c = true
        ];
        Map<String, PP_Content__c> scoreitemMap = new Map<String, PP_Content__c>();
        for (PP_Content__c item : scoreitems) {
            scoreitemMap.put(item.DocumentId__c + item.Global_Region__c, item);
        }

        Savepoint sp = Database.setSavepoint();
        
        //
        // For each downloaded content history item, record the staging record for valid contacts
        //
        PP_ContentBatchStage__c batch = new PP_ContentBatchStage__c();
        insert batch;
        PP_ContentStage__c[] stagelist = new List<PP_ContentStage__c>();
        Date todayDate = System.today();
        for (ContentVersionHistory h : history) {

            String expdate = h.ContentVersion.Expiration_Date__c;
            if (expdate != null && expdate.length() == 7) {
                Date d = Date.newInstance(Decimal.valueOf(expdate.substring(0, 4)).intValue(), Decimal.valueOf(expdate.substring(5, 7)).intValue(), 1);
                d = d.addMonths(1);
                if (d < todayDate) {
                    continue;
                }
            }

            User contact = userContactMap.get(h.CreatedById);
            if (contact != null) {
                //
                // if the content hasn't been scored, don't record a staging record
                //
                PP_Content__c scoreitem = scoreitemMap.get(h.ContentVersion.ContentDocumentId + contact.Contact.Account.Global_Region__c);
                if (scoreitem == null) {
                    scoreitem = scoreitemMap.get(h.ContentVersion.ContentDocumentId + 'Global');
                    if (scoreitem == null) {
                        continue;
                    }
                }

                // make sure not already in the same batch (dups)
                boolean found = false;
                for (PP_ContentStage__c cs : stagelist) {
                    String docid = h.ContentVersion.ContentDocumentId;
                    docid = docid.substring(0, 15);
                    if (cs.Contact__c == contact.ContactId && cs.ContentID__c.substring(0,15) == docid) {
                        found = true;
                        break;
                    }
                }
                // make sure not already recorded in stage
                for (PP_ContentStage__c prior : priors) {
                    String docid = h.ContentVersion.ContentDocumentId;
                    docid = docid.substring(0, 15);
                    if (prior.Contact__c == contact.ContactId && prior.ContentID__c == h.ContentVersion.ContentDocumentId) {
                        found = true;
                        break;
                    }
                }
                if (found) continue;

                // is a partner user/contact so record this
                PP_ContentStage__c c = new PP_ContentStage__c(ContentBatch__c = batch.Id);
                c.Contact__c = contact.ContactId;
                c.ContentID__c = h.ContentVersion.ContentDocumentId;
                c.ContentVersionHistoryId__c = h.Id;
                c.When_Earned__c = h.CreatedDate;
                if (h.ContentVersion.Title.length() > 80)
                    c.Name = h.ContentVersion.Title.substring(0, 80);
                else
                    c.Name = h.ContentVersion.Title;
                stagelist.add(c);
            }
        }

        if (!stagelist.isEmpty()) {
            insert stagelist;
            batch.Status__c = 'Ready';
            update batch;
        }
        else {
            // Don't record empty batches
            Database.rollback(sp);
        }
    }
    
    public void expireDocuments() {
        ContentWorkspace[] spaces = [select Id from ContentWorkspace where Name in :expiringContentLibraries];
        Date now = System.today();
        String datestr = now.year() + '-';
        if (now.month() < 10) datestr += '0';
        datestr += now.month();
        System.debug('****[debug]**** looking for ' + datestr);
        ContentVersion[] verdocs = [select Id, ContentDocumentId from ContentVersion where Expiration_Date__c < :datestr and Expiration_Date__c != null and IsLatest = true limit 100];
        Set<String> docIdSet = PartnerUtil.getStringFieldSet(verdocs, 'ContentDocumentId');
        ContentWorkspaceDoc[] wsdocs = [select ContentDocumentId from ContentWorkspaceDoc where ContentDocumentId in :docIdSet and ContentWorkspaceId in :PartnerUtil.getIdSet(spaces)];
        docIdSet = PartnerUtil.getStringFieldSet(wsdocs, 'ContentDocumentId');
        if (!verdocs.isEmpty()) {
            ContentDocument[] docs = [select Id from ContentDocument where Id in :docIdSet];
            for (ContentDocument doc : docs) {
                doc.IsArchived = true;
            }
            update docs;
            System.debug('****[debug]**** archived docs: ' + docs.size());
        }
    }
    
    static testmethod void testPendingContent() {
        PPContentSchedulable pi = new PPContentSchedulable();
        pi.run();       
    }
}