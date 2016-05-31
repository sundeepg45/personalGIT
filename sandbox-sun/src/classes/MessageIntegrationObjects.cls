/*****************************************************************************************
    Name    : MessageIntegrationObjects
    Desc    : This class is a temporary adapter between IntegrationObjects and the new
              message formats that include a number of renamed properties.

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Scott Coleman         2014-09-16       Created
    Scott Coleman         2014-10-09       Added support for PartnerClassifications
    Scott Coleman         2015-03-17       Removed hierachy fields from top level of SalesAccount, added new relationships object
    Scott Coleman         2015-08-26       US69276 Support for ID arrays (parsing layer only) for CDH Party Merge
******************************************************************************************/

public class MessageIntegrationObjects {

/*************************************************************************************************
 
 Temporary adapter classes compatible with message property name updates. In time these new 
 property names should be moved into the classes in IntegrationObjects and all references updated, 
 otherwise we incur an effort multipler on any changes to integration object properties.

 *************************************************************************************************/
    public virtual class SimpleTransactionalAccount {
        public String AccountNumber;
        public Boolean PrimaryEBSAccount;
        public String Status;
        public String AccountType;
        public String AccountDescription;
        public String CDHPartyNumber;
        public String PartyType;
        public String Name;
        public String EBSPartyNumber;
        public String EBSPartyName;
        public String SalesChannel;
        public String Classification;
        public Boolean CreditHold;
        public Date LastCreditReviewDate;
        public Date NextCreditReviewDate;
        public String CreditReviewCycle;
    }

    public class TransactionalAccount extends SimpleTransactionalAccount {
        public String SalesAccount;

        public IntegrationObjects.TransactionalAccount getIOTransactionalAccount() {
            IntegrationObjects.TransactionalAccount account = new IntegrationObjects.TransactionalAccount();
            account.Account_Number = this.AccountNumber;
            account.Primary_EBS_Account = this.PrimaryEBSAccount;
            account.Status = this.Status;
            account.Account_Type = this.AccountType;
            account.Account_Description = this.AccountDescription;
            account.CDH_Party_Number = this.CDHPartyNumber;
            account.PartyType = this.PartyType;
            account.Name = this.Name;
            account.EBS_Party_Number = this.EBSPartyNumber;
            account.EBS_Party_Name = this.EBSPartyName;
            account.Sales_Channel = this.SalesChannel;
            account.Classification = this.Classification;
            account.Credit_hold = this.CreditHold;
            account.Last_Credit_Review_Date = this.LastCreditReviewDate;
            account.Next_Credit_Review_Date = this.NextCreditReviewDate;
            account.Credit_Review_Cycle = this.CreditReviewCycle;
            account.Sales_Account = this.SalesAccount;
            return account;
        }

        public void setIOTransactionalAccount(IntegrationObjects.TransactionalAccount account) {
            this.AccountNumber = account.Account_Number;
            this.PrimaryEBSAccount = account.Primary_EBS_Account;
            this.Status = account.Status;
            this.AccountType = account.Account_Type;
            this.AccountDescription = account.Account_Description;
            this.CDHPartyNumber = account.CDH_Party_Number;
            this.PartyType = account.PartyType;
            this.Name = account.Name;
            this.EBSPartyNumber = account.EBS_Party_Number;
            this.EBSPartyName = account.EBS_Party_Name;
            this.SalesChannel = account.Sales_Channel;
            this.Classification = account.Classification;
            this.CreditHold = account.Credit_hold;
            this.LastCreditReviewDate = account.Last_Credit_Review_Date;
            this.NextCreditReviewDate = account.Next_Credit_Review_Date;
            this.CreditReviewCycle = account.Credit_Review_Cycle;
            this.SalesAccount = account.Sales_Account;
        }        
    }

    public class Contact {
        public List<Id> IDs;
        public String SalesAccountId;
        public String SalesAccountCDHPartyNumber;
        public String CDHPartyNumber;
        public String LoginName;
        public String FirstName;
        public String LastName;
        public String Salutation;
        public String Status;
        public String Email;
        public String Phone;
        public String MobilePhone;
        public String Fax;

        public IntegrationObjects.Contact getIOContact() {
            IntegrationObjects.Contact contact = new IntegrationObjects.Contact();
            if(this.IDs != null && !this.IDs.isEmpty()) {
                contact.IDs = this.IDs[0];
                contact.IDList = this.IDs;
            }
            contact.SalesAccount_Id = this.SalesAccountId;
            contact.SalesAccount_CDH_Party_Number = this.SalesAccountCDHPartyNumber;
            contact.CDH_Party_Number = this.CDHPartyNumber;
            contact.LoginName = this.LoginName;
            contact.FirstName = this.FirstName;
            contact.LastName = this.LastName;
            contact.Salutation = this.Salutation;
            contact.Status = this.Status;
            contact.Email = this.Email;
            contact.Phone = this.Phone;
            contact.MobilePhone = this.MobilePhone;
            contact.Fax = this.Fax;
            return contact;
        }

