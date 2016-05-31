@isTest(SeeAllData=true)
private class AntiCorruptionAttachmentTest {

    @isTest static void testDelete() {
        Anti_Corruption__c[] aclist = [select Id, Screenshot_Attached__c from Anti_Corruption__c where Screenshot_Attached__c = true limit 50];
        for (Anti_Corruption__c ac : aclist) {
            Attachment[] attlist = [select Id from Attachment where ParentId = :ac.Id];
            if (!attlist.isEmpty()) {
                delete attlist.get(0);
                ac = [select Id, Screenshot_Attached__c from Anti_Corruption__c where Id = :ac.Id];
                System.assert(ac.Screenshot_Attached__c == false,  'Screenshot_Attached__c flag should be false');
                break;
            }
        }
    }


}