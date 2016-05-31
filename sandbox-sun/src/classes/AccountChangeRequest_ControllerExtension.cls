/**
 * This class is used for account change requests as part of the account lock process.
 *
 * @version 2013-12-17
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-12-17 - Updated to use API version 29 so the DunsNumber field can be locked.
 */
public with sharing class AccountChangeRequest_ControllerExtension {
    public static final String REVIEWED = 'Reviewed';
    private final AccountChangeRequest__c record;
    private final ApexPages.StandardController stdController;
    private final Integer approvedCount;
    private final Integer rejectedCount;
    public final List<AccountChangeRequestField__c> changeRequestFields;

    public AccountChangeRequest_ControllerExtension(ApexPages.StandardController stdController){
        this.record = (AccountChangeRequest__c)stdController.getRecord();
        this.stdController = stdController;
        // order by does not work for picklist values.  So we must manually sort values.
        Map<String,AccountChangeRequestField__c> m = new Map<String,AccountChangeRequestField__c>();
        this.changeRequestFields = [
            select
                Approved__c,
                ChangeRequest__c,
                BooleanValue__c,
                DateTimeValue__c,
                DateValue__c,
                OriginalBooleanValue__c,
                OriginalDateTimeValue__c,
                OriginalDateValue__c,
                OriginalTextValue__c,
                FieldName__c,
                TextValue__c
            from AccountChangeRequestField__c
            where ChangeRequest__c = :record.Id ];
    }

    public static Map<String, Schema.SObjectField> accountFieldMap {
        get {
            if(accountFieldMap == null) {
                accountFieldMap = Schema.SObjectType.Account.fields.getMap();
            }
            return accountFieldMap;
        }
        set;
    }

    static Map<String, Schema.DescribeFieldResult> accountFieldDescribeResultMap = new Map<String, Schema.DescribeFieldResult>();

    public static Schema.DescribeFieldResult getAccountDescribeFieldResult(String fieldName) {
        Schema.DescribeFieldResult retval = accountFieldDescribeResultMap.get(fieldName);
        if(retval == null) {
            Schema.SObjectField sf = accountFieldMap.get(fieldName);
            if(sf != null) {
                retval = sf.getDescribe();
                accountFieldDescribeResultMap.put(fieldName,retval);
            }
        }
        return retval;
    }

    public static Boolean isDataStatusAccessible {
        get {
            if(isDataStatusAccessible == null) {
                isDataStatusAccessible = getAccountDescribeFieldResult('Data_Status__c').isAccessible();
            }
            return isDataStatusAccessible;
        }
        set;
    }

    public static Boolean isDataStatusUpdateable {
        get {
            if(isDataStatusUpdateable == null) {
                isDataStatusUpdateable = getAccountDescribeFieldResult('Data_Status__c').isUpdateable();
            }
            return isDataStatusUpdateable;
        }
        set;
    }

    public static void putValue(SObject o, String key, Object value, Object referenceValue) {
        if(value instanceof Integer && referenceValue instanceof Integer) {
            o.put(key,(Integer)value);
        }
        else if(value instanceof Decimal && referenceValue instanceof Decimal) {
            o.put(key,(Decimal)value);
        }
        else if(value instanceof Boolean && referenceValue instanceof Boolean) {
            o.put(key,(Boolean)value);
        }
        else if(value instanceof Date && referenceValue instanceof Date) {
            o.put(key,(Date)value);
        }
        else if(value instanceof DateTime && referenceValue instanceof DateTime) {
            o.put(key,(DateTime)value);
        }
        else if(value == null && referenceValue != null) {
            o.put(key,(String)null);
        }
        else {
            o.put(key,value);
        }
    }

    public Map<String,String> accountLookupFieldMap {
        get {
            if(accountLookupFieldMap == null) {
                accountLookupFieldMap = new Map<String,String>();
                for(AccountChangeRequestField__c acrf : changeRequestFields) {
                    Schema.DescribeFieldResult dfr = getAccountDescribeFieldResult(acrf.FieldName__c);
                    System.debug('acrf.FieldName__c='+acrf.FieldName__c+',dfr='+dfr);
                    if(dfr != null && dfr.getSOAPType() == Schema.SOAPType.ID) {
                        String f = null;
                        if(acrf.FieldName__c.endsWith('__c')) {
                            f = acrf.FieldName__c.substring(0,acrf.FieldName__c.length()-1)+'r';
                        }
                        else if(acrf.FieldName__c.endsWith('Id')) {
                            f = acrf.FieldName__c.substring(0,acrf.FieldName__c.length()-2);
                        }
                        System.debug('f='+f+',acrf.FieldName__c='+acrf.FieldName__c+',dfr='+dfr);
                        if(f != null) {
                            accountLookupFieldMap.put(acrf.FieldName__c,f);
                        }
                    }
                }
                System.debug('accountLookupFieldMap='+accountLookupFieldMap);
            }
            return accountLookupFieldMap;
        }
        set;
    }

    String accountQuery {
        get {
            if(accountQuery == null) {
                accountQuery = 'select Id';
                for(AccountChangeRequestField__c acrf : changeRequestFields) {
                    accountQuery += ',' + acrf.FieldName__c;
                }
                for(String f : accountLookupFieldMap.values()) {
                    accountQuery += ','+f+'.Name';
                }
                accountQuery += ' from Account where Id = \''+record.Account__c+'\'';
            }
            return accountQuery;
        }
        set;
    }

    private Boolean needUpdate = false;

    public PageReference updateRefAccount() {
        if(refAccount != null) {
            if(needUpdate) {
                System.Savepoint sp = Database.setSavepoint();
                try {
                    update refAccount;
                    refAccount = (Account)Database.query(accountQuery).get(0);
                }
                catch(Exception e) {
                    ApexPages.addMessages(e);
                }
                finally {
                    Database.rollback(sp);
                }
                System.debug('refAccount='+refAccount);
                approvedChanges = null;
                pendingChanges = null;
                rejectedChanges = null;
            }
        }
        return null;
    }

    public Account account {
        get {
            if(account == null) {
                account = (Account)Database.query(accountQuery).get(0);
                System.debug('account='+account);
            }
            return account;
        }
        set;
    }

    public Account refAccount {
        get {
            if(refAccount == null) {
                needUpdate = false;
                refAccount = new Account(Id=record.Account__c);
                for(AccountChangeRequestField__c acrf : changeRequestFields) {
                    String f = accountLookupFieldMap.get(acrf.FieldName__c);
                    if(f != null) {
                        // This is an SObject Id, such as OwnerId.
                        refAccount.put(acrf.FieldName__c,(String)acrf.TextValue__c);
                        System.debug('assign refAccount.'+acrf.FieldName__c+'='+acrf.TextValue__c);
                        // We will need to do an update an a query to find out the name of the SObject.
                        needUpdate = true;
                    }
                    else {
                        Schema.DescribeFieldResult dfr = getAccountDescribeFieldResult(acrf.FieldName__c);
                        Schema.SOAPType st = dfr.getSOAPType();
                        if(st == Schema.SOAPType.Boolean) {
                            refAccount.put(acrf.FieldName__c,acrf.BooleanValue__c);
                        }
                        else if(st == Schema.SOAPType.Date) {
                            refAccount.put(acrf.FieldName__c,acrf.DateValue__c);
                        }
                        else if(st == Schema.SOAPType.DateTime) {
                            refAccount.put(acrf.FieldName__c,acrf.DateTimeValue__c);
                        }
                        else if(st == Schema.SOAPType.Double) {
                            Decimal value = null;
                            if(acrf.TextValue__c != null) {
                                value = Decimal.valueof(acrf.TextValue__c);
                                value.setScale(dfr.getScale());
                            }
                            refAccount.put(acrf.FieldName__c,value);
                        }
                        else if(st == Schema.SOAPType.Integer) {
                            Integer value = null;
                            if(acrf.TextValue__c != null) {
                                value = Integer.valueof(acrf.TextValue__c);
                            }
                            refAccount.put(acrf.FieldName__c,value);
                        }
                        else {
                            refAccount.put(acrf.FieldName__c,acrf.TextValue__c);
                        }
                    }
                }
                System.debug('refAccount='+refAccount);
            }
            return refAccount;
        }
        set;
    }

    public Boolean isReviewed {
        get {
            return (record.Status__c == REVIEWED);
        }
    }

    public Boolean isEdit {
        get {
            return (!isReviewed)&&isDataStatusUpdateable;
        }
    }

    private List<Change> sortChanges(List<Change> changes) {
        List<String> labels = new List<String>();
        Map<String,List<Change>> m = new Map<String,List<Change>>();
        for(Change c : changes) {
            labels.add(c.label);
            List<Change> cl = m.get(c.label);
            if(cl == null) {
                cl = new List<Change>();
                m.put(c.label,cl);
            }
            cl.add(c);
        }
        changes.clear();
        labels.sort();
        for(String label : labels) {
            changes.addAll(m.get(label));
        }
        return changes;
    }

    public List<Change> pendingChanges {
        get {
            if(pendingChanges == null) {
                List<Change> changes = new List<Change>();
                if(! isReviewed) {
                    for(AccountChangeRequestField__c acrf : changeRequestFields) {
                        changes.add(new Change(this,acrf));
                    }
                }
                pendingChanges = sortChanges(changes);
            }
            return pendingChanges;
        }
        set;
    }

    public Integer getPendingChangeCount() {
        return pendingChanges.size();
    }

    public List<Change> approvedChanges {
        get {
            if(approvedChanges == null) {
                List<Change> changes = new List<Change>();
                if(isReviewed) {
                    for(AccountChangeRequestField__c acrf : changeRequestFields) {
                        if(acrf.Approved__c == true) {
                            changes.add(new Change(this,acrf));
                        }
                    }
                }
                approvedChanges = sortChanges(changes);
            }
            return approvedChanges;
        }
        set;
    }

    public Integer getApprovedChangeCount() {
        return approvedChanges.size();
    }

    public List<Change> rejectedChanges {
        get {
            if(rejectedChanges == null) {
                List<Change> changes = new List<Change>();
                if(isReviewed) {
                    for(AccountChangeRequestField__c acrf : changeRequestFields) {
                        if(acrf.Approved__c != true) {
                            changes.add(new Change(this,acrf));
                        }
                    }
                }
                rejectedChanges = sortChanges(changes);
            }
            return rejectedChanges;
        }
        set;
    }

    public Integer getRejectedChangeCount() {
        return rejectedChanges.size();
    }

    public PageReference cancel() {
        return new PageReference('/'+record.Account__c);
    }

    public PageReference save() {
        PageReference retval = null;
        System.Savepoint sp = null;
        try {
            sp = Database.setSavepoint();
            Account a = new Account(Id=account.Id);
            List<AccountChangeRequestField__c> acrfs = new List<AccountChangeRequestField__c>();
            for(Change c : pendingChanges) {
                if(c.accountChangeRequestField.Approved__c) {
                    acrfs.add(c.accountChangeRequestField);
                    putValue(a,c.accountChangeRequestField.FieldName__c,c.newValue,c.oldValue);
                }
            }
            a.Data_Status__c = AccountTriggerBefore.LOCKED;
            AccountChangeRequest__c acr = record.clone(true);
            acr.Status__c = REVIEWED;
            Double hoursToReview = 0;
            try {
                hoursToReview = Double.valueOf(DateTime.now().getTime() - record.CreatedDate.getTime())/3600000.0;
            }
            catch(Exception ignored) {}
            acr.Hours_to_Review__c = hoursToReview;
            update acr;
            if(! acrfs.isEmpty()) {
                update acrfs;
            }
            //update a;
            retval = new PageReference('/'+record.Account__c);
        }
        catch(Exception e) {
            if(sp != null) {
                Database.rollback(sp);
            }
            ApexPages.addMessages(e);
        }
        return retval;
    }

    public class Change {
        Change(AccountChangeRequest_ControllerExtension parent, AccountChangeRequestField__c acrf) {
            accountChangeRequestField = acrf;
            Account account = parent.account;
            Account refAccount = parent.refAccount;
            oldValue = account.get(acrf.FieldName__c);
            oldTextValue = String.valueof(oldValue);
            if(parent.isReviewed) {
                oldTextValue = acrf.OriginalTextValue__c;
            }
            newValue = refAccount.get(acrf.FieldName__c);
            newTextValue = String.valueof(newValue);
            Schema.DescribeFieldResult dfr = getAccountDescribeFieldResult(acrf.FieldName__c);
            Schema.DisplayType t = dfr.getType();
            displayType = t.name();
            label = dfr.getLabel();
            old = new AccountChangeRequestField__c(TextValue__c=oldTextValue);
            String lookupField = parent.accountLookupFieldMap.get(acrf.FieldName__c);
            if(lookupField != null) {
                if(label.toUpperCase().endsWith(' ID')) {
                    label = label.substring(0,label.length()-3);
                }
                oldReference = account.getSObject(lookupField);
                if(oldReference != null) {
                    oldName = (String)oldReference.get('Name');
                }
                newReference = refAccount.getSObject(lookupField);
                if(newReference != null) {
                    newName = (String)newReference.get('Name');
                }
            }
            else if(oldValue instanceof Date && newValue instanceof Date) {
                old = new AccountChangeRequestField__c(TextValue__c=oldTextValue,DateValue__c=(Date)oldValue);
            }
            else if(oldValue instanceof DateTime && newValue instanceof DateTime) {
                old = new AccountChangeRequestField__c(TextValue__c=oldTextValue,DateTimeValue__c=(DateTime)oldValue);
            }
            else if(t == Schema.DisplayType.Picklist || t == Schema.DisplayType.MultiPicklist) {
                Map<String,String> labelMap = new Map<String,String>();
                for(Schema.PicklistEntry ple : dfr.getPicklistValues()) {
                    labelMap.put(ple.getValue(),ple.getLabel());
                }
                List<String> values;
                if(oldTextValue != null) {
                    values = oldTextValue.split('\\s*;\\s*');
                    String sep='';
                    oldTextValue='';
                    for( String value : values) {
                        String label = labelMap.get(value);
                        if(label != null) {
                            value = label;
                        }
                        oldTextValue += sep+value;
                        sep='; ';
                    }
                }
                if(newTextValue != null) {
                    values = newTextValue.split('\\s*;\\s*');
                    String sep='';
                    newTextValue='';
                    for( String value : values) {
                        String label = labelMap.get(value);
                        if(label != null) {
                            value = label;
                        }
                        newTextValue += sep+value;
                        sep='; ';
                    }
                }
            }
        }

        public AccountChangeRequestField__c accountChangeRequestField {
            get;
            set;
        }

        public AccountChangeRequestField__c old {
            get;
            set;
        }

        public String label {
            get;
            set;
        }

        public String displayType {
            get;
            set;
        }

        public SObject oldReference {
            get;
            set;
        }

        public SObject newReference {
            get;
            set;
        }

        public String oldName {
            get;
            set;
        }

        public String newName {
            get;
            set;
        }

        public Object oldValue {
            get;
            set;
        }

        public Object newValue {
            get;
            set;
        }

        public String oldTextValue {
            get;
            set;
        }

        public String newTextValue {
            get;
            set;
        }
    }
}