        public void setIOContact(IntegrationObjects.Contact contact) {
            this.IDs = null;
            if (contact.IDs != null) {
                this.IDs = new List<Id>{contact.IDs};
            }
            this.SalesAccountId = contact.SalesAccount_Id;
            this.SalesAccountCDHPartyNumber = contact.SalesAccount_CDH_Party_Number;
            this.CDHPartyNumber = contact.CDH_Party_Number;
            this.LoginName = contact.LoginName;
            this.FirstName = contact.FirstName;
            this.LastName = contact.LastName;
            this.Salutation = contact.Salutation;
            this.Status = contact.Status;
            this.Email = contact.Email;
            this.Phone = contact.Phone;
            this.MobilePhone = contact.MobilePhone;
            this.Fax = contact.Fax;
        }
    }

    public class Address {
        public List<Id> IDs;
        public String CDHPartySiteNumber;
        public String AddressLine1;
        public String AddressLine2;
        public String AddressLine3;
        public String AddressLine4;
        public String City;
        public String State;
        public String Province;
        public String ZipPostalCode;
        public String County;
        public String Country;
        public Boolean BillToAddress;
        public Boolean SoldToAddress;
        public Boolean ShipToAddress;
        public Boolean EntitleToAddress;
        public Boolean IdentifyingAddress;
        public String Status;

        public IntegrationObjects.Address getIOAddress() {
            IntegrationObjects.Address address = new IntegrationObjects.Address();
            if(this.IDs != null && !this.IDs.isEmpty()) {
                address.IDs = this.IDs[0];
                address.IDList = this.IDs;
            }
            address.CDH_Party_Site_Number = this.CDHPartySiteNumber;
            address.Address_Line1 = this.AddressLine1;
            address.Address_Line2 = this.AddressLine2;
            address.Address_Line3 = this.AddressLine3;
            address.Address_Line4 = this.AddressLine4;
            address.City = this.City;
            address.State = this.State;
            address.Province = this.Province;
            address.Zip_Postal_Code = this.ZipPostalCode;
            address.County = this.County;
            address.Country = this.Country;
            address.Bill_To_Address = this.BillToAddress;
            address.Sold_To_Address = this.SoldToAddress;
            address.Ship_To_Address = this.ShipToAddress;
            address.Entitle_To_Address = this.EntitleToAddress;
            address.Identifying_Address = this.IdentifyingAddress;
            address.Status = this.Status;
            return address;
        }

        public void setIOAddress(IntegrationObjects.Address address) {
            this.IDs = null;
            if (address.IDs != null) {
                this.IDs = new List<Id>{address.IDs};
            }
            this.CDHPartySiteNumber = address.CDH_Party_Site_Number;
            this.AddressLine1 = address.Address_Line1;
            this.AddressLine2 = address.Address_Line2;
            this.AddressLine3 = address.Address_Line3;
            this.AddressLine4 = address.Address_Line4;
            this.City = address.City;
            this.State = address.State;
            this.Province = address.Province;
            this.ZipPostalCode = address.Zip_Postal_Code;
            this.County = address.County;
            this.Country = address.Country;
            this.BillToAddress = address.Bill_To_Address;
            this.SoldToAddress = address.Sold_To_Address;
            this.ShipToAddress = address.Ship_To_Address;
            this.EntitleToAddress = address.Entitle_To_Address;
            this.IdentifyingAddress = address.Identifying_Address;
            this.Status = address.Status;
        }
    }

    public virtual class SimpleSalesAccount {
        public List<Id> IDs;
        public String CDHPartyNumber;
        public String Name;
        public String CDHPartyType;
        public String VATNumber;
        public String DUNS;
        public String Status;
        public String Sic;
        public String SicDesc;
        public String AllNAICSCodes;
        public Boolean DoNotDoBusinessWith;
        public String SEAConcern;
        public String TradeStyle;
        public String YearStarted;
        public Integer NumberOfEmployees;
        public Decimal AnnualRevenue;
        public String Website;
        public String Phone;
        public String Fax;
        public String LinkedinUrl;
        public String KnownAs;
    }

    public class SalesAccount extends SimpleSalesAccount {      
        public List<Contact> Contacts;
        public List<Address> Addresses;
        public List<IntegrationObjects.Classification> PartnerClassifications;
        public Relationships CorporateRelationships;

