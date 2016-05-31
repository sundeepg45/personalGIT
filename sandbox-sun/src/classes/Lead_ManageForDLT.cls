public with sharing class Lead_ManageForDLT {
    // Constructor

    public Lead_ManageForDLT() {
        importLeadMapping = new Map<Id, Lead>();
        importSuccessList = new List<Lead>();
        importFailureList = new List<Lead>();
        importAttachment = new Attachment();

        exportCreatedMin = new Task();
        exportCreatedMax = new Task();
        exportLastModifiedMin = new Task();
        exportLastModifiedMax = new Task();
        exportPreview = false;
        exportData = null;
    }
    
    // private vars

    private static Time MIDNIGHT = Time.newInstance(0, 0, 0, 0);
    private static Time JUST_BEFORE_MIDNIGHT = Time.newInstance(23, 59, 59, 999);
    private Integer leadListPrefetchSize = null;    
    
    // helper objects
    
    public Map<Id, Lead> importLeadMapping { get; set; }
    public List<Lead> importSuccessList { get; set; }
    public List<Lead> importFailureList { get; set; }
    public Attachment importAttachment { get; set; }

    public Task exportCreatedMin { get; set; }
    public Task exportCreatedMax { get; set; }
    public Task exportLastModifiedMin { get; set; }
    public Task exportLastModifiedMax { get; set; }
    public Boolean exportPreview { get; set; }
    public String exportLeadSource { get; set; }
    public String exportData { get; set; }
    
    // master list of fields
    
    private List<String> getFieldList() {
        return new List<String> {
            'Id',
            'CreatedDate',
            'LastModifiedDate',
            'Salutation',
            'FirstName',
            'LastName',
            'Title',
            'Company',
            'Street',
            'City',
            'State',
            'PostalCode',
            'Country',
            'Phone',
            'MobilePhone',
            'Email',
            'LeadSourceDetail__c'
        };
    }
    
    public Integer getImportListSize() {
        return importLeadMapping.size();
    }

    public Integer getImportSuccessListSize() {
        return importSuccessList.size();
    }

    public Integer getImportFailureListSize() {
        return importFailureList.size();
    }

    public String getParam(String name) {
        return System.currentPageReference().getParameters().get(name);
    }

    public void putParam(String name, String data) {
        System.currentPageReference().getParameters().put(name, data);
    }

    public Date getMinimumCreatedDate() {
        return exportCreatedMin.ActivityDate == null ? Date.newInstance(2000, 01, 01) : exportCreatedMin.ActivityDate;
    }
    
    public Date getMaximumCreatedDate() {
        return exportCreatedMax.ActivityDate == null ? Date.newInstance(2099, 21, 31) : exportCreatedMax.ActivityDate;
    }
    
    public Date getMinimumLastModifiedDate() {
        return exportLastModifiedMin.ActivityDate == null ? Date.newInstance(2000, 01, 01) : exportLastModifiedMin.ActivityDate;
    }
    
    public Date getMaximumLastModifiedDate() {
        return exportLastModifiedMax.ActivityDate == null ? Date.newInstance(2099, 21, 31) : exportLastModifiedMax.ActivityDate;
    }
    
    public String getLeadSourceDetailIsLike() {
        if (exportLeadSource == '' || exportLeadSource == null)
            return '%';
        return exportLeadSource.replace('*', '%').replace('%%', '%');
    }
    
    public String getLeadSourceDetailIsEqualTo() {
        if (exportLeadSource == '' || exportLeadSource == null)
            return null;
        return '301f63d4699e63a76deb816b3a92c16e'; // some random md5 that should never be matched.
    }
    
    public List<Lead> getLeadList() {
        return [
           select Salutation
                , FirstName
                , LastName
                , Title
                , Company
                , Street
                , City
                , State
                , PostalCode
                , Country
                , Phone
                , MobilePhone
                , Email
                , CreatedDate
                , LastModifiedDate
                , LeadSourceDetail__c
             from Lead 
            where (CreatedDate >= :DateTime.newInstanceGMT(getMinimumCreatedDate(), MIDNIGHT))
              and (CreatedDate <= :DateTime.newInstanceGMT(getMaximumCreatedDate(), JUST_BEFORE_MIDNIGHT))
              and (LastModifiedDate >= :DateTime.newInstanceGMT(getMinimumLastModifiedDate(), MIDNIGHT) or LastModifiedDate = null)
              and (LastModifiedDate <= :DateTime.newInstanceGMT(getMaximumLastModifiedDate(), JUST_BEFORE_MIDNIGHT) or LastModifiedDate = null) 
              and (LeadSourceDetail__c like :getLeadSourceDetailIsLike() or LeadSourceDetail__c = :getLeadSourceDetailIsEqualTo())
              and (IsConverted = false)
         order by Company, LastName, FirstName 
            limit 500
        ];
    } 
    
    public Integer getLeadListPrefetchSize() {
        if (leadListPrefetchSize == null)
            leadListPrefetchSize = [
               select COUNT()
                 from Lead 
                where (CreatedDate >= :DateTime.newInstanceGMT(getMinimumCreatedDate(), MIDNIGHT))
                  and (CreatedDate <= :DateTime.newInstanceGMT(getMaximumCreatedDate(), JUST_BEFORE_MIDNIGHT))
                  and (LastModifiedDate >= :DateTime.newInstanceGMT(getMinimumLastModifiedDate(), MIDNIGHT) or LastModifiedDate = null)
                  and (LastModifiedDate <= :DateTime.newInstanceGMT(getMaximumLastModifiedDate(), JUST_BEFORE_MIDNIGHT) or LastModifiedDate = null) 
                  and (LeadSourceDetail__c like :getLeadSourceDetailIsLike() or LeadSourceDetail__c = :getLeadSourceDetailIsEqualTo())
                  and (IsConverted = false)
                limit 500
            ];
            
        return leadListPrefetchSize;
    }
    
    // page references

    public PageReference exportDocument() {
        try {
            exportData = CSVWriter.process(getLeadList(), getFieldList());
        } catch (System.DmlException dmlException) {
            ApexPages.addMessages(dmlException);
            exportData = null;
        }
        
        return null;
    }

    public PageReference importDocument() {
    	if (importAttachment.Name == null || importAttachment.Name == '')
    	    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a file first.'));
        else if (importAttachment.Body == null)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected file is empty.'));
        else if (importAttachment.Body.toString() == null || importAttachment.Body.toString() == '')
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected file is empty.'));
        else try {
            importLeadMapping.clear();
            importSuccessList.clear();
            importFailureList.clear();
            
            // 
            // Loop through acceptable field names and add
            //
            
            for(Map<String, String> recordMap : CSVReader.process(importAttachment)) {
                Lead lead = new Lead(Id = recordMap.get('Id'));
                
                system.assert(recordMap.containsKey('Id'), 'Id field is missing: ' + recordMap);
                
                for(String field : getFieldList()) { // use internal field list
                    if (field == 'Id') 
                        continue;
                    if (field == 'CreatedDate') 
                        continue;
                    if (field == 'LastModifiedDate') 
                        continue;
                    if (field == 'LeadSourceDetail__c') 
                        continue;
                    lead.put(field, recordMap.get(field));
                }
                
                importLeadMapping.put(lead.Id, lead);
            }
        
            //
            // Execute the update
            //
            
            List<Lead> importLeadList = importLeadMapping.values(); // done to preserve order for the success/failure op
            List<Database.SaveResult> importResultList = Database.update(importLeadList, false);
            
            //
            // Create the list of successes & failures
            //
            
            for(Integer pos = 0; pos < importResultList.size(); pos ++) {
                Database.SaveResult importResult = importResultList.get(pos);
                Lead importLead = importLeadList.get(pos);
                
                if (importResult.isSuccess()) {
                    importSuccessList.add(importLead);
                } else for (Database.Error error : importResult.getErrors()) {
                    importLead.Description = 'Failed: ' + error.getMessage();
                    importFailureList.add(importLead);
                }
            }
        } catch (Exception pException) {
            ApexPages.addMessages(pException);
        } finally {
            importAttachment.Body = null;
        }

        return null;
    }

    public PageReference refreshLeadList() {
        leadListPrefetchSize = null;
        return null;
    }
}