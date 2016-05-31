trigger Contract_After on Contract (after insert, after update) {
    Map<ID,Contract> filteredOldMap = new Map<ID,Contract>();
    Map<ID,Contract> filteredNewMap = new Map<ID,Contract>();
    ID partnerRecordTypeId = [select Id from RecordType where SObjectType = 'Contract' and DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE].Id;

    for (Contract contract : Trigger.new) {
        if (contract.RecordTypeId != partnerRecordTypeId) {
            filteredNewMap.put(contract.Id, contract);
            if (Trigger.isUpdate) {
                filteredOldMap.put(contract.Id, Trigger.oldMap.get(contract.Id));
            }
        }
        else {
            System.debug('************************ skipping partner contract');
        }
    }
	ContractTriggerAfter.processTrigger(filteredOldMap, filteredNewMap);
}