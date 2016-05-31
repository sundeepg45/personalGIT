/**
 * This class is container for all Integration related apex objects
 * 
 * @version 2015-12-18
 * @author John Herson <jherson@redhat.com>
 * @since 2014-07-11 - Created
 * @author Vipul Jain
 * @since 2014-07-11 - Updated the structure of address and contact class
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2014-07-24 - Updates to SalesAccount
 * @since 2014-10-18 - Added Product class
 * @since 2014-12-09 - Added contractNumber to Order
 * @since 2015-03-15 - Added non-entitled end customer info to order
 * @since 2015-03-17 - Removed hierachy fields from top level of SalesAccount, added new relationships object
 * @author Mark Smith <masmith@redhat.com>
 * @since 2015-04-10 - Converted classification DateTime to String
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2015-12-18 - Added setters and getters to keep track of arrays of ids
 */
public class IntegrationObjects {

	/**
	 * Assign a value to the first position of a list.  The idea is we to make assignment of the
	 * first value and assignment of a list which contains that value order independant operations.
	 * So if the value is already in the list, the value will be moved to the begining of a list.  If on the 
	 * the list did not contain the value, then the list will only contain the new value.
	 * @param value
	 * @param ids
	 */
	private static void setFirstIdValue(Id value,List<Id> ids) {
		if(((value != null || ! ids.isEmpty())
			&& (value == null || ids.isEmpty() || ids[0] != value)) ) 
		{
			List<Id> idsClone = ids.clone();
			ids.clear();
			if(value != null) {
				ids.add(value);
				// adding a value that is already in the list will result in just a reordering of the list
				for(Id id0 : idsClone) {
					if(id0 == value) {
						for(Id id1 : idsClone) {
							if(id1 != value) {
								ids.add(id1);
							}
						}
						break;
					}
				}
			}
		}
	}

	/**
	 * Return the first value in the list.
	 * @param ids
	 */
	private static Id getFirstIdValue(List<Id> ids) {
		Id retval = null;
		if(ids != null && ! ids.isEmpty()) {
			retval = ids[0];
		}
		return retval;
	}

	abstract class AbstractHeader {
		public String Operation;
		public String Type;
		public Datetime Timestamp;
		public String EventKey;
		public String EsbMessageGuid;
	}

	public class Header extends AbstractHeader {

	}

	public class ErrorHeader {
		public String ErrorCode;
		public String ErrorDetails;
		public String ErrorGuid;
	}

	public class Id {
		public String ID;
	}

	public virtual class SimpleTransactionalAccount {
		public String Account_Number;
		public Boolean Primary_EBS_Account;
		public String Status;
		public String Account_Type;
		public String Account_Description;
		public String CDH_Party_Number;
		public String PartyType;
		public String Name;
		public String EBS_Party_Number;
		public String EBS_Party_Name;
		public String Sales_Channel;
		public String Classification;
		public Boolean Credit_hold;
		public Date Last_Credit_Review_Date;
		public Date Next_Credit_Review_Date;
		public String Credit_Review_Cycle;
	}

	public class TransactionalAccount extends SimpleTransactionalAccount {
		public String Sales_Account;
	}

	public class Contact {
		public Id IDs;
		public List<Id> IDList;
		// added new attribute
		public String SalesAccount_Id;
		public String SalesAccount_CDH_Party_Number;
		public String CDH_Party_Number;
		public String LoginName;
		public String FirstName;
		public String LastName;
		public String Salutation;
		public String Status;
		public String Email;
		public String Phone;
		public String MobilePhone;
		public String Fax;
	}

	public class Address {
		//public String ID;
		// added two new attributes
		public Id IDs {
			get { return getFirstIdValue(IDList); }
			set { setFirstIdValue(value,IDList); }
		}
		public List<Id> IDList {
			get {
				if(IDList == null) {
					IDList = new List<Id>();
				}
				return IDList;
			}
			set;
		}
		public String CDH_Party_Site_Number;
		public String Address_Line1;
		public String Address_Line2;
		public String Address_Line3;
		public String Address_Line4;
		public String City;
		public String State;
		public String Province;
		public String Zip_Postal_Code;
		public String County;
		public String Country;
		public Boolean Bill_To_Address;
		public Boolean Sold_To_Address;
		public Boolean Ship_To_Address;
		public Boolean Entitle_To_Address;
		public Boolean Identifying_Address;
		public String Status;
	}

