Global class RHNLogin{
    webservice static void copy(String Role,String OpportunityID,String ContactID){

        OpportunityContactRole obj_OpportunityContactRole=new OpportunityContactRole();
        obj_OpportunityContactRole.Role=Role;
        obj_OpportunityContactRole.ContactId=ContactID;
        obj_OpportunityContactRole.OpportunityId=OpportunityID;
        insert obj_OpportunityContactRole;
        }
}