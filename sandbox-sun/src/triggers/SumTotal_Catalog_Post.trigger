trigger SumTotal_Catalog_Post on SumTotal_Catalog__c (before insert, before update) {
    Map<String,String> roleMap = new Map<String,String>(); // {
        /*
        'S' => 'Sales',
        'DEL' => 'Delivery',
        'SE' => 'Sales Engineer',
        'TECH' => 'Delivery and Sales Engineer',
        'ADD' => 'Advanced Delivery'
    };
    */

    Map<String,String> solutionMap = new Map<String,String>(); // {
        /*
        'CLI' => 'Cloud Infrastructure',
        'MWS' => 'Middleware Solutions',
        'DCI' => 'Data Center Infrastructure'
    };
    */

    Map<String,String> skillMap = new Map<String,String>(); // {
        /*
    // DCI products:
        'PLT' => 'Platform',
        'PLM' => 'Platform Migration',
        'VIR' => 'Virtualization / RHEV',
        'STR' => 'Storage',
        'ACA' => 'Academic',
    // MWS products:
        'APD' => 'Application Development',
        'MWM' => 'Middleware Migration',
        'MWI' => 'Middleware Integration Services',
        'BPA' => 'Business Process Automation',
        'FOU' => 'Foundation',
        'CLI' => 'Cloud Infrastructure',
        'PAS' => 'Platform as a Service',
        'IAS' => 'Infrastructure as a Service',
        'CMT' => 'Cloud Management',
        'ADV' => 'Advanced Training',
        'PASDEV' => 'PaaS Development',
        'CEPH' => 'OpenStack Integration',
        'DG' => 'Data Grid',
        'DM' => 'Data Mapper',
        'MDFH' => 'Mobile Development with Feed Henry',
        'OPT' => 'Optiplanner',
        'OS' => 'OpenStack',
        'SAP' => 'SAP HANA',
        'AHC' => 'Atomic Host and Containers',
        'SDSY' => 'Service Development with Switchyard',
        'ACC' => 'Accreditation',
        'CLF' => 'CloudForms'
    };
    */

    for (SumTotal_Code__c code : [select Code__c, Description__c, Category__c from SumTotal_Code__c]) {
        if (code.Category__c == 'Role') {
            roleMap.put(code.Code__c, code.Description__c);
        }
        else if (code.Category__c == 'Skill') {
            skillMap.put(code.Code__c, code.Description__c);
        }
        else if (code.Category__c == 'Solution') {
            solutionMap.put(code.Code__c, code.Description__c);
        }
    }

    Partner_Points_LMS_Catalog__c[] lmscat = [select Id, Course_Id__c from Partner_Points_LMS_Catalog__c where Course_Id__c in :PartnerUtil.getStringFieldSet(Trigger.new, 'SumTotal_ID__c')];

    PartnerTrack__c[] tracks = [select Id, Partner_Function__c, Product_of_Interest__c from PartnerTrack__c];
    for (SumTotal_Catalog__c cat : Trigger.new) {
        cat.Language__c = 'en_US';  // default to this so we have no orphaned entries in PP admin
        String code = cat.Attributes__c;
        if (code == null) {
            continue;
        }
        String[] parts = code.split('-');
        if (parts.size() != 2 && parts.size() != 4 && parts.size() != 6) {
            continue;
        }
        String solution = '';
        String role = '';
        String spectrack = '';
        String module = '';
        String product = '';
        String language = '';

        solution = parts[0];
        role = parts[1];
        if (parts.size() > 2) {
            spectrack = parts[2];
            module = parts[3];
            if (parts.size() > 4) {
                product = parts[4];
                language = parts[5];
            }
        }

        cat.Language__c = language;
        if (module == 'ASM' || product == 'ASM' || product == 'EXAM') {
            cat.Training_Type__c = 'Exam';
        }
        else {
            cat.Training_Type__c = 'Course';
        }
        if (roleMap.containsKey(role) && solutionMap.containsKey(solution)) {
            String roleName = roleMap.get(role);
            String solutionName = solutionMap.get(solution);
            for (PartnerTrack__c track : tracks) {
                if (track.Partner_Function__c == roleName && track.Product_of_Interest__c == solutionName) {
                    cat.Training_Path__c = track.Id;
                    break;
                }
            }
            if (cat.Training_Path__c == null) {
//                cat.addError('Cannot resolve track: ' + roleName + ' / ' + solutionName);
            }
        }
        else {
//            cat.addError('Invalid role: ' + role);
//            continue;
        }
        if (skillMap.containsKey(spectrack)) {
            cat.Skill__c = skillMap.get(spectrack);
        }
        else {
//            cat.addError('Invalid skill: ' + spectrack);
        }

        for (Partner_Points_LMS_Catalog__c lcat : lmscat) {
            if (lcat.Course_Id__c == cat.SumTotal_ID__c) {
                lcat.Partner_Track__c = cat.Training_Path__c;
                lcat.Language__c = cat.Language__c;
                lcat.Global_Region__c = cat.Global_Region__c;
                if (cat.Activity_Name__c.length() > 80) {
                    lcat.Name = cat.Activity_Name__c.substring(0,80);
                }
                else {
                    lcat.Name = cat.Activity_Name__c;
                }
                break;
            }
        }
        update lmscat;
    }
}