        public IntegrationObjects.SalesAccount getIOSalesAccount() {
            IntegrationObjects.SalesAccount account = new IntegrationObjects.SalesAccount();
            if(this.IDs != null && !this.IDs.isEmpty()) {
                account.IDs = this.IDs[0];
                account.IDList = this.IDs;
            }
            account.CDH_Party_Number = this.CDHPartyNumber;
            account.Name = this.Name;
            account.CDH_Party_Type = this.CDHPartyType;
            account.VATNumber = this.VATNumber;
            account.D_U_N_S = this.DUNS;
            account.Status = this.Status;
            account.Sic = this.Sic;
            account.SicDesc = this.SicDesc;
            account.All_NAICS_Codes = this.AllNAICSCodes;
            account.Do_Not_Do_Business_with = this.DoNotDoBusinessWith;
            account.SEA_Concern = this.SEAConcern;
            account.Trade_Style = this.TradeStyle;
            account.YearStarted = this.YearStarted;
            account.NumberOfEmployees = this.NumberOfEmployees;
            account.AnnualRevenue = this.AnnualRevenue;
            account.Website = this.Website;
            account.Phone = this.Phone;
            account.Fax = this.Fax;
            account.Linkedin_URL = this.LinkedinUrl;
            account.KnownAs = this.KnownAs;
            account.PartnerClassifications = this.PartnerClassifications;

            if(this.CorporateRelationships != null) {
                account.CorporateRelationships = new IntegrationObjects.Relationships();
                account.CorporateRelationships.DomesticUltimate = this.CorporateRelationships.DomesticUltimate.getIORelationship();
                account.CorporateRelationships.GlobalUltimate = this.CorporateRelationships.GlobalUltimate.getIORelationship();
                if(this.CorporateRelationships.HeadQuarters != null && this.CorporateRelationships.HeadQuarters.CDHPartyNumber != null) {
                    account.CorporateRelationships.HeadQuartersOrParent = this.CorporateRelationships.HeadQuarters.getIORelationship();
                }
                else {
                    account.CorporateRelationships.HeadQuartersOrParent = this.CorporateRelationships.Parent.getIORelationship();
                }
            }

            if(this.Contacts != null && !this.Contacts.isEmpty()) {
                account.Contacts = new List<IntegrationObjects.Contact>();
                for(Contact contact : this.Contacts) {
                    account.Contacts.add(contact.getIOContact());
                }
            }

            if(this.Addresses != null && !this.Addresses.isEmpty()) {
                account.Addresses = new List<IntegrationObjects.Address>();
                for(Address address : this.Addresses) {
                    account.Addresses.add(address.getIOAddress());
                }
            }

            return account;
        }

        public void setIOSalesAccount(IntegrationObjects.SalesAccount account) {
            this.IDs = null;
            if (account.IDs != null) {
                this.IDs = new List<Id>{account.IDs};
            }
            this.CDHPartyNumber = account.CDH_Party_Number;
            this.Name = account.Name;
            this.CDHPartyType = account.CDH_Party_Type;
            this.VATNumber = account.VATNumber;
            this.DUNS = account.D_U_N_S;
            this.Status = account.Status;
            this.Sic = account.Sic;
            this.SicDesc = account.SicDesc;
            this.AllNAICSCodes = account.All_NAICS_Codes;
            this.DoNotDoBusinessWith = account.Do_Not_Do_Business_with;
            this.SEAConcern = account.SEA_Concern;
            this.TradeStyle = account.Trade_Style;
            this.YearStarted = account.YearStarted;
            this.NumberOfEmployees = account.NumberOfEmployees;
            this.AnnualRevenue = account.AnnualRevenue;
            this.Website = account.Website;
            this.Phone = account.Phone;
            this.Fax = account.Fax;
            this.LinkedinUrl = account.Linkedin_URL;
            this.KnownAs = account.KnownAs;
            this.PartnerClassifications = account.PartnerClassifications;
            this.CorporateRelationships = null;

            this.Contacts = null;
            if(account.Contacts != null && !account.Contacts.isEmpty()) {
                this.Contacts = new List<Contact>();
                for(IntegrationObjects.Contact contact : account.Contacts) {
                    Contact messageContact = new Contact();
                    messageContact.setIOContact(contact);
                    this.Contacts.add(messageContact);
                }
            }

            this.Addresses = null;
            if(account.Addresses != null && !account.Addresses.isEmpty()) {
                this.Addresses = new List<Address>();
                for(IntegrationObjects.Address address : account.Addresses) {
                    Address messageAddress = new Address();
                    messageAddress.setIOAddress(address);
                    this.Addresses.add(messageAddress);
                }
            }
        }
    }

    public class Relationships {
        public Relationship DomesticUltimate;
        public Relationship GlobalUltimate;
        public Relationship HeadQuarters;
        public Relationship Parent;
    }

    public class Relationship {
        public String CDHPartyNumber;
        public String DUNS;
        public String Name;

        public IntegrationObjects.Relationship getIORelationship() {
            IntegrationObjects.Relationship relationship = new IntegrationObjects.Relationship();
            relationship.CDHPartyNumber = this.CDHPartyNumber;
            relationship.DUNS = this.DUNS;
            relationship.Name = this.Name;
            relationship.SalesAccountId = null; //for now this attribute is not in the message
            return relationship;
        }
    }
}