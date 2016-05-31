public class UserAgreementsHelper {

    static public Agreement__c getAgreementForFeature(String language, String featureName) {
        if (language == null || featureName == null) {
            return null;
        }

        String shortLanguage = language;
        if (language.indexOf('_') != -1) {
            shortLanguage = language.split('_').get(0);
        }

        System.debug('*****[debug]***** language=' + language);
        System.debug('*****[debug]***** short language=' + shortLanguage);
        System.debug('*****[debug]***** featureName=' + featureName);


        /*
           TODO: We need to know if feature-level agreements are global, regional, or by country.
           Also need to know if partner type/tier plays any part
        */
        Agreement__c[] alist = [
            select  Id, Name, Feature__c,
                    (select Id, Name from Attachments)
            from    Agreement__c
            where   Feature__c = :featureName
            and     Type__c = 'User'
            and     Language__c in (:language, :shortLanguage, 'en')
            and     Is_Terms_Document__c = True
            order by Language__c desc
        ];

        if (alist.size() > 1) {
            for (Agreement__c agree : alist) {
                if (agree.Language__c == language || agree.Language__c == shortLanguage) {
                    return agree;
                }
            }
        }
        if (alist.size() == 1) {
            return alist.get(0);
        }
        return null;
    }

    static public Boolean hasAcceptedForFeature(ID userid, String feature) {
        User_Agreement__c[] ulist = [
            select  Id
            from    User_Agreement__c
            where   User__c = :userid
            and     Agreement__r.Feature__c = :feature
            and     Accept_Date__c != null
        ];
        return ulist.size() > 0;
    }

    static public User_Agreement__c acceptAgreement(ID userid, ID agreementid) {
        User_Agreement__c ua = new User_Agreement__c(User__c = userid, Agreement__c = agreementid, Accept_Date__c = System.now());
        insert ua;
        return ua;
    }
}