/**
 * The controller extension used by the Global Order Management Form.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2012-07-11
 * 2012-07-11 - Added PriceOverrideReason__c to the line item query.
 */ 
public class GlobalOrderManagementControllerExtension {
    private final Opportunity opportunity;
    private final Contact shippingContact;
    private final Contact payableContact;
    private final Boolean isEMEA;
    private final Boolean isLATAM;
    private final Boolean isAPAC;
    private final Boolean isNA;
    private Boolean needQuoteContact = true;
    private Contact quoteContact = null;
    private Credit__c credit = null;
    private List<ApprovalCustom__c> recentApprovalCustomList = null;
    private List<OpportunityLineItem> opportunityLineItemList = null;

    /**
     * Extension constructor.
     */
    public GlobalOrderManagementControllerExtension(ApexPages.StandardController stdController)
    {
/*      this.opportunity = [select 
                            Id,
                            Name,
                            Super_Region__c,
                            Owner.Region__c,
                            ContractStartDate__c,
                            ContractEndDate__c,
                            ExpirationDate__c,
                            ShippingAddress__c,
                            ShippingCity__c,
                            ShippingState__c,
                            ShippingZipPostalCode__c,
                            ShippingCountry__c,
                            BillingAddress__c,
                            BillingCity__c,
                            BillingState__c,
                            BillingZipPostalCode__c,
                            BillingCountry__c,
                            PONumber__c,
                            Pay_Now__c,
                            NameOnCard__c,
                            Credit_Card_Number__c,
                            CreditCardType__c,
                            CurrencyISOCode,
                            Year1PaymentAmount__c,
                            Year2PaymentAmount__c,
                            Year3PaymentAmount__c,
                            Year4PaymentAmount__c,
                            Year5PaymentAmount__c,
                            Year6PaymentAmount__c,
                            PO_Special_Instructions__c,
                            Statement_of_Work_Reference__c
                        from Opportunity
                        where Id = :stdController.getRecord().Id];*/
        this.opportunity = (Opportunity)stdController.getRecord();
                            
                            
                            
        String name = opportunity.Super_Region__c;
        Boolean emea = (name == 'EMEA');
        Boolean latam = (name == 'LATAM');
        Boolean apac = (name == 'APAC');
        Boolean na = (name == 'NA');
        if(!(emea||latam||apac||na)) {
            name = opportunity.Owner.Region__c;
            emea = (name == 'EMEA');
            latam = (name == 'LATAM');
            apac = (name == 'APAC');
            na = (name == 'NA');
        }
        this.isEMEA = emea;
        this.isLATAM = latam;
        this.isAPAC = apac;
        this.isNA = na;
        Contact shippingContact = null;
        Contact payableContact = null;
        try
        {
            List<OpportunityContactRole> opportunityContactRoles = [select
                Role,
                Contact.Email,
                Contact.Id,
                Contact.LoginName__c,
                Contact.Name,
                Contact.Phone,
                Contact.Department
                from OpportunityContactRole
                where OpportunityId=:opportunity.Id and (Role = 'Shipping Contact' or Role = 'Payables Contact')];
            for(OpportunityContactRole opportunityContactRole : opportunityContactRoles)
            {
                if ('Shipping Contact'.equals(opportunityContactRole.Role))
                {
                    shippingContact=opportunityContactRole.Contact;
                }
                else if ('Payables Contact'.equals(opportunityContactRole.Role))
                {
                    payableContact=opportunityContactRole.Contact;
                }
            }
        }
        catch(Exception ignored) {}
        this.shippingContact = shippingContact;
        this.payableContact = payableContact;
    }

	public String getCreditCardNumber() {
		String creditCardNumber = opportunity.Credit_Card_Number__c;
		if(String.isNotBlank(creditCardNumber)) {
			creditCardNumber = creditCardNumber.replaceAll('^(....)(....)(....)(.)','$1-$2-$3-$4');
			Boolean allowed = false;
			if(String.isNotBlank(opportunity.Operating_Unit__c)) {
				GlobalOrderManagementConfig__c gomc = GlobalOrderManagementConfig__c.getInstance();
				if(gomc != null && String.isNotBlank(gomc.OperatingUnitsAllowedCCView__c) && String.isNotBlank(opportunity.Operating_Unit__c) ) {
					String re = gomc.OperatingUnitsAllowedCCView__c.replaceAll('\\s*[\\n,]+\\s*','|').toLowerCase();
					String operatingUnit=opportunity.Operating_Unit__c.toLowerCase();
					allowed = Pattern.matches('^('+re+')$',operatingUnit)
						|| Pattern.matches('^rh ('+re+') operating unit$',operatingUnit);
				}
			}
			if(!allowed) {
				creditCardNumber = creditCardNumber.replaceAll('[0-9]','*');
			}
		}
		return creditCardNumber;
	}

