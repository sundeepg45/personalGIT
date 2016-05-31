trigger BusinessPlan_ValidateSubmit on SFDC_Channel_Account_Plan__c (before update ) {


List<String> AccountIds = new List<String>();

List<String> BPName = new List<String>();


List<SFDC_Plan_Resource_Association__c> RHTeam= new List<SFDC_Plan_Resource_Association__c>();

List<SFDC_Objective__c> obj= new List<SFDC_Objective__c>(); 

List<String> role= new List<String>();



String errorMessage='';



 for(integer i=0;i<trigger.new.size();i++){



       if(Trigger.new[i].Approval_Status__c=='Pending First Approval' &&  (Trigger.old[i].Approval_Status__c=='Draft' || Trigger.old[i].Approval_Status__c=='Rejected')){

       AccountIds.add(Trigger.new[i].Partner_Name__c);

       BPName.add(Trigger.new[i].Id);

       }



     }



if(AccountIds.size()==0){
    return;
}


RHTeam= [Select Channel_Plan__c, Role__c from SFDC_Plan_Resource_Association__c where Channel_Plan__c IN:BPName];

obj=[Select Id from SFDC_Objective__c where Channel_Plan__c IN:BPName ];



boolean CAMPresent1=false;
boolean CAMPresent2=false;
boolean CAMPresent3=false;
boolean CAMPresent4=false;

Integer count=0;

for(SFDC_Channel_Account_Plan__c bp: Trigger.new){

 
   for(Integer i=0;i<RHTeam.size();i++)
   {
    if(RHTeam[i].Role__c=='Channel Account Manager')
        {
        CAMPresent1=true;
        }
    if(RHTeam[i].Role__c=='Key Partner Executive')
        {
        CAMPresent2=true;
        }
        
    if(RHTeam[i].Role__c=='Account Champion Partner Executive')
        {
        CAMPresent3=true;   
        }

    if(RHTeam[i].Role__c=='Business Planning Partner Participant')
        {
        CAMPresent4=true;   
        }

                
   }



            if(CAMPresent1==false)

            {

                errorMessage =errorMessage + '\n'+ System.Label.BusinessPlan_ErrorResourceCAMIsMissing;       

            }
    
       if(CAMPresent2==false)

            {

                errorMessage =errorMessage + '\n'+ System.Label.BusinessPlan_ErrorResourceKeyPartnerExecutiveIsMissing;       

            }

       if(CAMPresent3==false)

            {

                errorMessage =errorMessage + '\n'+ System.Label.BusinessPlan_ErrorResourceAccountChamptionIsMissing;       

            }

        if(CAMPresent4==false)

            {

                errorMessage =errorMessage + '\n'+ System.Label.BusinessPlan_ErrorResourcePlanningPartnerIsMissing;       

            }


            if(obj.size()<=0)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorObjectiveIsMissing;

            }





            if(bp.Responsible_Red_Hat_Account_Manager__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorAccountTeamCAMIsMissing;

            }

             

            if(bp.ICAM__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorAccountTeamICAMIsMissing;

            }

             
            if(bp.Sales_Reps__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorSalesRepsIsMissing;

            }
             

             if(bp.Plan_Date__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorPickPlanYearIsMissing;

            }



            if(bp.Partner_Red_Hat_Offerings__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorPartnerRedHatOfferingsIsMissing;

            }



            if(bp.Red_Hat_Trained_Sales__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorRedHatTrainedSalesIsMissing;

            }



            if(bp.Red_Hat_Trained_Engineers__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorRedHatTrainedEngineersIsMissing;

            }



            if(bp.Employees__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorEmployeesIsMissing;

            }

            if(bp.Partner_Priorities__c==null)

            {

                errorMessage = errorMessage + '\n'+ System.Label.BusinessPlan_ErrorPartnerPrioritiesIsMissing;

            }



              

              if(errorMessage !='' || bp.Active__c == false){

                

                errorMessage = errorMessage + '\n'+'\n'+'\n'+System.Label.BusinessPlan_ErrorUseBackButton;
                if(bp.Active__c)
                bp.addError(errorMessage);
                else 
                bp.addError(System.Label.BusinessPlan_ErrorIsInactive);

              }

    }

