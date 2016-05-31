trigger Contract_Before on Contract (before insert, before update) {
    Map<ID,Contract> filteredOldMap = new Map<ID,Contract>();
    List<Contract> filteredNewList = new List<Contract>();
    ID partnerRecordTypeId = [select Id from RecordType where SObjectType = 'Contract' and DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE].Id;
    for (Contract contract : Trigger.new) {
        if (contract.RecordTypeId != partnerRecordTypeId) {
            filteredNewList.add(contract);
            if (Trigger.isUpdate) {
                filteredOldMap.put(contract.Id, Trigger.oldMap.get(contract.Id));
            }
        }
        else {
            System.debug('************************ skipping partner contract');
        }
    }
	ContractTriggerBefore.processTrigger(filteredOldMap, filteredNewList);
}