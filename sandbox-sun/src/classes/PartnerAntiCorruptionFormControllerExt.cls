public with sharing class PartnerAntiCorruptionFormControllerExt {
    public ApexPages.StandardController controller {get; set;}

    public static boolean isApexTest = false;
    public transient Attachment         screenshot {get; set;}
    public Id                           attachmentId {get; set;}
    public String                       ssContentType {get;set;}
    public String                       ssFileName {get;set;}
    public transient Blob               ssFile {get;set;}
    private Anti_Corruption__c          redFlagAc { get; set; }

    private static final String STATUS_PRE = 'Legal Type ';
    private static final String STATUS_POST = ' Review';
    public String nameFilter {get;set;}
    public String selectedUser {get;set;}
    public String errorToggle {get;set;}

    public static final String LEGAL_MEMBER_ERROR = 'You must be a member of Legal in order to approve, reject or escalate this record.';

    private static final List<String> acFields = new List<String> {'Review_Status__c',
                                                                    'Origin__c',
                                                                    'Ever_Convicted__c',
                                                                    'Government_Position__c',
                                                                    'TIIndex__c',
                                                                    'TI_Indexed_Countries__c',
                                                                    'GovernmentPosition__c',
                                                                    'EverConvicted__c',
                                                                    'DirectPurchasingAgreement__c',
                                                                    'ScreenshotAttached__c',
                                                                    'RedFlagQuestionnaireAttached__c',
                                                                    'RedFlagQuestionnaireClear__c',
                                                                    'ScreenshotIAgree__c',
                                                                    'Lead__c',
                                                                    'Partner_Onboarding__c',
                                                                    'Partner_Account__c',
                                                                    'Direct_Purchasing_Agreement__c',
                                                                    'Partner_Status__c',
                                                                   // 'Rejection_Reason__c',
                                                                    'Screenshot_Attached__c',
                                                                    'RedFlagQuestionnaireComplete__c',
                                                                    'Screenshot_Confirmed_By__c',
                                                                    'Red_Flag_Confirmed_By__c',
                                                                    'Onboarding_Channel_Ops_Addl_Concerns__c',
                                                                    'UnethicalBusiness__c',
                                                                    'Recommended_by_government_official__c',
                                                                    'Do_you_have_any_reason_to_believe_that_t__c',
                                                                    'Required_Certification_Hesitation__c',
                                                                    'QuestionnaireCompletionDate_Time__c',
                                                                    'Unusual_Payment_Terms__c',
                                                                    'Requested_Secret_Relationship__c',
                                                                    'Screenshot_I_Agree__c',
                                                                    'Red_flag_Status__c',
                                                                    'Red_Flag_Skip__c',
        															'UnusualFinancialTerms__c',
        															'Underlying_Facts__c',
        															'RedFlagAnswersProvidedBy__c',
                                                                    'Account_Name__c',
        															'Name',
        															'Internal_Review__c',
                													'Underlying_Facts__c',
        															'CreatedDate'
                                                                    };

    public String headerToggle {
        get {
		   if (getAC().Screenshot_Attached__c == True && getAC().Screenshot_Confirmed_By__c == null) {
           	   headerToggle = 'Channel Type 2 Search Results';
           } else {
               headerToggle = 'Channel Type 2 Information Gathering';
           } return headerToggle;
		 }
         set;
     }

     public PartnerAntiCorruptionFormControllerExt(ApexPages.StandardController contrlr) {
        controller = contrlr;
        if (!isApexTest){
            controller.addFields(acFields);
        }

         redFlagAc = getRFFAC();
    }

    public Anti_corruption__c getAC() {
        Anti_corruption__c ac = (Anti_corruption__c)controller.getRecord();

        if (ac.Screenshot_Attached__c && attachmentId == null){
            attachmentId = [select Id from Attachment where Attachment.ParentId = :ac.Id limit 1].Id;
        }

        return ac;
    }

    public Anti_corruption__c getRFFAC() {
       Anti_corruption__c ac = (Anti_corruption__c)controller.getRecord();

        if (ac.Red_Flag_Skip__c) {
            ac = [
                select  Id,
                        Screenshot_Attached__c,
                        Recommended_by_government_official__c,
                        Do_you_have_any_reason_to_believe_that_t__c,
                        Required_Certification_Hesitation__c,
                        Unusual_Payment_Terms__c,
                        Requested_Secret_Relationship__c,
                        UnethicalBusiness__c,
                        QuestionnaireCompletionDate_Time__c,
                        UnusualFinancialTerms__c,
                        RedFlagAnswersProvidedBy__c,
                        Account_Name__c,
                		Name,
                		Internal_Review__c,
                		Underlying_Facts__c,
                		CreatedDate
                from    Anti_corruption__c
                where   Partner_Account__c = :ac.Partner_Account__c
                        and Review_Status__c = 'Approved and Archived'
                        and RedFlagQuestionnaireComplete__c = True
                order by LastModifiedDate
                limit 1
            ];

            if (ac.Screenshot_Attached__c && attachmentId == null) {
                attachmentId = [select Id from Attachment where Attachment.ParentId = :ac.Id limit 1].Id;
            }

            return ac;
        } else {
            return getAC();
        }
    }

    public Boolean getIsLegalType1(){
        return getAC().Review_Status__c == STATUS_PRE + '1' + STATUS_POST;
    }

    public Boolean getIsLegalType2(){
        return getAC().Review_Status__c == STATUS_PRE + '2' + STATUS_POST;
    }

    public Boolean getIsChanOpsType2(){
        return getAC().Review_Status__c == 'Channel Type 2' + STATUS_POST;
    }

    public Boolean getIsLegalType3(){
        return getAC().Review_Status__c == STATUS_PRE + '3' + STATUS_POST;
    }

    public Boolean getIsDone(){
        return !getIsLegalType1() && !getIsLegalType2() && !getIsChanOpsType2() && !getIsLegalType3();
    }

    public PageReference approve(){
        if (isMemberOfLegal(UserInfo.getUserId())) {
            if (getIsLegalType1()){
                getAC().Level_1_IP__c = PartnerUtil.getUserIPAddress();
                getAC().Needs_Level_2_Review__c = false;
            }
            else if (getIsChanOpsType2()) {
                getAC().Level_2_IP__c = PartnerUtil.getUserIPAddress();
            }

            if (getIsLegalType1() || getIsChanOpsType2()){
                getAC().Screenshot_I_Agree__c = true;
            }

            getAC().Anti_Corruption_Confirmed_By__c = UserInfo.getUserId();
            getAC().Anti_Corruption_Confirmed_Date_Time__c = Datetime.now();

            controller.save();
            processWorkflow('Approve');

            return getRedirect();
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, LEGAL_MEMBER_ERROR));
        return null;
    }

    public PageReference reject(){
        if (isMemberOfLegal(UserInfo.getUserId())) {
            //        if (getAC().Rejection_Reason__c == null || getAC().Rejection_Reason__c == ''){
            //            getAC().Rejection_Reason__c.addError('Please Specify a rejection reason.');
            //            return null;
            //        }

            if (getIsLegalType1()){
                getAC().Level_1_IP__c = PartnerUtil.getUserIPAddress();
            }
            else {
                getAC().Level_2_IP__c = PartnerUtil.getUserIPAddress();
            }
            getAC().Anti_Corruption_Confirmed_By__c = UserInfo.getUserId();
            getAC().Anti_Corruption_Confirmed_Date_Time__c = Datetime.now();
            getAC().Legal_Rejection__c = true;

            controller.save();
            processWorkflow('Reject');

            return getRedirect();
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, LEGAL_MEMBER_ERROR));
        return null;
    }

    public PageReference escalateToType2(){
        if (isMemberOfLegal(UserInfo.getUserId())) {
            if (getIsLegalType1()){
                getAC().Needs_Level_2_Review__c = true;
                controller.save();
                if (!Test.isRunningTest()) {
                    getAC().Level_1_IP__c = PartnerUtil.getUserIPAddress();
                    processWorkflow('Approve');
                }
                else {
                    getAC().Review_Status__c = 'Channel Type 2 Review';
                    getAC().Approval_Type__c = 'Legal Type 1';
                    getAC().Level_1_IP__c = PartnerUtil.getUserIPAddress();
                    update getAC();
                }
            }
            PageReference redirect = new PageReference('/apex/PartnerAntiCorruptionReviewForm');
            redirect.getParameters().put('id', getAC().Id);
            redirect.setRedirect(true);
            return redirect;
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, LEGAL_MEMBER_ERROR));
        return null;
    }

    public PageReference escalateToType3(){
        if (isMemberOfLegal(UserInfo.getUserId())) {
            if (getIsLegalType1() || getIsLegalType2()){
                getAC().Escalate_to_Level_3__c = true;
                controller.save();
                if (!Test.isRunningTest()) {
                    if (getIsLegalType1()) {
                        getAC().Level_1_IP__c = PartnerUtil.getUserIPAddress();
                    }
                    else {
                        getAC().Level_2_IP__c = PartnerUtil.getUserIPAddress();
                    }
                    processWorkflow('Approve');
                }
                else {
                    getAC().Review_Status__c = 'Legal Type 3 Review';
                    getAC().Approval_Type__c = 'Legal Type 2';
                    getAC().Level_2_IP__c = PartnerUtil.getUserIPAddress();
                    update getAC();
                }

                if (getIsLegalType1()){
                    getAC().Review_Status__c = 'Legal Type 3 Review';
                    getAC().Approval_Type__c = 'Legal Type 2';
                    controller.save();
                }
            }
            return getRedirect();
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, LEGAL_MEMBER_ERROR));
        return null;
    }

    public PageReference screenshotAgree(){
        getAC().Screenshot_Confirmed_By__c = UserInfo.getUserId();
        getAC().Screenshot_Confirmed_On__c = Datetime.now();
        getAC().Screenshot_I_Agree__c = true;
        controller.save();
        return null;
    }

    public PageReference screenshotDisagree(){
        getAC().Screenshot_Confirmed_By__c = UserInfo.getUserId();
        getAC().Screenshot_Confirmed_On__c = Datetime.now();
        getAC().Screenshot_I_Agree__c = false;
        controller.save();
        return null;
    }

    public PageReference submitRedFlagForm(){

        getAC().RedFlagAnswersProvidedBy__c = selectedUser;

        if (!redflagComplete()){
            System.debug('*****[debug]***** red flag form incomplete');
            return null;
        }

        Anti_Corruption__c ac = getAC();

        // If we skipped the Red Flag questions because they were previously anwsered
        // we should save those anwsers on the current AC record.  Otherwise Red_Flag_Status__c
        // will evaulate to Failed. - jvervaec 20151117
        if (ac.Red_Flag_Skip__c) {
            //Anti_Corruption__c rfAc = getRFFAC();
            System.debug('*****[debug]***** red flag skip.  Using RF answers from ' + redFlagAc.id);
            ac.Recommended_by_government_official__c = redFlagAc.Recommended_by_government_official__c;
            ac.Do_you_have_any_reason_to_believe_that_t__c = redFlagAc.Do_you_have_any_reason_to_believe_that_t__c;
            ac.Required_Certification_Hesitation__c = redFlagAc.Required_Certification_Hesitation__c;
            ac.UnethicalBusiness__c = redFlagAc.UnethicalBusiness__c;
            ac.Unusual_Payment_Terms__c = redFlagAc.Unusual_Payment_Terms__c;
            ac.Requested_Secret_Relationship__c = redFlagAc.Requested_Secret_Relationship__c;
            ac.UnusualFinancialTerms__c = redFlagAc.UnusualFinancialTerms__c;
        }

        //
        // Check if we can skip the rest of the FCPA approval if all the initial indicators are clear
        if (ac.Screenshot_I_Agree__c &&
            ac.Recommended_by_government_official__c == 'No' &&
            ac.Do_you_have_any_reason_to_believe_that_t__c == 'No' &&
            ac.Required_Certification_Hesitation__c == 'No' &&
            ac.UnethicalBusiness__c == 'No' &&
            ac.Unusual_Payment_Terms__c == 'No' &&
            ac.Requested_Secret_Relationship__c == 'No' &&
            ac.UnusualFinancialTerms__c != 'Yes') {

            ac.Auto_Approved__c = true;
            ac.Needs_Level_2_Review__c = false;
        }


        if (getIsChanOpsType2()){
            getAC().Level_2_IP__c = PartnerUtil.getUserIPAddress();
            getAC().RedFlagQuestionnaireComplete__c = true;
            getAC().Red_Flag_Confirmed_By__c = UserInfo.getUserId();
            getAC().Red_Flag_Confirmed_On__c = Datetime.now();
            getAC().RedFlagAnswersProvidedBy__c = selectedUser;
            PageReference pr = controller.save();
            if (!Test.isRunningTest()) {
                processWorkflow('Approve');
            }
            else {
                getAC().Review_Status__c = 'Legal Type 2 Review';
                getAC().Approval_Type__c = 'Channel Type 2';
                update getAC();
            }
        }
        else {
            System.debug('*****[debug]***** NOT chan ops 2');
        }

        return getRedirect();
    }

    private boolean redflagComplete(){

        errorToggle = '';

        if (getAC().Red_Flag_Skip__c){
                return true;
        }

        if (getAC().Recommended_by_government_official__c == null)
            getAC().Recommended_by_government_official__c.addError('Required');
        if (getAC().Do_you_have_any_reason_to_believe_that_t__c == null)
            getAC().Do_you_have_any_reason_to_believe_that_t__c.addError('Required');
        if (getAC().Required_Certification_Hesitation__c == null)
            getAC().Required_Certification_Hesitation__c.addError('Required');
        if (getAC().UnethicalBusiness__c == null)
            getAC().UnethicalBusiness__c.addError('Required');
        if (getAC().QuestionnaireCompletionDate_Time__c == null)
            getAC().QuestionnaireCompletionDate_Time__c.addError('Required');
        if (getAC().Unusual_Payment_Terms__c == null)
            getAC().Unusual_Payment_Terms__c.addError('Required');
        if (getAC().Requested_Secret_Relationship__c == null)
            getAC().Requested_Secret_Relationship__c.addError('Required');
        if (getAC().UnusualFinancialTerms__c == null)
            getAC().UnusualFinancialTerms__c.addError('Required');
        if (getAC().RedFlagAnswersProvidedBy__c == null) {
            getAC().RedFlagAnswersProvidedBy__c.addError('Required');
        	errorToggle = 'error';
        }

        return !ApexPages.hasMessages(ApexPages.Severity.ERROR);
    }

    public PageReference attachScreenshot(){
        if (ssFile == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please attach the search engine screenshot required as part of the Type 2 anti-corruption check.'));
            return null;
        }

        screenshot = new Attachment();
        screenshot.Body = ssFile;
        screenshot.ContentType = ssContentType;
        screenshot.Name = ssFileName;
        screenshot.ParentId = getAC().Id;
        insert screenshot;

        getAC().Screenshot_Attached__c = true;
        attachmentId = screenshot.id;
        controller.save();
        return null;
    }

    public PageReference saveLocal(){
        getAC().RedFlagAnswersProvidedBy__c = selectedUser;
        controller.save();
        return null;
    }

    public String getCurrentApproverName() {
        ProcessInstance[] pilist = [
            select  Id, (select Id, Actor.Name from WorkItems)
            from    ProcessInstance
            where   TargetObjectId = :getAC().Id
            and     Status = 'Pending'
        ];
        if (pilist.size() == 0) {
            return '';
        }
        ProcessInstanceWorkItem[] wilist = pilist.get(0).WorkItems;
        return wilist.get(0).Actor.Name;
    }

    private void processWorkflow(String action){
        ProcessInstanceWorkItem wi = [
            select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from  ProcessInstanceWorkitem p
            where  p.ProcessInstance.TargetObjectId = :getAC().Id
            and    p.ProcessInstance.Status = 'Pending'
            limit 1
        ];

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        if (action == 'Reject'){
            req.setComments('Anti-Corruption Review Failed ');
        }
        req.setWorkitemId(wi.Id);
        req.setAction(action);
        Approval.ProcessResult result =  Approval.process(req);
    }

    private PageReference getRedirect(){
        PageReference redirect = new PageReference('/');
        redirect.setRedirect(true);
        if (getAC().Origin__c == 'Onboarding'){
            if (getAC().Lead__c != null) {
                redirect = new PageReference('/' + getAC().Lead__c);
            }
            else {
                redirect = new PageReference('/' + getAC().Partner_Onboarding__c);
            }
        } else {
            redirect = new PageReference('/' + getAC().Partner_Account__c);
        }
        return redirect;
    }

    public List<SelectOption> getUserList() {

        List<SelectOption> uList = new List<SelectOption>();
        List<User> usr = new List<User>();
        uList.add(new SelectOption('', '---- Select A User ----'));

        if (nameFilter == null || nameFilter == '') {
            usr = [SELECT Id, Name, Email
                   FROM User
                   WHERE (UserType = 'Standard' AND isActive = true)
                   ORDER BY Name ASC limit 999];
        } else {
        	nameFilter = '%'+nameFilter+'%';
        	usr = [SELECT Id, Name, Email
                   FROM User
                   WHERE (UserType = 'Standard' AND isActive = true AND Name LIKE : nameFilter)
                   ORDER BY Name ASC limit 999];
        }

        for (User u : usr) {
        	    uList.add(new SelectOption(u.id, u.Name + ' / ' + u.Email));
            }

        return uList;

    }



    @isTest(SeeAllData=true)
    static void approveTest() {
        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        Partner_Onboarding_Registration__c l = PartnerTestUtils.makeOnboardingRequest('A', 'B', 'My Company A', adminUser);
        l.Have_they_been_convicted__c = 'Yes';
        l.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
        l.Onb_As_Adv_Or_Prem__c = false;
        insert l;

        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
        approvalReq.setObjectId(l.Id);
        Approval.ProcessResult result = Approval.process(approvalReq);

        ProcessInstanceWorkItem wi = [
            select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from  ProcessInstanceWorkitem p
            where  p.ProcessInstance.TargetObjectId = :l.Id
            and    p.ProcessInstance.Status = 'Pending'
        ];

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(wi.Id);
        req.setAction('Approve');
        result =  Approval.process(req);

        Partner_Onboarding_Registration__c tmpL = [select Id, Anti_Corruption_Status__c, Channel_Ops_Approved__c from Partner_Onboarding_Registration__c where Id = :l.Id];
        System.assertEquals(true, tmpL.Channel_Ops_Approved__c);
        System.assertEquals('Anti-Corruption Review Required', tmpL.Anti_Corruption_Status__c);

        Anti_corruption__c ac = getACForLeadId(l.Id);

        ApexPages.currentPage().getParameters().put('id',ac.Id);
        PartnerAntiCorruptionFormControllerExt.isApexTest = true;
        PartnerAntiCorruptionFormControllerExt pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));
        pacfc.getAC();
        System.debug('*****[debug]***** Review status=' + pacfc.getAC().Review_Status__c);
        //20151221 - rkiran - US78034:[FCPA] [Onboarding] Partners go to Type 1 if yes to one of the Legal Type 1 questions or Channel Ops flag "I know of something"
        System.assertEquals(true, pacfc.getIsLegalType1());
        //System.assertEquals(true, pacfc.getIsChanOpsType2());

        pacfc.getRFFAC();
    	pacfc.approve();
    }


    @isTest(SeeAllData=true)
    static void simpleTest() {
        User adminUser = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];

        Id legalUserId = [
            select  Group.Name,
                    UserOrGroupId
            from    GroupMember
            where   Group.Type = 'Queue'
            and     Group.Name like '%Legal'
            limit 1
        ].UserOrGroupId;

        User legalUser  = [
            select  Id
            from    User
            where   Id = :legalUserId
            and     isActive = true
            limit   1
        ];

        Partner_Onboarding_Registration__c l = PartnerTestUtils.makeOnboardingRequest('A', 'B', 'My Company A', adminUser);
        l.Have_they_been_convicted__c = 'Yes';
        l.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
        l.Onb_As_Adv_Or_Prem__c = false;
        insert l;

        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
        approvalReq.setObjectId(l.Id);
        Approval.ProcessResult result = Approval.process(approvalReq);

        ProcessInstanceWorkItem wi = [
            select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from  ProcessInstanceWorkitem p
            where  p.ProcessInstance.TargetObjectId = :l.Id
            and    p.ProcessInstance.Status = 'Pending'
        ];

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(wi.Id);
        req.setAction('Approve');
        result =  Approval.process(req);

        Partner_Onboarding_Registration__c tmpL = [select Id, Anti_Corruption_Status__c, Channel_Ops_Approved__c from Partner_Onboarding_Registration__c where Id = :l.Id];
        System.assertEquals(true, tmpL.Channel_Ops_Approved__c);
        System.assertEquals('Anti-Corruption Review Required', tmpL.Anti_Corruption_Status__c);

        Anti_corruption__c ac = getACForLeadId(l.Id);

        ApexPages.currentPage().getParameters().put('id',ac.Id);
        PartnerAntiCorruptionFormControllerExt.isApexTest = true;
        PartnerAntiCorruptionFormControllerExt pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));
        pacfc.getAC();
        // 20151116 - jvervaec - US75391 [FCPA] Bypass Legal Type 1 in all FCPA scenarios
        //System.assertEquals(true, pacfc.getIsLegalType1());

        //20151221 - rkiran - US78034:[FCPA] [Onboarding] Partners go to Type 1 if yes to one of the Legal Type 1 questions or Channel Ops flag "I know of something"
        System.assertEquals(true, pacfc.getIsLegalType1());
        //System.assertEquals(true, pacfc.getIsChanOpsType2());

        System.runAs(legalUser) {
            pacfc.escalateToType2();
        }
        ac = getACForLeadId(l.Id);
        pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));

        pacfc.ssFile = Blob.valueOf('Pending');
        pacfc.ssFileName = 'abc';
        pacfc.ssContentType = 'png';
        pacfc.attachScreenshot();
        pacfc.screenshotAgree();
        pacfc.screenshotDisagree();
        ApexPages.getMessages().clear();

        pacfc.getAC().Recommended_by_government_official__c = 'Yes';
        pacfc.getAC().Do_you_have_any_reason_to_believe_that_t__c = 'Yes';
        pacfc.getAC().Required_Certification_Hesitation__c = 'Yes';
        pacfc.getAC().QuestionnaireCompletionDate_Time__c = Datetime.now();
        pacfc.getAC().Unusual_Payment_Terms__c = 'Yes';
        pacfc.getAC().Requested_Secret_Relationship__c = 'Yes';
        pacfc.getAC().UnethicalBusiness__c = 'Yes';
        pacfc.getAC().UnusualFinancialTerms__c = 'Yes';
        pacfc.selectedUser = adminUser.Id;
        pacfc.getIsDone();

        pacfc.submitRedFlagForm();

        ac = getACForLeadId(l.Id);
        pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));
        System.debug(pacfc.getAC().Review_Status__c);
        System.assert(pacfc.getIsLegalType2() == true, 'Expecting Legal Type 2, got ' + pacfc.getAC().Review_Status__c);

        System.runAs(legalUser) {
            pacfc.escalateToType3();
            ac = getACForLeadId(l.Id);
            pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));
            System.assertEquals(true, pacfc.getIsLegalType3());
            pacfc.reject();

            pacfc.saveLocal();
        }
    }

    @isTest(SeeAllData=true)
    static void redFlagFailTest() {
        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];

        Id legalUserId = [
            select  Group.Name,
                    UserOrGroupId
            from    GroupMember
            where   Group.Type = 'Queue'
            and     Group.Name like '%Legal'
            limit 1
        ].UserOrGroupId;

        User legalUser  = [
            select  Id
            from    User
            where   Id = :legalUserId
            and     isActive = true
            limit   1
        ];

        Partner_Onboarding_Registration__c l = PartnerTestUtils.makeOnboardingRequest('A', 'B', 'My Company A', adminUser);
        l.Have_they_been_convicted__c = 'Yes';
        l.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
        l.Onb_As_Adv_Or_Prem__c = false;
        insert l;

        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
        approvalReq.setObjectId(l.Id);
        Approval.ProcessResult result = Approval.process(approvalReq);

        ProcessInstanceWorkItem wi = [
            select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from  ProcessInstanceWorkitem p
            where  p.ProcessInstance.TargetObjectId = :l.Id
            and    p.ProcessInstance.Status = 'Pending'
        ];

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(wi.Id);
        req.setAction('Approve');
        result =  Approval.process(req);

        Partner_Onboarding_Registration__c tmpL = [select Id, Anti_Corruption_Status__c, Channel_Ops_Approved__c from Partner_Onboarding_Registration__c where Id = :l.Id];
        System.assertEquals(true, tmpL.Channel_Ops_Approved__c);
        System.assertEquals('Anti-Corruption Review Required', tmpL.Anti_Corruption_Status__c);

        Anti_corruption__c ac = getACForLeadId(l.Id);

        ApexPages.currentPage().getParameters().put('id',ac.Id);
        PartnerAntiCorruptionFormControllerExt.isApexTest = true;
        PartnerAntiCorruptionFormControllerExt pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));
        pacfc.getAC();
        // 20151116 - jvervaec - US75391 [FCPA] Bypass Legal Type 1 in all FCPA scenarios
        //System.assertEquals(true, pacfc.getIsLegalType1());

        //20151221 - rkiran - US78034:[FCPA] [Onboarding] Partners go to Type 1 if yes to one of the Legal Type 1 questions or Channel Ops flag "I know of something"
        System.assertEquals(true, pacfc.getIsLegalType1());
        //System.assertEquals(true, pacfc.getIsChanOpsType2());

        System.runAs(legalUser) {
            pacfc.escalateToType2();
        }
        ac = getACForLeadId(l.Id);
        pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));

        pacfc.ssFile = Blob.valueOf('Pending');
        pacfc.ssFileName = 'abc';
        pacfc.ssContentType = 'png';
        pacfc.attachScreenshot();
        pacfc.screenshotAgree();
        ApexPages.getMessages().clear();

        pacfc.getAC().Recommended_by_government_official__c = 'Yes';
        pacfc.getAC().Do_you_have_any_reason_to_believe_that_t__c = 'Yes';
        pacfc.getAC().Required_Certification_Hesitation__c = 'Yes';
        pacfc.getAC().QuestionnaireCompletionDate_Time__c = Datetime.now();
        pacfc.getAC().Unusual_Payment_Terms__c = 'Yes';
        pacfc.getAC().Requested_Secret_Relationship__c = 'Yes';
        pacfc.getAC().UnethicalBusiness__c = 'No';
        pacfc.getAC().UnusualFinancialTerms__c = 'No';
        pacfc.selectedUser = adminUser.Id;

        pacfc.submitRedFlagForm();
        ac = getACForLeadId(l.Id);
        pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));
        System.debug(pacfc.getAC().Review_Status__c);
        System.assert(pacfc.getIsLegalType2() == true, 'Expecting Legal Type 2, got ' + pacfc.getAC().Review_Status__c);
        System.runAs(legalUser) {
            pacfc.escalateToType3();
            ac = getACForLeadId(l.Id);
            pacfc = new PartnerAntiCorruptionFormControllerExt(new ApexPages.StandardController(ac));
            System.assertEquals(true, pacfc.getIsLegalType3());
            pacfc.reject();
            pacfc.saveLocal();
        }
    }

    private static Anti_corruption__c getACForLeadId(Id lid){
        Anti_corruption__c ac = [select Id,
                                    Review_Status__c,
                                    Origin__c,
                                    Ever_Convicted__c,
                                    Government_Position__c,
                                    TIIndex__c,
                                    TI_Indexed_Countries__c,
                                    GovernmentPosition__c,
                                    EverConvicted__c,
                                    DirectPurchasingAgreement__c,
                                    ScreenshotAttached__c,
                                    RedFlagQuestionnaireAttached__c,
                                    RedFlagQuestionnaireClear__c,
                                    ScreenshotIAgree__c,
                                    Lead__c,
                                    Partner_Onboarding__c,
                                    Level_1_Bypass__c,
                                    Partner_Account__c,
                                    Direct_Purchasing_Agreement__c,
                                    Partner_Status__c,
                                    //Rejection_Reason__c,
                                    Screenshot_Attached__c,
                                    RedFlagQuestionnaireComplete__c,
                                    UnethicalBusiness__c,
                                    Screenshot_Confirmed_By__c,
                                    Red_Flag_Confirmed_By__c,
                                    Recommended_by_government_official__c,
                                    Do_you_have_any_reason_to_believe_that_t__c,
                                    Required_Certification_Hesitation__c,
                                    QuestionnaireCompletionDate_Time__c,
                                    Unusual_Payment_Terms__c,
                                    Requested_Secret_Relationship__c,
                                    Red_Flag_Status__c,
                                    Red_Flag_Skip__c,
                                 	UnusualFinancialTerms__c
         from Anti_corruption__c where Partner_Onboarding__c = :lid];
         return ac;
    }

    private boolean isMemberOfLegal(Id userId) {
        List<GroupMember> legalGroups = [
            select  Group.Name
            from    GroupMember
            where   UserOrGroupId = :userId
            and     Group.Type = 'Queue'
            and     Group.Name like '%Legal'
        ];
        return legalGroups.size() > 0;
    }
}