	public virtual class SimpleSalesAccount {
		public Id IDs {
			get { return getFirstIdValue(IDList); }
			set { setFirstIdValue(value,IDList); }
		}
		public List<Id> IDList {
			get {
				if(IDList == null) {
					IDList = new List<Id>();
				}
				return IDList;
			}
			set;
		}
		public String CDH_Party_Number;
		public String Name;
		public String CDH_Party_Type;
		public String VATNumber;
		public String D_U_N_S;
		public String Status;
		public String Sic;
		public String SicDesc;
		public String All_NAICS_Codes;
		public Boolean Do_Not_Do_Business_with;
		public String SEA_Concern;
		public String Trade_Style;
		public String YearStarted;
		public Integer NumberOfEmployees;
		public Decimal AnnualRevenue;
		public String Website;
		public String Phone;
		public String Fax;
		public String Head_Quarters;
		public String Domestic_Ultimate;
		public String Global_Ultimate;
		public String Linkedin_URL;
		public String KnownAs;
		public Relationships CorporateRelationships;
	}

	public class SalesAccount extends SimpleSalesAccount {
		public List<Contact> Contacts;
		public List<Address> Addresses;
		public List<Classification> PartnerClassifications;
	}

	public class Classification {
		public String Code;
		public String Status;
		public String StartDate;
		public String EndDate;
	}

	public class Relationships {
		public Relationship DomesticUltimate;
		public Relationship GlobalUltimate;
		public Relationship HeadQuartersOrParent;
	}

	public class Relationship {
		public String CDHPartyNumber;
		public String DUNS;
		public String Name;
		public String SalesAccountId;
	}

	public class Order {
		public String id;
		public String orderId;
		public String orderNumber;
		public String employeeNumber ;
		public String opportunityNumber ;
		public String purchaseOrderNumber;
		public String orderType ;
		public String operatingUnit;
		public String paymentType;
		public String payNow;
		public String contractNumber;
		public String creditCardNumber;
		public Date expirationDate;
		public String creditCardType;
		public String nameOnCard;
		public String fulfillmentChannel;
		public String paymentTerms;
		public String currencyIsoCode;
		public String orderSource;
		public String orderStatus;
		public Date bookedDate;
		public Date orderedDate;
		public Date lastUpdateDate;
		public String opportunityId;
		public Decimal amount;
		public String shippingInstructions;
		public String vatCode;
		public Boolean rushOrder;
		public String resellerPurchaseOrder;
		public String nonEntitledEndcoCDHPartyNumber;
		public String nonEntitledEndcoCDHPartyName;

		public IntegrationObjects.TransactionalAccount soldToAccount;
		public IntegrationObjects.TransactionalAccount billToAccount;
		public IntegrationObjects.TransactionalAccount entitleToAccount;
		public IntegrationObjects.TransactionalAccount shipToAccount;

		public IntegrationObjects.Address soldToAddress;
		public IntegrationObjects.Address billToAddress;
		public IntegrationObjects.Address entitleToAddress;
		public IntegrationObjects.Address shipToAddress;

		public IntegrationObjects.Contact soldToContact;
		public IntegrationObjects.Contact billToContact;
		public IntegrationObjects.Contact entitleToContact;
		public IntegrationObjects.Contact shipToContact;

		public List<OrderLine> orderLines;
		public List<OrderPartner> orderPartners;
	}

	public class OrderLine {
		public String id;
		public String productCode;
		public Date actualStartDate;
		public Date actualEndDate;
		public Decimal quantity;
		public String unitOfMeasure;
		public String currencyIsoCode;
		public Decimal salesPrice ;
		public Decimal perUnitProratedPrice ;
		public String contractNumbers ;
		public String opportunityId ;
		public String opportunityLineId;
		public Decimal listPrice;
		public Decimal discretionaryDiscountedPrice ;
		public Decimal oneTimeDiscountedPrice;
		public String priceOverrideReason;
		public String installBaseNumber;
		public TransactionalAccount entitleToAccount;
		public Address entitleToAddress;
		public Contact entitleToContact;
	}

	public class OrderPartner {
		public String id;
		public String partnerType;
		public String partnerTier;
		public String classificationCode;
		public String transactionRole;
		public Contact contact;
		public SalesAccount account;
	}

	public virtual class SimpleProduct {
		public String Description;
		public String ProductCategory;
		public Boolean IsActive;
		public String Name;
		public String PrimaryBusinessUnit;
		public String PrimaryBusinessUnitSplit;
		public String ProductCode;
		public String ProductLine;
		public String QuaternaryBusinessUnit;
		public String QuaternaryBusinessUnitSplit;
		public String QuinaryBusinessUnit;
		public String QuinaryBusinessUnitSplit;
		public String SecondaryBusinessUnit;
		public String SecondaryBusinessUnitSplit;
		public String SpecialPricingValue;
		public String Term;
		public String TertiaryBusinessUnit;
		public String TertiaryBusinessUnitSplit;
		public String UnitOfMeasure;
	}

	public class Product extends SimpleProduct {
		public Map<String,String> Attribute;
	}
}