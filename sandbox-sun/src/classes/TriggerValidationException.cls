public with sharing class TriggerValidationException extends Exception {

    public String errorMessage {
        get {
            return ApexPages.currentPage().getParameters().get('message');
        }
    }

    public Id recordId {
        get {
            return ApexPages.currentPage().getParameters().get('record');
        }
    }

    public String recordMessage {
        get {
            return ApexPages.currentPage().getParameters().get('recordmessage');
        }
    }

    public boolean hasRecordId {
        get {
            return (ApexPages.currentPage().getParameters().get('record') != null && ApexPages.currentPage().getParameters().get('record') != '');
        }
    }
}