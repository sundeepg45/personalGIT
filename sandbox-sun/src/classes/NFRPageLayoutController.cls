/****************************************************************************************
Name    : NFRPageLayoutController
Desc    : Used to create NFR Requests along with their line items, by product family,
          based on the products from the SKU matrix.

Modification Log
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
 Kiran Ravikanti        16-Mar-2015     Enhancement Request to clone partner contact on
                                        to shell sales account.
 Jonthan Garrison       27-Apr-2015     Changed how rhnLogin is determined. Now getting
                                        it from User.FederationIdentifier instead of
                                        Contact.LoginName__c.
****************************************************************************************/

//Since, Partner do not have access to see the Sales accounts, Controller has to be 'without sharing'
public without sharing class NFRPageLayoutController {

    public Id NFRRequestId {get; set;}
    public Id partnerAccountId {get; set;}
    public Id oldPartnerAccountId {get; set;}
    public NFR_Request__c NFRs {get; set;}
    public NFR_Request__c activeNFRs {get; set;}
    public Account partnerAccount {get; set;}
    public User partnerUser {get; set;}
    public List<NFR_SKU_Matrix__c> skumatrix {get; set;}
    public List<NFR_SKU_Matrix__c> skumatrixoriginal {get; set;}
    public List<NFR_SKU_Matrix__c> newNFRProducts {get; set;}
    public List<NFR_SKU_Matrix__c> tempSKUMatrix {get; set;}
    public Boolean editmode {get; set;}
    public Boolean stopCreation {get; set;}
    public Boolean agreeToTerms {get; set;}
    public String requestedBy {get; set;}
    public List<String> useCases {get; set;}
    public NFR_Request__c NFR_Request {get; set; }
    public boolean isPartnerUser {get; set;}
    public boolean skuMatrixEstablished {get; set;}
    public boolean maxQuantityExceeded {get; set;}
    public List<NFR_Request__c> nfrRequests;
    private List<List<NFR_SKU_Matrix__c>> sortedNFRProducts;
    private List<NFR_LI__c> activeNFRLineItems = new List<NFR_LI__c>();

    static public final String EXC_MAX_QUANTITY = 'Max_Quantity';
    static public final String EXC_SPECIAL_APPROVAL = 'Special_Approval';
    static public final String EXC_ENABLEMENT_PREREQUISITE = 'Enablement_Prerequisite';

    public NFRPageLayoutController(ApexPages.StandardController controller) {
        tempSKUMatrix = new List<NFR_SKU_Matrix__c>();
        skuMatrixEstablished = false;
        maxQuantityExceeded = false;
        isPartnerUser = false;
        NFR_Request = new NFR_Request__c();
        nfrRequests = new List<NFR_Request__c>();
        sortedNFRProducts = new List<List<NFR_SKU_Matrix__c>>();
        useCases = new List<String>();
        agreeToTerms = false;
        editmode = true;
        stopCreation = false;
        loadAccountInformation();
    }

    private void loadAccountInformation() {
        try {
            User me = [select Contact.AccountId,
                        Contact.LoginName__c,
                        Contact_Name__c,
                        Name
                        from User
                        where Id = :UserInfo.getUserId()];
            requestedBy = me.Name;
            if (me.Contact.AccountId != null) {
                isPartnerUser = true;
                partnerAccountId = me.Contact.AccountId;
                System.debug('Partner Account ID----' + partnerAccountId);
                NFR_Request.Contact_at_Partner__c = me.Contact.Id;
            } else {
                String tempId = ApexPages.currentPage().getParameters().get('retURL');
                if (!String.isEmpty(tempId.trim())) {
                    tempId = tempId.replaceAll('/', '');
                    partnerAccountId = (Id) tempId;
                }
                if (partnerAccountId == null) {
                    String acId = ApexPages.currentPage().getParameters().get('id');
                    partnerAccountId = (Id) acId;
                }
            }
            partnerAccount = [select Name,
                                Id,
                                OwnerId,
                                Global_Region__c,
                                Finder_Partner_Type__c,
                                Finder_Partner_Tier__c,
                                Finder_Partner_Type__r.Name,
                                Finder_Partner_Tier__r.Name,
                                Finder_Partner_Type_Name__c,
                                Finder_Partner_Tier_Name__c,
                                OEM_Tier__c
                                from Account where id = :partnerAccountId];
            NFR_Request.Partner__c = partnerAccount.Id;
            NFR_Request.Account_Owner__c = partnerAccount.OwnerId;
            getActiveNFRLineItems();
            skumatrix = setUpSKUMatrix();
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }

    public PageReference doOnLoad() {
        try {
            System.debug('*****[debug]***** doOnLoad()');
            if (partnerAccountId != null) {
                if (skumatrix != null && skumatrix.size() == 0) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, System.Label.NFRErrorNotSkus));
                    stopCreation = true;
                    return null;
                } else {
                    stopCreation = false;
                    return null;
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
        stopCreation = false;
        return null;
    }

    public PageReference doOK() {
        return showListOfNFRs();
    }

    public PageReference doCreateCase() {
        PageReference pageRef = new PageReference('/500/e?retURL=%2F500%2Fo&RecordType=012600000005EVG&ent=Case');
        pageref.setRedirect(true);
        return pageRef;
    }

    public PageReference save_submit() {
        //To get the federation id from user
        if(NFR_Request.Contact_at_Partner__c !=null) {
            partnerUser = [SELECT id, FederationIdentifier FROM User WHERE ContactId = :NFR_Request.Contact_at_Partner__c];
        }
        if (useCases != null && useCases.size() > 0) {

            // Add the use cases to the NFR request.
            String allSelectedUseCases = '';
            for (String useCase : useCases) {
                allSelectedUseCases += useCase + ';';
            }
            NFR_Request.Use_Case__c = allSelectedUseCases;

            System.debug('>>>>>>>>>> testing skumatrix');
            if (skumatrix != null) {
                System.debug('>>>>>>>>>> skumatrix size: ' + skumatrix.size());
            } else {
                System.debug('>>>>>>>>>> skumatrix is null.');
            }
            if (skumatrix != null && skumatrix.size() <> 0) {
                if (agreeToTerms) {
                    newNFRProducts = new LIST<NFR_SKU_Matrix__c>();
                    for (Integer i = 0; i < skumatrix.size(); i++) {
                        if (skumatrix.get(i).Default_Quantity__c.intValue() < 1) {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.NFR_Product_Quantity_At_Least_1));
                            return null;
                        }
                        if (skumatrix.get(i).Selected__c == true && skumatrix.get(i).Default_Quantity__c.intValue() > 0) {
                            newNFRProducts.add(skumatrix.get(i));
                            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> NFR Product: ' + newNFRProducts[newNFRProducts.size() - 1].Name + ' | ' + newNFRProducts[newNFRProducts.size() - 1].Product_Family__c);
                        }
                    }
                    try {
                        if (newNFRProducts != null && newNFRProducts.size() > 0) {
                            // Cycle through products selected and sort them into separate lists for each product family.
                            for (NFR_SKU_Matrix__c newNFRProduct : newNFRProducts) {
                                Integer currentNFRProductsList = -1;
                                if (String.isEmpty(newNFRProduct.Product_Family__c)) {
                                    newNFRProduct.Product_Family__c = 'Not Specified';
                                }
                                for (Integer index = 0; index < sortedNFRProducts.size(); index++) {
                                    String sortedNFRProductFamily = sortedNFRProducts[index][0].Product_Family__c;
                                    if (String.isEmpty(sortedNFRProductFamily)) {
                                        sortedNFRProductFamily = 'Not Specified';
                                    }
                                    if (!String.isEmpty(sortedNFRProductFamily) && sortedNFRProductFamily.equalsIgnoreCase(newNFRProduct.Product_Family__c)) {
                                        currentNFRProductsList = index;
                                    }
                                }
                                if (currentNFRProductsList < 0) {
                                    sortedNFRProducts.add(new List<NFR_SKU_Matrix__c>());
                                    currentNFRProductsList = sortedNFRProducts.size() - 1;
                                }
                                sortedNFRProducts[currentNFRProductsList].add(newNFRProduct);
                            }
                            List<NFR_Request__c> nfrRequestsToInsert = new List<NFR_Request__c>();
                            List<NFR_LI__c> nfrLineItemsToInsert = new List<NFR_LI__c>();
                            List<String> productsExceedingMaximumQuantity = new List<String>();
                            // Cycle through the sorted list of products and create an NFR request
                            // for each product family and associate the appropriate line items.
                            for (List<NFR_SKU_Matrix__c> productList : sortedNFRProducts) {
                                NFR_Request__c currentNFRRequest = new NFR_Request__c();
                                currentNFRRequest.Product_Family__c = productList[0].Product_Family__c;
                                currentNFRRequest.Use_Case__c = allSelectedUseCases;
                                currentNFRRequest.Status__c = 'Draft';
                                currentNFRRequest.User_RHN_Entitlement_Login__c = partnerUser.FederationIdentifier;
                                currentNFRRequest.Contact_at_Partner__c = NFR_Request.Contact_at_Partner__c;
                                currentNFRRequest.Partner__c = NFR_Request.Partner__c;
                                currentNFRRequest.Account_Owner__c = NFR_Request.Account_Owner__c;
                                currentNFRRequest.Partner_Status__c = partnerTypeAndTier;
                                currentNFRRequest.Comments__c = NFR_Request.Comments__c;
                                Set<String> exclist = new Set<String>();
                                for (NFR_SKU_Matrix__c nfrProduct : productList) {
                                    NFR_LI__c NFRProducts = new NFR_LI__c();
                                    if (nfrProduct.Default_Quantity__c <> null) {
                                        NFRProducts.Quantity__c = nfrProduct.Default_Quantity__c;
                                    } else {
                                        NFRProducts.Quantity__c = 1;
                                    }
                                    NFRProducts.Configured_SKU__c = nfrProduct.Configured_SKU__c;
                                    NFRProducts.Product__c = nfrProduct.Product__r.Id;
                                    NFRProducts.NFR_Product_Name__c = nfrProduct.Name;
                                    NFRProducts.Product_Family__c = nfrProduct.Product_Family__c;
                                    nfrLineItemsToInsert.add(NFRProducts);

                                    Decimal activeQuantity = getTotalActiveSubscriptions(NFRProducts);
                                    Decimal totalCount = activeQuantity + NFRProducts.Quantity__c;
                                    System.debug('>>>>>>>>>> Total count for ' + NFRProducts.Configured_SKU__c + ': ' + totalCount + ' Max allowed: ' + nfrProduct.Max_Quantity__c);

                                    // Tag the NFR Request with any rule exceptions.
                                    if (totalCount > nfrProduct.Max_Quantity__c) {
                                        exclist.add(EXC_MAX_QUANTITY);
                                        productsExceedingMaximumQuantity.add(System.Label.NFR_Active_Quantity + activeQuantity + System.Label.NFR_Requested_Quantity + NFRProducts.Quantity__c.intValue() + System.Label.NFR_Exceeds_Maximum + nfrProduct.Max_Quantity__c + System.Label.NFR_For + ' ' + NFRProducts.NFR_Product_Name__c + System.Label.NFR_Additional_Approval);
                                    }
                                    if (nfrProduct.Enablement_Prerequisite__c) {
                                        exclist.add(EXC_ENABLEMENT_PREREQUISITE);
                                    }
                                    if (nfrProduct.Is_Internal_only__c) {
                                        exclist.add(EXC_SPECIAL_APPROVAL);
                                    }
                                    currentNFRRequest.Rule_Exceptions__c = PartnerUtil.joinArray(new List<String>(exclist), ';');
                                    if (!String.isEmpty(currentNFRRequest.Rule_Exceptions__c)) {
                                        currentNFRRequest.Additional_Approval__c = true;
                                    }
                                }
                                nfrRequestsToInsert.add(currentNFRRequest);
                            }

                            //make a list of applicable shell customer accounts' record types from custom settings
                            List<AccountRecordType__c> accountRecordTypeSettings = AccountRecordType__c.getAll().values();
                            Set<String> salesAccountTypes = new Set<String>();
                            if(accountRecordTypeSettings != null) {
                                for (AccountRecordType__c recType : accountRecordTypeSettings) {
                                    if (recType.Customer_Account__c == true) {
                                        salesAccountTypes.add(recType.RecordTypeId__c);
                                    }
                                }
                            }
                            System.debug('****Account recordtypes'+salesAccountTypes.size());

                            //get the customer shell account on which the contact needs to be copied onto
                            if (NFR_Request.Partner__c != null) {
                                Id CDHPartnerId = [select CDH_Party_Name__c from Account where id = :NFR_Request.Partner__c].CDH_Party_Name__c;
                                System.debug('****CDH Party ID:'+CDHPartnerId);
                                List<Account> relatedAccounts = [select id
                                                                        from Account
                                                                        where RecordTypeId in: salesAccountTypes
                                                                        and CDH_Party_Name__c = :CDHPartnerId];
                                System.debug('****Accounts related: '+relatedAccounts.size());

                                //get email & other info from the contact which is associated to the current (In-flight) NFR Request:
                                if(relatedAccounts.size() > 0) {
                                    Contact nfrContact = [select id,
                                                                 Firstname,
                                                                 Lastname,
                                                                 Email,
                                                                 LoginName__c,
                                                                 DoNotCall,
                                                                 HasOptedOutOfEmail,
                                                                 Do_Not_Contact__c,
                                                                 OwnerId,
                                                                 CDH_Party__c
                                                            from Contact
                                                            where id = :NFR_Request.Contact_at_Partner__c];

                                    //Duplicate check: Check if there's already a contact exists on the sister sales account with the email
                                    // of the current NFR request's Contact Email:
                                    List<Contact> selectedContact = [select Email
                                                                     from Contact
                                                                     where Email =: nfrContact.Email
                                                                     and accountId in: relatedAccounts];
                                    System.debug('****Contacts found : '+selectedContact.size()+ 'with email'+ nfrContact.Email);

                                    //copy the existing partner contact onto the shell account:
                                    if(selectedContact.size() == 0) {
                                        Contact clonedContact = new Contact();
                                        clonedContact.Firstname = nfrContact.Firstname;
                                        clonedContact.Lastname = nfrContact.Lastname;
                                        clonedContact.Email = nfrContact.Email;
                                        clonedContact.LoginName__c = nfrContact.LoginName__c;
                                        clonedContact.DoNotCall = true;
                                        clonedContact.HasOptedOutOfEmail = true;
                                        clonedContact.Do_Not_Contact__c = true;
                                        clonedContact.OwnerId = nfrContact.OwnerId;
                                        clonedContact.CDH_Party__c = nfrContact.CDH_Party__c;
                                        //Contact clonedContact = nfrContact.clone(false, false, false);
                                        //System.debug('****Contact Lastname'+clonedContact.Lastname);

                                        clonedContact.accountId = relatedAccounts[0].id;
                                        insert clonedContact;
                                    }
                                }
                            }



                            // Insert NFR Requests and Line Items into the database.
                            insert nfrRequestsToInsert;
                            // Set the NFR ids on the line items.
                            for (Integer counter = 0; counter < nfrLineItemsToInsert.size(); counter++) {
                                for (NFR_Request__c nfrRequest : nfrRequestsToInsert) {
                                    if (nfrLineItemsToInsert[counter].Product_Family__c.equalsIgnoreCase(nfrRequest.Product_Family__c)) {
                                        nfrLineItemsToInsert[counter].NFR__c = nfrRequest.Id;
                                    }
                                }
                            }
                            insert nfrLineItemsToInsert;

                            // Submit NFR requests for approval.
                            List<Approval.ProcessSubmitRequest> reqs = new List<Approval.ProcessSubmitRequest>();
                            for (NFR_Request__c nfrRequest : nfrRequestsToInsert) {
                                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                                req.setComments('NFR submit from a Partner');
                                req.setObjectId(nfrRequest.Id);
                                reqs.add(req);
                            }

                            List<Approval.ProcessResult> results = Approval.process(reqs, false);
                            for (Approval.ProcessResult result : results) {
                                if (result.isSuccess()) {
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.INFO, System.Label.NFRSubmitted));
                                } else {
                                    // this only hides the real errors. SF will tell us if this is the case already
                                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, System.Label.NFRFailTosubmit));
                                    return null;
                                }
                            }

                            if (productsExceedingMaximumQuantity.size() > 0) {
                                maxQuantityExceeded = true;
                                for (String message : productsExceedingMaximumQuantity) {
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.INFO, message));
                                }
                                return null;
                            } else {
                                return showListOfNFRs();
                            }
                        } else {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, System.Label.NFRErrorNeedProducts));
                            return Page.NFRPageLayout;
                        }
                    } catch (DMLException e) {
                        System.debug('>>>>>>>>>>>>>>>>>>>>>>> Error: ' + e);
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.NFRErrorCreating));
                        return null;
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.NFR_Must_Agree));
                    return Page.NFRPageLayout;
                }
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, System.Label.NFRErrorNeedProducts));
                return Page.NFRPageLayout;
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.NFR_At_Least_One_Use_Case));
            return Page.NFRPageLayout;
        }
    }

    public PageReference cancel() {
        PageReference pageRef = new PageReference('/a1b/o');
        pageref.setRedirect(true);
        return pageRef;
    }

    public Decimal getTotalActiveSubscriptions(NFR_LI__c NFRProducts) {

        // Total the quantity of active subscriptions for each product.
        Decimal totalCount = 0;
        for (NFR_LI__c lineItem : activeNFRLineItems) {
            if (lineItem.Configured_SKU__c.equalsIgnoreCase(NFRProducts.Configured_SKU__c)) {
                totalCount += lineItem.Quantity__c;
            }
        }

        return totalCount;
    }

    public String rhnLogin {
        get {
            String retVal = '';
            if (NFR_Request != null) {
                List<User> selectedUser = [
                    select  FederationIdentifier,
                            ContactId
                    from    User
                    where   ContactId = :NFR_Request.Contact_at_Partner__c
                    limit   1
                ];
                if (selectedUser != null && selectedUser.size() > 0) {
                    retVal = selectedUser[0].FederationIdentifier;
                }
            }
            return retVal;
        }
    }

    public String partnerTypeAndTier {
        get {
            if (NFR_Request.Partner__c == null) {
                updatePartnerAccountId();
            }
            String retVal = '';
            if (partnerAccount != null) {
                retVal = partnerAccount.Finder_Partner_Tier__r.Name + ' ' + partnerAccount.Finder_Partner_Type__r.Name;
            }
            return retVal;
        }
    }

    public List<SelectOption> getUseCaseNames() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = NFR_Request__c.Use_Case__c.getDescribe();
        List<Schema.PicklistEntry> pickListEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : pickListEntries) {
            options.add(new SelectOption(entry.getLabel(), entry.getValue()));
        }

        return options;
    }

    public void updatePartnerAccountId() {
        oldPartnerAccountId = partnerAccountId;
        List<Account> accounts = [select Name,
                            Id,
                            OwnerId,
                            Global_Region__c,
                            Finder_Partner_Type__c,
                            Finder_Partner_Tier__c,
                            Finder_Partner_Type__r.Name,
                            Finder_Partner_Tier__r.Name,
                            Finder_Partner_Type_Name__c,
                            Finder_Partner_Tier_Name__c,
                            OEM_Tier__c
                            from Account where id = :NFR_Request.Partner__c limit 1];
        partnerAccount = null;
        partnerAccountId = null;
        if (accounts != null && accounts.size() > 0) {
            partnerAccount = accounts[0];
            partnerAccountId = partnerAccount.Id;
            if (oldPartnerAccountId != partnerAccountId) {
                skuMatrixEstablished = false;
                NFR_Request.Partner__c = partnerAccount.Id;
                NFR_Request.Account_Owner__c = partnerAccount.OwnerId;
                getActiveNFRLineItems();
                skumatrix = setUpSKUMatrix();
            }
        }
    }

    public PageReference setPartnerId() {
        String tmp = ApexPages.currentPage().getParameters().get('partnerId');
        if (tmp != null && tmp.startsWith('000') == false) {
            NFR_Request.Partner__c = tmp;
            System.debug('*****[debug]***** set partner__c 1');
        }
        else {
            return null;
        }
        updatePartnerAccountId();
        return null;
    }

    public List<NFR_SKU_Matrix__c> setUpSKUMatrix() {
        if (!skuMatrixEstablished) {
            tempSKUMatrix.clear();
            try {
                if (partnerAccount != null) {
                    skumatrixoriginal = [select Id,
                                            Additional_Rules__c,
                                            Selected__c,
                                            Configured_SKU__c,
                                            Product_Code__c,
                                            Product_Description__c,
                                            Product_Family__c,
                                            Name,
                                            OEM_Tier__c,
                                            Default_Quantity__c,
                                            Enablement_Prerequisite__c,
                                            Max_Quantity__c,
                                            Partner_Type__c,
                                            Partner_Tier__c,
                                            Global_Region__c,
                                            Product__r.Name,
                                            Product__r.Id,
                                            Is_Internal_only__c
                                            from NFR_SKU_Matrix__c
                                            where Global_Region__c = :partnerAccount.Global_Region__c];
                    newNFRProducts = new List<NFR_SKU_Matrix__c>();
                    if (skumatrixoriginal != null && skumatrixoriginal.size() > 0) {
                        for (Integer i = 0; i < skumatrixoriginal.size(); i++) {

                            // Count up all the same SKUs from other active NFRs.
                            skumatrixoriginal.get(i).Active_Line_Items__c = countMatchingLineItems(skumatrixoriginal.get(i).Configured_SKU__c);

                            if (isPartnerUser && skumatrixoriginal.get(i).Is_Internal_only__c) {
                                // Do nothing -- Partner users should not see internal-only skus.
                            } else {
                                System.debug('>>>>>>>>>>>>>>> OEM Tier for product / partner: ' + skumatrixoriginal.get(i).OEM_Tier__c + '  ' + partnerAccount.OEM_Tier__c);
                                if (partnerAccount.Finder_Partner_Type_Name__c.equalsIgnoreCase('OEM') && !String.isEmpty(skumatrixoriginal.get(i).Partner_Tier__c) && (skumatrixoriginal.get(i).OEM_Tier__c != partnerAccount.OEM_Tier__c)) {
                                    // Do nothing -- OEM partners should not see skus that do not match thier OEM tier.
                                } else {
                                    if (skumatrixoriginal.get(i).Partner_Tier__c == null && skumatrixoriginal.get(i).Partner_Type__c == null) {
                                        tempSKUMatrix.add(skumatrixoriginal.get(i));
                                        System.debug('NFR SKU matrix----' + tempSKUMatrix);
                                    } else if (skumatrixoriginal.get(i).Partner_Tier__c == partnerAccount.Finder_Partner_Tier__c && skumatrixoriginal.get(i).Partner_Type__c == partnerAccount.Finder_Partner_Type__c) {
                                        tempSKUMatrix.add(skumatrixoriginal.get(i));
                                        System.debug('NFR SKU matrix----' + tempSKUMatrix);
                                    } else if (skumatrixoriginal.get(i).Partner_Tier__c == null && skumatrixoriginal.get(i).Partner_Type__c == partnerAccount.Finder_Partner_Type__c) {
                                        tempSKUMatrix.add(skumatrixoriginal.get(i));
                                        System.debug('NFR SKU matrix----' + tempSKUMatrix);
                                    }
                                }
                            }
                        }
                    }
                    skuMatrixEstablished = true;
                }
            } catch (Exception e) {
                System.debug('Error: ' + e);
            }
        }
        return sortSKUMatrix(tempSKUMatrix);
    }

    private Decimal countMatchingLineItems(String configuredSKU) {
        Decimal count = 0;
        for (NFR_LI__c activeNFRLineItem : activeNFRLineItems) {
            System.debug('>>>>>>>>>> active line item: ' + activeNFRLineItem.Configured_SKU__c);
            if (activeNFRLineItem.Configured_SKU__c.trim().equalsIgnoreCase(configuredSKU.trim())) {
                count += activeNFRLineItem.Quantity__c;
            }
        }
        return count;
    }

    private void getActiveNFRLineItems() {
        // Get all the NFR line items on active NFRs associated with the account.
        activeNFRLineItems = [
            select  Product__c,
                    Product__r.Name,
                    Configured_SKU__c,
                    Quantity__c,
                    NFR__c,
                    NFR__r.Active__c,
                    NFR__r.Partner__c
            from    NFR_LI__c
            where   NFR__r.Active__c = true
            and     NFR__r.Partner__c = :NFR_Request.Partner__c
        ];
        System.debug('>>>>>>>>>> Active NFR line items: ' + activeNFRLineItems.size());
    }

    private PageReference showListOfNFRs() {
        editmode=false;
        PageReference pageRef = new PageReference('/a1b/o');
        pageref.setRedirect(true);
        return pageRef;
    }

    private List<NFR_SKU_Matrix__c> sortSKUMatrix(List<NFR_SKU_Matrix__c> tempSKUMatrix) {
        List<NFR_SKU_Matrix__c> internalItems = new List<NFR_SKU_Matrix__c>();
        List<NFR_SKU_Matrix__c> externalItems = new List<NFR_SKU_Matrix__c>();
        for (NFR_SKU_Matrix__c item : tempSKUMatrix) {
            if (item.Is_Internal_only__c) {
                internalItems.add(item);
            } else {
                externalItems.add(item);
            }
        }
        internalItems = sortList(internalItems);
        externalItems = sortList(externalItems);
        externalItems.addAll(internalItems);
        return externalItems;
    }

    private List<NFR_SKU_Matrix__c> sortList(List<NFR_SKU_Matrix__c> itemList) {
        for (Integer x = 0; x < itemList.size() - 1; x++) {
            for (Integer y = x + 1; y < itemList.size(); y++) {
                NFR_SKU_Matrix__c item1 = itemList.get(x);
                NFR_SKU_Matrix__c item2 = itemList.get(y);
                System.debug('product item name: ' + item1.Name);
                if (item1.Name.compareTo(item2.Name) > 0) {
                    itemList.set(x, item2);
                    itemList.set(y, item1);
                }
            }
        }
        return itemList;
    }
}