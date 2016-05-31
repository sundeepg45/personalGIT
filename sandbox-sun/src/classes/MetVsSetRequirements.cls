public class MetVsSetRequirements {

    // This map contains all of the region/status combinations and the base # of required accredited users of each type.
    public map<String, Map<String,Integer>> baseRoleRequirements;

    // These maps are the sub-maps in the baseRoleRequirements map.
    public map<String,Integer> NA_Affiliated;
    public map<String,Integer> NA_Ready;
    public map<String,Integer> NA_Advanced;
    public map<String,Integer> NA_Premier;
    public map<String,Integer> EMEA_Affiliated;
    public map<String,Integer> EMEA_Ready;
    public map<String,Integer> EMEA_Advanced;
    public map<String,Integer> EMEA_Premier;
    public map<String,Integer> LATAM_Affiliated;
    public map<String,Integer> LATAM_Ready;
    public map<String,Integer> LATAM_Advanced;
    public map<String,Integer> LATAM_Premier;
    public map<String,Integer> APAC_Affiliated;
    public map<String,Integer> APAC_Ready;
    public map<String,Integer> APAC_Advanced;
    public map<String,Integer> APAC_Premier;
    public Integer accountRevenue;
    public String region;

    private Map<string, List<RequalMetVsSetRequirements__c>> mvsRegionMap;


    public MetVsSetRequirements(Account acc){
        region = acc.Global_Region__c;
        loadConfig();
        populateMaps();
        accountRevenue = calculateRevenue(acc);
    }


    // Loads the MetVsSet requirements from custom settings
    private void loadConfig(){
        Map<string, RequalMetVsSetRequirements__c> mvs = RequalMetVsSetRequirements__c.getAll();
        mvsRegionMap = new Map<string, List<RequalMetVsSetRequirements__c>>();
        for(RequalMetVsSetRequirements__c r:mvs.values()){
            List<RequalMetVsSetRequirements__c> mvsList = new List<RequalMetVsSetRequirements__c>();
            if(mvsRegionMap.containsKey(r.Region__c)){
                mvsList = mvsRegionMap.get(r.Region__c);
            }
            mvsList.add(r);
            mvsRegionMap.put(r.Region__c, mvsList);
        }
        
    }


    //Clears the existing map and re-populates the values in case they have
    //been changed since the last time they were populated.
    void populateMaps(){
        baseRoleRequirements = new Map<String,Map<String,Integer>>();
        if(region=='LATAM'){
            populateLATAM();
        }else if(region=='EMEA'){
            populateEMEA();
        }else if(region=='APAC'){
            populateAPAC();
        }else{
            populateNA();
        }
    }

    

    // One method for each region.  Clears the existing map to catch updates and
    // then calls the putValues method to insert all of the values at once
    // when creating the maps.
    void populateNA(){
        NA_Affiliated = new Map<String, Integer>();
        NA_Ready = new Map<String, Integer>();
        NA_Advanced = new Map<String, Integer>();
        NA_Premier = new Map<String, Integer>();

        for(RequalMetVsSetRequirements__c r: mvsRegionMap.get('NA')){
            system.debug('NA requirement for [' + r.Partner_Tier__c + ']: ' + r);
            if(r.Partner_Tier__c == 'Affiliated'){
                putValues(NA_Affiliated, r);
                baseRoleRequirements.put('NA_Affiliated',NA_Affiliated);
            } else if(r.Partner_Tier__c == 'Ready'){
                putValues(NA_Ready, r);
                baseRoleRequirements.put('NA_Ready',NA_Ready);
            } else if(r.Partner_Tier__c == 'Advanced'){
                putValues(NA_Advanced, r);
                baseRoleRequirements.put('NA_Advanced',NA_Advanced);
            } else if(r.Partner_Tier__c == 'Premier'){
                putValues(NA_Premier, r);
                baseRoleRequirements.put('NA_Premier',NA_Premier);
            } else {
                system.debug('ERROR: Region undefined: ' + region + '. No Met Vs Set Requirements defined in custom settings for this region!');
                return;
            }
        }
        /*
        putValues(NA_Affiliated,0,0,0,2,0,0,0,0,0);
        putValues(NA_Ready,1,0,0,0,1,0,1,0,0);
        baseRoleRequirements.put('NA_Ready',NA_Ready);
        putValues(NA_Advanced,2,1,1,0,1,1,2,1,1);
        baseRoleRequirements.put('NA_Advanced',NA_Advanced);
        putValues(NA_Premier,4,2,2,0,2,2,4,2,2);
        baseRoleRequirements.put('NA_Premier',NA_Premier);
        */
    }

    void populateAPAC(){
        APAC_Affiliated = new Map<String, Integer>();
        APAC_Ready = new Map<String, Integer>();
        APAC_Advanced = new Map<String, Integer>();
        APAC_Premier = new Map<String, Integer>();
        
        /*
        putValues(APAC_Affiliated,0,0,0,2,0,0,0,0,0);
        baseRoleRequirements.put('APAC_Affiliated',APAC_Affiliated);
        putValues(APAC_Ready,1,1,0,0,1,0,0,0,0);
        baseRoleRequirements.put('APAC_Ready',APAC_Ready);
        //guidelines say "per business plan & commit" for the revenue additions.
        //need clarification on how that needs to work.
        putValues(APAC_Advanced,4,2,2,0,1,1,0,0,0);
        baseRoleRequirements.put('APAC_Advanced',APAC_Advanced);
        //per bp & c
        putValues(APAC_Premier,5,5,5,0,2,2,0,0,0);
        baseRoleRequirements.put('APAC_Premier',APAC_Premier);
        */
        
         
        for(RequalMetVsSetRequirements__c r: mvsRegionMap.get('APAC')){
            system.debug('APAC requirement for [' + r.Partner_Tier__c + ']: ' + r);
            if(r.Partner_Tier__c == 'Affiliated'){
                putValues(APAC_Affiliated, r);
                baseRoleRequirements.put('APAC_Affiliated',APAC_Affiliated);
            } else if(r.Partner_Tier__c == 'Ready'){
                putValues(APAC_Ready, r);
                baseRoleRequirements.put('APAC_Ready',APAC_Ready);
            } else if(r.Partner_Tier__c == 'Advanced'){
                putValues(APAC_Advanced, r);
                baseRoleRequirements.put('APAC_Advanced',APAC_Advanced);
            } else if(r.Partner_Tier__c == 'Premier'){
                putValues(APAC_Premier, r);
                baseRoleRequirements.put('APAC_Premier',APAC_Premier);
            } else {
                system.debug('ERROR: Region undefined: ' + region + '. No Met Vs Set Requirements defined in custom settings for this region!');
                return;
            }
        }
        
    }

    void populateEMEA(){
        EMEA_Affiliated = new Map<String, Integer>();
        EMEA_Ready = new Map<String, Integer>();
        EMEA_Advanced = new Map<String, Integer>();
        EMEA_Premier = new Map<String, Integer>();
        
        /*
        putValues(EMEA_Affiliated,0,0,0,2,0,0,0,0,0);
        baseRoleRequirements.put('EMEA_Affiliated',EMEA_Affiliated);
        //guidelines say "1 tbd" for sales requirement.  Should the requirement
        //be set at 1 or 0 for the time being?
        putValues(EMEA_Ready,1,0,0,0,0,0,0,0,0);
        baseRoleRequirements.put('EMEA_Ready',EMEA_Ready);
        //guidelines say "1 per skill" on customer references here.  Should that
        //be per specialization or something else?
        putValues(EMEA_Advanced,2,2,2,1,1,1,0,0,0);
        baseRoleRequirements.put('EMEA_Advanced',EMEA_Advanced);
        //per bp
        //Guidelines say for technical: "2 SEAP ; RHCE tbd".  Currently have
        //the req set to 2.
        putValues(EMEA_Premier,4,4,4,2,1,2,0,0,0);
        baseRoleRequirements.put('EMEA_Premier',EMEA_Premier);
        */
        for(RequalMetVsSetRequirements__c r: mvsRegionMap.get('EMEA')){
            system.debug('EMEA requirement for [' + r.Partner_Tier__c + ']: ' + r);
            if(r.Partner_Tier__c == 'Affiliated'){
                putValues(EMEA_Affiliated, r);
                baseRoleRequirements.put('EMEA_Affiliated',EMEA_Affiliated);
            } else if(r.Partner_Tier__c == 'Ready'){
                putValues(EMEA_Ready, r);
                baseRoleRequirements.put('EMEA_Ready',EMEA_Ready);
            } else if(r.Partner_Tier__c == 'Advanced'){
                putValues(EMEA_Advanced, r);
                baseRoleRequirements.put('EMEA_Advanced',EMEA_Advanced);
            } else if(r.Partner_Tier__c == 'Premier'){
                putValues(EMEA_Premier, r);
                baseRoleRequirements.put('EMEA_Premier',EMEA_Premier);
            } else {
                system.debug('ERROR: Region undefined: ' + region + '. No Met Vs Set Requirements defined in custom settings for this region!');
                return;
            }
        }
    }

    void populateLATAM(){
        LATAM_Affiliated = new Map<String, Integer>();
        LATAM_Ready = new Map<String, Integer>();
        LATAM_Advanced = new Map<String, Integer>();
        LATAM_Premier = new Map<String, Integer>();
        /*
        putValues(LATAM_Affiliated,0,0,0,2,0,0,0,0,0);
        baseRoleRequirements.put('LATAM_Affiliated',LATAM_Affiliated);
        putValues(LATAM_Ready,1,0,1,0,1,0,0,0,0);
        baseRoleRequirements.put('LATAM_Ready',LATAM_Ready);
        putValues(LATAM_Advanced,2,1,1,1,1,1,0,0,0);
        baseRoleRequirements.put('LATAM_Advanced',LATAM_Advanced);
        putValues(LATAM_Premier,2,2,1,1,1,1,0,0,0);
        baseRoleRequirements.put('LATAM_Premier',LATAM_Premier);
        */
        for(RequalMetVsSetRequirements__c r: mvsRegionMap.get('LATAM')){
            system.debug('LATAM requirement for [' + r.Partner_Tier__c + ']: ' + r);
            if(r.Partner_Tier__c == 'Affiliated'){
                putValues(LATAM_Affiliated, r);
                baseRoleRequirements.put('LATAM_Affiliated',LATAM_Affiliated);
            } else if(r.Partner_Tier__c == 'Ready'){
                putValues(LATAM_Ready, r);
                baseRoleRequirements.put('LATAM_Ready',LATAM_Ready);
            } else if(r.Partner_Tier__c == 'Advanced'){
                putValues(LATAM_Advanced, r);
                baseRoleRequirements.put('LATAM_Advanced',LATAM_Advanced);
            } else if(r.Partner_Tier__c == 'Premier'){
                putValues(LATAM_Premier, r);
                baseRoleRequirements.put('LATAM_Premier',LATAM_Premier);
            } else {
                system.debug('ERROR: Region undefined: ' + region + '. No Met Vs Set Requirements defined in custom settings for this region!');
                return;
            }
        }
    }


    void putValues(Map<String,Integer> theMap, RequalMetVsSetRequirements__c reqs){
        putValues(
            theMap,
            Integer.valueOf(reqs.Sales__c),
            Integer.valueOf(reqs.SalesEngineer__c),
            Integer.valueOf(reqs.Delivery__c),
            Integer.valueOf(reqs.Rhce__c),
            Integer.valueOf(reqs.Specializations__c),
            Integer.valueOf(reqs.CustomerRefs__c),
            Integer.valueOf(reqs.RevenueAddSales__c),
            Integer.valueOf(reqs.RevenueAddSE__c),
            Integer.valueOf(reqs.RevenueAddDelivery__c)
        );
    }


    //This method fills in the values to the requirement maps for each Region.
    void putValues(Map<String,Integer> theMap, Integer Sales, Integer SalesEngineer, Integer Delivery,
                    Integer Rhce, Integer Specializations, Integer CustomerRefs, Integer RevenueAddSales,
                    Integer RevenueAddSE, Integer RevenueAddDelivery){
        theMap.put('Sales',Sales);
        theMap.put('SalesEngineer',SalesEngineer);
        theMap.put('Delivery',Delivery);
        theMap.put('Rhce',Rhce);
        theMap.put('Specializations',Specializations);
        theMap.put('CustomerRefs',CustomerRefs);
        theMap.put('RevenueAddSales',RevenueAddSales);
        theMap.put('RevenueAddSE',RevenueAddSE);
        theMap.put('RevenueAddDelivery',RevenueAddDelivery);
    }

    //Method to input revenue and an accreditation type and return a list of integers
    //to add to the total Sales, SE, and Delivery required.
    public static List<Integer> calculateRevenueAdditions(String region, String status, Integer revenue){
        list<Integer> additionalReqs = new list<Integer>();

        //This will probably be sent to or replaced by the rules engine.
        return additionalReqs;
    }

    //This method will do the Opportunity query and math to calculate the revenue
    //once I have clarification on how that should be calculated.
    Integer calculateRevenue(account acc){
        Integer revenue = 0;
        return revenue;
    }

    public static boolean businessPlanRequired(string status){
        if(status=='Ready'){
            return false;
        }else{
            return true;
        }
    }

     //This is the object that contains all of the values for the requirements.
    public class RegionStatusReq{
        public Integer Sales { get; set; }
        public Integer SalesEngineer { get; set; }
        public Integer Delivery { get; set; }
        public Integer Rhce { get; set; }
        public Integer Specializations { get; set; }
        public Integer CustomerRefs { get; set; }
        public Integer RevenueAddSales { get; set; }
        public Integer RevenueAddSE { get; set; }
        public Integer RevenueAddDelivery { get; set; }
        public Boolean BusinessPlan { get; set; }
    }

    //Method to gather all of the requirements for a region/status combination
    //from the appropriate maps and wrap them in a RegionStatusReq object for
    //use on the page.
    public RegionStatusReq getReqs(String region, String status, Integer revenue){
        String regionStatus = region+'_'+status;
        RegionStatusReq rsr = new RegionStatusReq();
        rsr.Sales=baseRoleRequirements.get(regionStatus).get('Sales');
        rsr.SalesEngineer=baseRoleRequirements.get(regionStatus).get('SalesEngineer');
        rsr.Delivery=baseRoleRequirements.get(regionStatus).get('Delivery');
        rsr.Rhce=baseRoleRequirements.get(regionStatus).get('Rhce');
        rsr.Specializations=baseRoleRequirements.get(regionStatus).get('Specializations');
        rsr.CustomerRefs=baseRoleRequirements.get(regionStatus).get('CustomerRefs');
        rsr.RevenueAddSales=baseRoleRequirements.get(regionStatus).get('RevenueAddSales');
        rsr.RevenueAddSE=baseRoleRequirements.get(regionStatus).get('RevenueAddSE');
        rsr.RevenueAddDelivery=baseRoleRequirements.get(regionStatus).get('RevenueAddDelivery');
        rsr.BusinessPlan=businessPlanRequired(status);
        list<Integer> additionalReqs = calculateRevenueAdditions(region, status, revenue);
        return rsr;
    }

}