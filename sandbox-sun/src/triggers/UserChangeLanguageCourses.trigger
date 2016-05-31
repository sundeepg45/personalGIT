trigger UserChangeLanguageCourses on User (after update) {
/*
    system.debug('Trigger.old: '+Trigger.old);
    system.debug('Trigger.new: '+Trigger.new);    

    if(Trigger.old[0].LanguageLocaleKey != Trigger.new[0].LanguageLocaleKey){
            Id UserId = Trigger.new[0].id;
            Id usertransId;
            String LngNew = Trigger.new[0].LanguageLocaleKey;
            
            system.debug('LngNew: '+LngNew);
            
            //select the users transcript record    
            for(lmscons__Transcript__c trans : [Select Id from lmscons__Transcript__c where lmscons__Trainee__c =:UserId limit 1])
            {
                usertransId = trans.Id;
            }
            
            system.debug('usertransId: '+usertransId);
            
            if(usertransId != null)
            {
                set<id> tpIds = new set<id>();
                
                //search ex paths
                for(lmscons__Transcript_Line__c a : [select id, lmscons__Training_Path_Item__c, lmscons__Training_Path_Item__r.lmscons__Training_Path__c from lmscons__Transcript_Line__c where lmscons__Transcript__c =: usertransId and lmscons__Training_Path_Item__c!=null]){
                    id tmpId = a.lmscons__Training_Path_Item__r.lmscons__Training_Path__c;
                    tpIds.add(tmpId);
                }

                system.debug('tpIds: '+tpIds);

                //String Role;
                //String Interest;
                
                set<String> RoleInterest = new set<String>();
                
                
                //search matrix role+interest
                for(Role_Interest_Training_Matrix__c ritm : [select id, Role__c, Product_Interest__c from Role_Interest_Training_Matrix__c where T_Path__c IN :tpIds]){
                  //  Role = Role + ritm.Role__c+',';
                    //Interest = Interest + ritm.Product_Interest__c+',';
                    
                    RoleInterest.add(ritm.Role__c+','+ritm.Product_Interest__c);
                    
                }

                system.debug('RoleInterest: '+RoleInterest);


                //Role = Role.substring(0, (Role.length()-1));
                //Interest = Interest.substring(0, (Interest.length()-1));

                String[] Tmp;

                //map<String, Set<Id>> MatrixPathids = new map<String, Set<Id>>();

                Set<Id> paths = new Set<Id>();


                //search new path for selected lng
                for(String ri : RoleInterest){
                    
                    Tmp = ri.split(',', 2);
                    
                    system.debug('Tmp: '+Tmp);

//                    Integer cpath = [select count() from Role_Interest_Training_Matrix__c where T_Path__r.lmscons__Language__c=:LngNew and Role__c=:Tmp[0] and Product_Interest__c=:Tmp[1]];

//                    system.debug('cpath: '+cpath);

                    List<Role_Interest_Training_Matrix__c> ritm2 = new List<Role_Interest_Training_Matrix__c>();

                    try {
                        ritm2 = [select id, Role__c, Product_Interest__c, T_Path__c from Role_Interest_Training_Matrix__c where T_Path__r.lmscons__Language__c=:LngNew and Role__c=:Tmp[0] and Product_Interest__c=:Tmp[1]];
                        if (ritm2.size() == 0) {
                            ritm2 = [select id, Role__c, Product_Interest__c, T_Path__c from Role_Interest_Training_Matrix__c where (T_Path__r.lmscons__Language__c='en_US' or T_Path__r.lmscons__Language__c='en' or T_Path__r.lmscons__Language__c=null) and Role__c=:Tmp[0] and Product_Interest__c=:Tmp[1]];
                        }
                    }
                    catch (QueryException ex) {
                        // ignore
                    }
                    system.debug('ritm2: '+ritm2);
                    
                    for(Role_Interest_Training_Matrix__c r : ritm2){
                        paths.add(r.T_Path__c);
                    }

                    system.debug('paths: '+paths);
                }
                
                Set<Id> oldPathsFilter = new Set<Id>();
                
                Set<Id> newPathsFilter = new Set<Id>();
                
                //filter old paths if no need action
                for(Id tp : tpIds){
                    if(paths.contains(tp)==false){
                        oldPathsFilter.add(tp);
                    }
                }
                
                system.debug('oldPathsFilter: '+oldPathsFilter);
                

                //del old assignment if not started
                List<lmscons__Transcript_Line__c> delOld = [select id, lmscons__Training_User_License__c  from lmscons__Transcript_Line__c where lmscons__Training_Path_Item__r.lmscons__Training_Path__c IN:oldPathsFilter and lmscons__Percent_Complete__c = 0.0 and lmscons__Transcript__c=:usertransId];
                
                set<ID> delLicSet = new set<ID>();
                for(lmscons__Transcript_Line__c d : delOld){
                    delLicSet.add(d.lmscons__Training_User_License__c);
                }
                
                system.debug('delOld: '+delOld);
                lmscons.LMSUtil.AdminOperation = true;
                if(delOld.size()>0){
                    delete delOld;
                }
                
                List<lmscons__Training_User_License__c> delOldLic = [select id from lmscons__Training_User_License__c where id IN :delLicSet];
                if(delOldLic.size()>0){
                    for(lmscons__Training_User_License__c tl : delOldLic){
                        tl.lmscons__Cornerstone_ID__c = null;
                    }
                    update delOldLic;
                }



                //select what the user currently has and load a map of the content ids?
                Set<Id> userCurrentTrainContent = new Set<Id>();
                Map<Id,Id> userCurrentPaths = new Map<Id,Id>();
                for(lmscons__Transcript_Line__c curTL:[Select Id, lmscons__Training_Content__c, lmscons__Training_Path_Item__c, lmscons__Training_Path_Item__r.lmscons__Training_Path__c from lmscons__Transcript_Line__c 
                where lmscons__Training_User_License__r.lmscons__User__c = :UserId])
                {
                    userCurrentTrainContent.add(curTL.lmscons__Training_Content__c);
                    if(curTL.lmscons__Training_Path_Item__c != null && userCurrentPaths.get(curTL.lmscons__Training_Path_Item__r.lmscons__Training_Path__c) == null)
                    {                   
                        userCurrentPaths.put(curTL.lmscons__Training_Path_Item__r.lmscons__Training_Path__c, UserId);
                    }
                    
                }      

                //get all the training path items needed, not ones that are already assigned to user,  load a training content list
                Set<Id> trainContent = new Set<Id>();
                for(lmscons__Training_Path_Item__c tpi:[Select lmscons__Training_Path__r.Name, lmscons__Training_Path__c, lmscons__Training_Content__c
                    From lmscons__Training_Path_Item__c                 
                    where lmscons__Training_Path__c in :paths])             
                {
                    trainContent.add(tpi.lmscons__Training_Content__c);
                }   
                system.debug('trainContent: '+trainContent);
                        
                
                //load a map of the content along with the id of the license
                Map<Id,Id> contentLicenseMap = new Map<Id,Id>();            
                for(lmscons__Training_Content_License__c contLic : [Select lmscons__Training_Content__c, Id 
                    From lmscons__Training_Content_License__c 
                    where lmscons__Training_Content__c in: trainContent])
                {
                    contentLicenseMap.put(contLic.lmscons__Training_Content__c, contLic.Id);
                }

                system.debug('contentLicenseMap: '+contentLicenseMap);

                
                //load all the current users licenses for content
                Map<Id,Id>  userLicenseMap = new Map<Id,Id>();
                for(lmscons__Training_User_License__c userLic: [Select Id, lmscons__Content_License__c
                    From lmscons__Training_User_License__c where lmscons__User__c = :UserId])
                {
                    userLicenseMap.put(userLic.lmscons__Content_License__c, userLic.Id);
                }
                system.debug('userLicenseMap: '+userLicenseMap);
                
                
                for(lmscons__Training_Content_License__c contLic : [Select lmscons__Training_Content__c, Id, lmscons__Expiration_Date__c
                    From lmscons__Training_Content_License__c 
                    where lmscons__Training_Content__c in: trainContent])
                {
                    
                    if(userLicenseMap.get(contLic.Id) == null)
                    {
                        //lmscons.AssignTrainingController.ignoreInsertTranscriptLines = true;
                        
                        system.debug('creating a new userlicense');
                        lmscons__Training_User_License__c uLic = new lmscons__Training_User_License__c();
                        uLic.lmscons__Content_License__c = contLic.Id;
                        uLic.lmscons__User__c = UserId;
                        uLic.lmscons__Expiration__c = contLic.lmscons__Expiration_Date__c;
                        insert uLic;
                        userLicenseMap.put(uLic.lmscons__Content_License__c, uLic.Id);
                        
                    }   
                }
                
                system.debug('userLicenseMap: '+userLicenseMap);

                system.debug('paths ' + paths);
    
                //exclude ex path item
                
                set<id> exTPI = new set<id>();
                
                for(lmscons__Transcript_Line__c tl : [select id, lmscons__Training_Path_Item__c from lmscons__Transcript_Line__c where lmscons__Transcript__c =: usertransId and lmscons__Training_Path_Item__c!=null]){
                    exTPI.add(tl.lmscons__Training_Path_Item__c);
                }
    
                lmscons__Transcript_Line__c[] toinsert = new List<lmscons__Transcript_Line__c>();
                for(lmscons__Training_Path_Item__c tpi : [Select id, lmscons__Training_Path__r.Name, lmscons__Training_Path__c, lmscons__Training_Content__c
                    From lmscons__Training_Path_Item__c                 
                    where lmscons__Training_Path__c in :paths])
                {
                    if(contentLicenseMap.get(tpi.lmscons__Training_Content__c) != null)
                    {   
                        system.debug('trying for this training path: ' + tpi.lmscons__Training_Path__c);
                        //if(userCurrentPaths.get(tpi.lmscons__Training_Path__c) == null)
                        //{
                        if(exTPI.contains(tpi.id)==false){
                            lmscons__Transcript_Line__c tl = new lmscons__Transcript_Line__c();                                 
                            tl.lmscons__Transcript__c = usertransId;
                            tl.lmscons__Training_Path_Item__c = tpi.Id;
                            tl.lmscons__Training_Content__c = tpi.lmscons__Training_Content__c;                     
                            tl.lmscons__Training_User_License__c = userLicenseMap.get(contentLicenseMap.get(tpi.lmscons__Training_Content__c));
                            toinsert.add(tl);
                        }
                    }
                }                
                if (!toinsert.isEmpty()) {
                    insert toinsert;
                }

            }        
    
    }
*/
}