trigger SumTotal_Accreditation on PartnerTraining__c (before insert, before update) {

    if (!ThreadLock.lock('SumTotal_Accreditation')) {
        return;
    }
    Set<String> stidlist = PartnerUtil.getStringFieldSet(Trigger.new, 'SumTotal_Activity_ID__c');
    Map<String,SumTotal_Catalog__c> catalogMap = new Map<String,SumTotal_Catalog__c>();
    for (SumTotal_Catalog__c cat : [
        select  Id, Activity_Name__c, SumTotal_ID__c, Skill__c, Training_Path__r.Track__c, Training_Path__r.Partner_Function__c, Training_Path__r.Product_of_Interest__c
        from    Sumtotal_Catalog__c
        where   SumTotal_ID__c in :stidlist])
    {
        catalogMap.put(cat.SumTotal_ID__c, cat);
    }
    ID trainer = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TRAINING.RED_HAT'].Id;

    for (PartnerTraining__c st : Trigger.new) {
        if (catalogMap.containsKey(st.SumTotal_Activity_ID__c)) {
            SumTotal_Catalog__c cat = catalogMap.get(st.SumTotal_Activity_ID__c);
            st.LMS_Assignment__c = cat.Id;
            if (cat.Training_Path__r != null) {
                st.Track__c = cat.Training_Path__r.Track__c;
                String role = cat.Training_Path__r.Partner_Function__c;
                String solution = cat.Training_Path__r.Product_of_Interest__c;
                if (role == 'Sales' || role == 'Delivery') {
                    st.Accreditation_Name__c = 'Red Hat Accredited ' + role + ' Specialized ' + solution;
                }
                else {
                    st.Accreditation_Name__c = 'Red Hat Accredited ' + role + ' ' + solution;
                }
            }
            st.TrainingType__c = trainer;
            st.RedHatValidated__c = true;
            st.Catalog_Name__c = cat.Activity_Name__c;
            st.Skill__c = cat.Skill__c;
        }

        if (Trigger.isUpdate) {
            PartnerTraining__c old = Trigger.oldMap.get(st.Id);
            if (st.IsActive__c == false && old.IsActive__c == true) {
                st.Date_Expired__c = System.today();
            }
            else if (st.IsActive__c == true && st.Date_Expired__c != null) {
                st.Date_Expired__c = null;
            }
        }
    }
}