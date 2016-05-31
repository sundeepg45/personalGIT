public without sharing class Partner_State_Wrapper {

    private static Map<ID,Partner_State__c> partnerStateCache;

    //
    // Business methods
    //
    public static Boolean isLegalBlocked(ID accountId) {
        Partner_State__c state = get(accountId);
        return state == null ? false : state.Legal_Blocked__c;
    }

    public static void setLegalBlocked(ID accountId, Boolean blocked) {
        Partner_State__c state = get(accountId);
        if (state == null) {
            if (blocked) {
                System.debug('Account Id: ' + accountId);
                state = new Partner_State__c(Account__c = accountId, Legal_Blocked__c = true);
                add(state);
            }
        }
        else {
            state.Legal_Blocked__c = blocked;
        }
    }

    public static Boolean isRequalLockoutExempt(ID accountId) {
        Partner_State__c state = get(accountId);
        return state == null ? false : state.Requal_Lockout_Exempt__c;
    }

    //
    // caching methods
    //
    public static void load(Set<String> accountIdList) {
        ID[] idlist = new List<ID>();
        for (String s : accountIdList) idlist.add((ID) s);
        load(idlist);
    }

    public static void load(List<ID> accountIdList) {
        if (partnerStateCache == null) {
            partnerStateCache = new Map<ID,Partner_State__c>();
        }

        //
        // Determine if some of the requested ones are already in the cache and avoid reloading those.
        //
        Set<ID> requestedSet = new Set<ID>(accountIdList);
        requestedSet.removeAll(partnerStateCache.keySet());

        if (!requestedSet.isEmpty()) {
            Partner_State__c[] states = [
                select  Id, Legal_Blocked__c, Account__c, Requal_Lockout_Exempt__c
                from    Partner_State__c
                where   Account__c in :requestedSet
            ];
            for (Partner_State__c state : states) {
                if (state != null) {
                    partnerStateCache.put(state.Account__c, state);
                }
            }
        }
    }

    public static void add(Partner_State__c state) {
            partnerStateCache.put(state.Account__c, state);
    }

    public static void commitCache() {
        if (partnerStateCache != null && !partnerStateCache.isEmpty()) {
            for (Id key : partnerStateCache.keySet()) {
                System.debug('key: ' + key);
                System.debug('partner state: ' + partnerStateCache.get(key));
            }
            //
            // since null is a valid key value in the cache we need to filter them out before DML
            //
            List<Partner_State__c> upsertlist = new List<Partner_State__c>();
            for (Partner_State__c ps : partnerStateCache.values()) {
                if (ps != null) upsertlist.add(ps);
            }
            upsert upsertlist;
        }
    }

    //
    // lookups
    //

    public static Partner_State__c get(ID accountId) {
        if (partnerStateCache == null) {
            partnerStateCache = new Map<ID,Partner_State__c>();
        }
        if (partnerStateCache.containsKey(accountId)) {
            return partnerStateCache.get(accountId);
        }
        Partner_State__c[] states = [
            select  Id, Legal_Blocked__c, Account__c, Requal_Lockout_Exempt__c
            from    Partner_State__c
            where   Account__c = :accountId
        ];
        if (states.isEmpty()) {
            partnerStateCache.put(accountId, null);
            return null;
        }
        partnerStateCache.put(accountId, states.get(0));
        return states.get(0);
    }

    //
    // one-off helpers (also maintain cache state)
    //

    public static void updatePartnerStates(Partner_State__c[] states) {
        if (partnerStateCache == null) {
            partnerStateCache = new Map<ID,Partner_State__c>();
        }
        for (Partner_State__c state : states) {
            partnerStateCache.put(state.Account__c, state);
        }
        update states;
    }
}