/*
 * This code should be tested and implemented when possible.
 *
 *
 
    for(SFDC_Channel_Account_Plan__c businessPlan : Trigger.new) {
        SFDC_Channel_Account_Plan__c businessPlanOld = Trigger.oldMap.get(businessPlan.Id);
        
        if (businessPlan.Approval_Status__c !='Pending First Approval')
            continue; 
        else
            System.debug(businessPlan.Id + ': Ok! Approval Status is Pending First Approval');
            
        if (businessPlanOld.Approval_Status__c !='Draft' && businessPlanOld.Approval_Status__c !='Rejected')
            continue;
        else
            System.debug(businessPlan.Id + ': Ok! Old Approval Status is not Draft and not Rejected');

        if(businessPlan.Active__c == false) {
            businessPlan.addError (System.Label.BusinessPlan_ErrorIsInactive);
            continue;
        }

        boolean CAMPresent1 = false;
        boolean CAMPresent2 = false;
        boolean CAMPresent3 = false;
        boolean CAMPresent4 = false;
    
        for (SFDC_Plan_Resource_Association__c teamMember : [
            select Channel_Plan__c
                 , Role__c
              from SFDC_Plan_Resource_Association__c 
             where Channel_Plan__c = :businessPlan.Id
        ]) {
            if(teamMember.Role__c == 'Channel Account Manager')
                CAMPresent1 = true;
            if(teamMember.Role__c == 'Key Partner Executive')
                CAMPresent2 = true;
            if(teamMember.Role__c == 'Account Champion Partner Executive')
                CAMPresent3 = true;   
            if(teamMember.Role__c == 'Business Planning Partner Participant')
                CAMPresent4 = true;   
        }

        if(CAMPresent1 == false)
            businessPlan.addError (System.Label.BusinessPlan_ErrorResourceCAMIsMissing);
        if(CAMPresent2 == false)
            businessPlan.addError (System.Label.BusinessPlan_ErrorResourceKeyPartnerExecutiveIsMissing);
        if(CAMPresent3 == false)
            businessPlan.addError (System.Label.BusinessPlan_ErrorResourceAccountChamptionIsMissing);
        if(CAMPresent4 == false)
            businessPlan.addError (System.Label.BusinessPlan_ErrorResourcePlanningPartnerIsMissing);

        List<SFDC_Objective__c> objectiveList = [
            select Id 
              from SFDC_Objective__c 
             where Channel_Plan__c = :businessPlan.Id 
        ];
    
        if(objectiveList.size() <= 0)
            businessPlan.addError (System.Label.BusinessPlan_ErrorObjectiveIsMissing);

        if(businessPlan.Responsible_Red_Hat_Account_Manager__c == null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorAccountTeamCAMIsMissing);
        if(businessPlan.ICAM__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorAccountTeamICAMIsMissing);

        if(businessPlan.Sales_Reps__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorSalesRepsIsMissing);
        if(businessPlan.Plan_Date__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorPickPlanYearIsMissing);
        if(businessPlan.Partner_Red_Hat_Offerings__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorPartnerRedHatOfferingsIsMissing);
        if(businessPlan.Red_Hat_Trained_Sales__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorRedHatTrainedSalesIsMissing);
        if(businessPlan.Red_Hat_Trained_Engineers__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorRedHatTrainedEngineersIsMissing);
        if(businessPlan.Employees__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorEmployeesIsMissing);
        if(businessPlan.Partner_Priorities__c==null)
            businessPlan.addError (System.Label.BusinessPlan_ErrorPartnerPrioritiesIsMissing);

        // Test failure
        businessPlan.addError ('Ian Zepp: Debugging: Final failure stop.');
    }
    
    */
}