    /**
     * Query the credit record.
     *
     * @return the credit record.
     */
    public Credit__c getCredit()
    {
        if(this.credit == null)
        {
            if(isNA||isEMEA||isAPAC)
            {
                try {
                    Boolean flag=false;
                    List<Credit__c> creditList = [
                        select
                            A_R_Balance__c,
                            A_R_Past_Due_Amount__c,
                            BillingAccountNameUsed__c,
                            BillingAccountNumberUsed__c,
                            Comments__c,
                            Credit_Limit__c,
                            Credit_Stage__c,
                            Payment_Terms__c,
                            isFinal__c
                        from Credit__c
                        where Opportunity__c=:opportunity.Id
                        order by CreatedDate ASC ];
                    for(Credit__c credit : creditList)
                    {
                        if(credit.isFinal__c)
                        {
                            flag=true;
                        }
                        else if (flag)
                        {
                            continue;
                        }
                        this.credit = credit;
                    }
                }
                catch(Exception ignored) {}
            }
            if(this.credit == null) {
                this.credit = new Credit__c();
            }
        }
        return this.credit;
    }

    /**
     * Find out if this is an EMEA opportunity.
     *
     * @return true if EMEA
     */ 
    public Boolean getIsEMEA()
    {
        return isEMEA;
    }

    /**
     * Find out if this is an LATAM opportunity.
     *
     * @return true if LATAM
     */ 
    public Boolean getIsLATAM()
    {
        return isLATAM;
    }

    /**
     * Find out if this is an APAC opportunity.
     *
     * @return true if APAC
     */ 
    public Boolean getIsAPAC()
    {
        return isAPAC;
    }

    /**
     * Find out if this is an NA opportunity.
     *
     * @return true if NA
     */ 
    public Boolean getIsNA()
    {
        return isNA;
    }

    /**
     * Query the shipping contact.
     *
     * @return the shipping contact
     */
    public Contact getShippingContact()
    {
        return shippingContact;
    }

    /**
     * Query the payable contact.
     *
     * @return the payable contact
     */ 
    public Contact getPayableContact()
    {
        return payableContact;
    }

    /**
     * Query the payable contact.
     *
     * @return the payable contact
     */ 
    public Contact getQuoteContact()
    {
        if(needQuoteContact)
        {
            try
            {
                Quote__c activeQuote = [select
                    Id,
                    ContactId__r.Email,
                    ContactId__r.Id,
                    ContactId__r.LoginName__c,
                    ContactId__r.Name,
                    ContactId__r.Phone,
                    ContactId__r.Department
                    from Quote__c
                    where OpportunityId__c=:opportunity.Id and IsActive__c=true limit 1 ];
                quoteContact = activeQuote.ContactId__r;
            }
            catch(Exception ignored) {}
            needQuoteContact = false;
        }
        return quoteContact;
    }

    /**
     * Query the recent ApprovalCustom__c record.
     *
     * @return recent approval
     */
    public List<ApprovalCustom__c> getRecentApprovalCustomList()
    {
        if(recentApprovalCustomList == null)
        {
            try
            {
                recentApprovalCustomList = [select
                    ApprovedBy__r.Name, 
                    ApprovedByOther__c,
                    RecordType.Name,
                    ApprovalStatus__c, 
                    PricingDiscountApproved__c 
                    from ApprovalCustom__c 
                    where ApprovalStatus__c='Approved' and Quote__r.OpportunityId__c=:opportunity.Id and Quote__r.IsActive__c=true];
            }
            catch(Exception error)
            {
                recentApprovalCustomList = new List<ApprovalCustom__c>();
            }
        }
        return recentApprovalCustomList;
    }

    /**
     * Query the opportunity line items.
     *
     * @return opportunity line items
     */
    public List<OpportunityLineItem> getOpportunityLineItemList()
    {
        if(opportunityLineItemList == null)
        {
            try 
            {
                opportunityLineItemList = [select
                    Id,
                    One_Time_Discount__c,
                    Discretionary_Discount_Amount__c, 
                    Contract_Numbers__c,
                    Configured_SKU__c,
                    Description,
                    NewOrRenewal__c,
                    PricebookEntry.Name, 
                    PricebookEntry.ProductCode,
                    PricebookEntry.Product2.SKU_Type__c,
                    PricebookEntry.Product2.Description,
                    ActualStartDate__c,
                    ActualEndDate__c,
                    Base_Price__c,
                    Quantity,
                    TotalPrice,
                    UnitPrice,
                    CurrencyIsoCode,
                    PriceOverrideReason__c
                    from OpportunityLineItem 
                    where OpportunityId=:opportunity.Id ];
            }
            catch(Exception error) 
            {
                opportunityLineItemList = new List<OpportunityLineItem>();
            }
        }
        return opportunityLineItemList; 
    }

    /*
     * Used to format a date
     *
     * @param value date to format
     * @return the formatted date
     */ 
    private String formatDate(Date value)
    {
        if(value == null) {
            return '';
        }
        Datetime temp = Datetime.newInstance(value.year(), value.month(), value.day());
        return temp.format('dd-MMM-yyyy');
    }

    /**
     * Format the opportunity contract start date.
     *
     * @return the formatted contract start date.
     */
    public String getContractStartDate()
    {
        return formatDate(opportunity.ContractStartDate__c);
    }

    /**
     * Format the opportunity contract end date.
     *
     * @return the formatted contract end date.
     */
    public String getContractEndDate()
    {
        return formatDate(opportunity.ContractEndDate__c);
    }

    /**
     * Format the opportunity expiration date.
     *
     * @return the formatted expiration date.
     */
    public String getExpirationDate()
    {
        return formatDate(opportunity.ExpirationDate__c);
    }
}