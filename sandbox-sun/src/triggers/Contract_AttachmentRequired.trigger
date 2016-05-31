/*****************************************************************************************
    Name    :   Contract_AttachmentRequired
    Desc    :   trigger gets fired before a contract update executes the following:
    Actions :   1. Check Attachment is present to complete/approve the Contract


Modification Log :
---------------------------------------------------------------------------
 Developer                Date            Description
---------------------------------------------------------------------------
 Kiran Ravikanti        09/29/2015      Created.
 Kiran Ravikanti        02/26/2016      Updated to make rejection reason
                                        required for Embedded Contracts (US79750)

******************************************************************************************/

trigger Contract_AttachmentRequired on Contract (before update) {

    List<Contract> embedContracts = new List<Contract>();
    Set<Id> contractIds = new Set<Id>();
    List<Attachment> attached = new List<Attachment>();
    List<Contract> rejectedContracts = new List<Contract>();
    Id agreementRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();


    //build a list of not completed, embedded contracts
	for (Contract con : Trigger.new) {
        if(con.Status == 'Completed' && con.Status != Trigger.oldMap.get(con.Id).Status && con.Contract_Type__c == 'Embedded Deal') {
            embedContracts.add(con);
            contractIds.add(con.Id);
        }
        if(Trigger.oldMap.get(con.Id).Status != 'Rejected' &&
            con.Status == 'Rejected' &&
            con.RecordTypeId == agreementRecTypeId &&
            con.Contract_Type__c == 'Embedded Deal') {
            rejectedContracts.add(con);
        }
	}

    for (Contract cont :rejectedContracts) {
        if (cont.Rejection_Reason__c == null) {
            cont.addError('Please set the Contract Rejection Reason field before rejecting the contract.');
        }
    }

    if(!embedContracts.isEmpty()){
            attached =  [Select ParentId
                        From Attachment
                        Where ParentId in :contractIds];
    }



    //build a map of contracts whose parent id is a contract
    Map<Id, Attachment> attachmentMap =  new Map<Id, Attachment>();
    for(Attachment att :attached){
        attachmentMap.put(att.ParentId, att);
    }


    //throw an error if the contract do not have an attachment
    if (!embedContracts.isEmpty()) {
        for (Contract contract :embedContracts) {
            Attachment attachment = attachmentMap.get(contract.Id);
            if(attachment == null) {
                contract.addError('Contract can not be Approved. Please attach the terms document and try again');
            }
        }
    }

}