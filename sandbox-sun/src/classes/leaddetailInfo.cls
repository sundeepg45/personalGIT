/**
* Class Name:leaddetailInfo
* Author:Accenture
* Description:Used for displaying details of Deal Registration lead on Opportunity.
* Modificaton History:
* Modified By: Ratan Sharma
* Modified date: 4/29/2011
* Reason for Modification: Separated test class from business class.
* Modified By: Scott Coleman <scoleman@redhat.com>
* Modified date: 09/16/2013
* Reason for Modification: Added field Business_Unit__c to Lead query
*/

public class leaddetailInfo{

    Opportunity         objOpp;
    Lead                objLead;
    List<ProcessInstance> leadinstances;
    User                leadUser;
    Boolean             leadExists;
    List<ProcessInstanceStep> leadInstanceStep;

    private final Opportunity oppt;
    String Id;
    String message=null;


    public leaddetailInfo(ApexPages.StandardController con) {
        Id=con.getRecord().id;
        getObjOpp(Id);
        Lead ld = getObjLead(Id);
        if (ld == null) {
            System.debug('*****[debug]***** Lead is NULL');
        }
    }

    public Opportunity getObjOpp(String Id) {
        objOpp = [select Deal_Registration__c, RecordType.Name, Account.Global_Region__c from Opportunity where Id=:Id];
        return objOpp;
    }

    public Opportunity getObjOpp(){
        return objOpp;
    }

    public Lead getObjLead() {
        return objLead;
    }

    public Lead getObjLead(String Id) {

        try {
            objLead = [Select RecordType.Name, Status, Company, Name,  Revenue_Type__c, OwnerId, Title, Deal_Registration_Status__c, Decision_Role__c,  Stage__c,
                      PrimaryJobFunction__c,  ReasonforInboundCall__c, Do_Not_Contact__c, SIC_Code__c, Email, Country_of_Order__c, JBoss_Lead_ID__c,
                      Phone, MobilePhone, Sales_Ops_Reviewed__c, QualifiesForGSASchedule__c, Reasons_for_Rejection__c, Region__c,   Passed_to_Partner__c, Assignment_Error__c,
                      Partner_Led_Lead__c, Account__r.Global_Region__c, Note__c, Comments__c,
                      //Opp Details
                      Deal_ID__c, Deal_Type__c, Competitive_Deal__c, Deal_Registration_Classification__c, Competition__c, Marketing_Program__c,     Marketing_Program_na__c,
                      Competition_Details_if_Other__c, Project_Budgeted__c, Distributor_Quote_Number__c, Distributor__c, Distributor_if_other__c , Deal_Approved_Date__c, Estimated_Close_Date__c, Red_Hat_Subscription_Revenue__c,
                      Red_Hat_Services_Revenue__c, Project_Budget_Amount__c , Days_Left_Until_Expiry__c , Associated_Marketing_Program_Discount__c , Registration_Expiration__c, Red_Hat_Total_Revenue__c,
                      Deal_Registration_Amount__c, Registration_Length_Days__c, PartnerAccount.Name,
                      // Partner Info
                      Reseller_Company_Name__c, Reseller_Email__c , Reseller_First_Name__c, Reseller_Last_Name__c, Value_Added_Sales_Activity__c, Value_Added_Sales_Activity_Description__c,
                      Value_Added_Services_Proposed__c, Value_Added_Services_Proposed_Desc__c, Reseller_Phone__c, Are_you_the_Sales_Rep_for_this_Lead__c, Sales_Rep_Email__c,
                      Sales_Rep_Name__c, Sales_Rep_Phone__c, NumberOfEmployees, I_need_additional_sales_presales_support__c, Partner_Tier_Name__c, Partner_Type_Name__c,Contact_First_and_Last_Name__c, Contact_email__c, Contact_Phone__c,
                      Red_Hat_can_contact_the_Customer__c, Partner_Program_Participation__c, Partner_Full_Name__c, Partner_Account_Name__c, PartnerAccount.BillingCountry, PartnerAccount.Owner.Name, PartnerAccount.PartnerStatuses__c, Are_You_a_Red_Hat_Distributor__c ,
                      //Partner Lead Conversion Info
                      Sales_Stage__c, Partner_Comments__c, JBoss_Products__c, RHEV_Products__c, RHEL_Products__c, Cloud_Products__c,
                      //Lead Notes
                      Details_from_Lead__c, LeadSourceDetail__c,
                      //Qualification Criteria
                      AnnualRevenue,NumberOfEmployeesInWWOrg__c, Website, Fax,
                      // Lead Qualification Criteria
                      Industry, EstAnnualRevForWWOrg__c, LeadSource, NumberOfServerClassSystemsInWWOrg__c, Number_of_Employees__c, PurchasingHWWithThisDeployment__c, PreferredHWVendor__c,
                      OtherHWVendor__c, LeadSourceDescription__c , PartnerProvidedLead__c, Purchasing_Services_with_this_Deployment__c, Estimated_Value_of_Services__c,
                      //Address
                      Street, City, State, Country,
                      //Workloads
                      WorkloadsDeployedDeployingOnLinux__c,
                      // Project Description
                      Project_Description__c, Products_of_Interest__c,Red_Hat_Products_SKU_Quantity__c,
                      //Oracle Information
                      Oracle_Account_Number__c, RHNLogin__c,
                      //Preferred Purchasing Method
                      PreferredPurchasingMethod__c,
                      // financials
                      Budget__c, Authority__c, Need__c, Time_Frame__c,
                      // Lead conversion wizard
                      Business_Unit__c,
                      // Special Deal Type,
                      Special_Deal_Type__c,
                      Isconverted, CreatedById, LastModifiedById   from Lead Where ConvertedOpportunityId= : Id];

            return objLead;
        }
        catch(Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'This opportunity did not come from a lead');
            ApexPages.addMessage(myMsg);
            return null;
        }

    }

    public Boolean isEMEA {
        get {
            if (objOpp == null) return false;
//          return objOpp.Account.Global_Region__c == 'EMEA';
            return objOpp.RecordType.Name.startsWith('EMEA');
        }
    }

    public Boolean isLATAM {
        get {
            if (objOpp == null) return false;
//          return objOpp.Account.Global_Region__c == 'LATAM';
            return objOpp.RecordType.Name.startsWith('LATAM');
        }
    }

    public User getLeadUser()
    {
        try {
            If (objLead.id <> null) {
                leadUser = [Select Name, Id from User where Id =: objLead.OwnerId];
                return leadUser;
            }
            else {
                ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.INFO,'This opportunity did not came from a lead');
                return null;
            }
        }
        catch(Exception e) {
            ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.INFO,'This opportunity did not came from a lead');
            leadExists = FALSE;
            return null;
        }
    }

    public List<ProcessInstance> getLeadInstances() {
        try {
            leadinstances = [Select Status, Id, TargetObjectId from ProcessInstance where TargetObjectId =: objLead.Id];
            return leadinstances;
        }
        catch(Exception e) {
            ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.INFO,'This opportunity did not come from a lead');
            return null;
        }
    }

    public List<ProcessInstanceStep> getLeadInstanceStep() {
        try {
            getLeadInstances();
            leadInstanceStep = [
                select Comments, StepStatus, ActorId, CreatedDate
                from    ProcessInstanceStep
                where   ProcessInstanceId in :leadinstances order by CreatedDate desc
            ];
            return leadInstanceStep;
        }
        catch(Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'This opportunity did not came from a lead');
            return null;
        }
    }

}