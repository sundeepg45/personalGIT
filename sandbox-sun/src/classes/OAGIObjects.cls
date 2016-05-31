/*****************************************************************************************
    Name    : OAGIObjects
    Desc    : This class is container for all OAGI order related apex objects     
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    John Herson           2014-07-11       Created
    Bill C Riemers        2015-05-01       Modified to add a partners list to USERAREA_LINE_SCH
                          2015-10-15       Both ONETIME and PARTNRIDX changed to String from Integer
******************************************************************************************/

public class OAGIObjects {
	
	public class BSR {
		public NOUN VERB;
		public NOUN NOUN;
		public String REVISION;
	}
	
	public class NOUN {
		public String content;
		public String value;
	}

    public class SENDER {
		public String LOGICALID;
		public String COMPONENT;
		public String TASK;
		public String REFERENCEID;
		public Integer CONFIRMATION;
		public String LANGUAGE;
		public String CODEPAGE;
		public String AUTHID;
	}
	
	public class DATE_TIME {
		public Integer index;
		public String qualifier;
		public String type;
		public String YEAR;
		public String MONTH;
		public String DAY;
		public String HOUR;
		public String MINUTE;
		public String SECOND;
		public String SUBSECOND;
		public String TIMEZONE;
	}

	public class DFFPOHEADER {
		public String ATTRIBUTE3;
		public String ATTRIBUTE2;
		public String ATTRIBUTE1;
		public String ATTRIBUTE13;
		public String ATTRIBUTE14;
		public String ATTRIBUTE9;
		public String ATTRIBUTE11;
		public String ATTRIBUTE8;
		public String ATTRIBUTE12;
		public String ATTRIBUTE7;
		public String ATTRIBUTE6;
		public String ATTRIBUTE10;
		public String ATTRIBUTE20;
		public String ATTRIBUTE5;
		public String ATTRIBUTE4;
		public String ATTRIBUTE19;
		public String ATTRIBUTE16;
		public String ATTRIBUTE15;
		public String ATTRIBUTE18;
		public String ATTRIBUTE17;
	}

	public class KFFITEM {
		public String ATTRIBUTE3;
		public String ATTRIBUTE2;
		public String ATTRIBUTE1;
		public String ATTRIBUTE13;
		public String ATTRIBUTE14;
		public String ATTRIBUTE9;
		public String ATTRIBUTE11;
		public String ATTRIBUTE8;
		public String ATTRIBUTE12;
		public String ATTRIBUTE7;
		public String ATTRIBUTE6;
		public String ATTRIBUTE10;
		public String ATTRIBUTE20;
		public String ATTRIBUTE5;
		public String ATTRIBUTE4;
		public String ATTRIBUTE19;
		public String ATTRIBUTE16;
		public String ATTRIBUTE15;
		public String ATTRIBUTE18;
		public String ATTRIBUTE17;
	}

	public class PARTNER {
		public String TERMID;
		public NAME NAME;
		public String ONETIME;
		public String PARTNRID;
		public ADDRESS ADDRESS;
		public String TAXID;
		public String DUNSNUMBER;
		public String PARTNRIDX;
		public CONTACT CONTACT;
		public String PARTNRTYPE;
		public String CURRENCYISOCODE;
	}

	public class QUANTITY {
		public String SIGN;
		public String VALUE;
		public String UOM;
		public String qualifier;
		public Integer NUMOFDEC;
	}

	public class USERAREA {
		public FOB FOB;
		public String CONFIRM;
		public String EXCHRATE;
		public String TANDC;
		public DFFPOHEADER DFFPOHEADER;
		public String SHIPPINGCONTROL;
		public FOB FTTERM;
		public PCARDHDR PCARDHDR;
	}

	public class SOLINESCHD {
		public String PSCLINENUM;
		public String DESCRIPTN;
		public USERAREA_LINE_SCH USERAREA;
		public QUANTITY QUANTITY;
	}

	public class OPERAMT {
		public String SIGN;
		public String UOMNUMDEC;
		public String CURRENCYISOCODE;
		public String VALUE;
		public String UOM;
		public String qualifier;
		public Integer NUMOFDEC;
		public String type;
		public Integer UOMVALUE;
	}

	public class FOB {
		public String TERMID;
		public String DESCRIPTN;
	}

	public class NAME {
		public String content;
		public Integer index;
	}

	public class ADDRESS {
		public String POSTALCODE;
		public String CURRENCYISOCODE;
		public String COUNTY;
		public String DESCRIPTN;
		public USERAREA USERAREA;
		public String COUNTRY;
		public List<NAME> ADDRLINE;
		public String TAXJRSDCTN;
		public String STATEPROVN;
		public String CITY;
		public String URL;
		public String REGION;
		public List<TELEPHONE> TELEPHONE;
		public TELEPHONE FAX;
	}

	public class PCARDHDR {
		public String PCARDBRAND;
		public String PCARDNUM;
		public String MEMBERNAME;
		public DATE_TIME DATE_TIME;
	}

	public class TELEPHONE {
		public Integer index;
		public String content;
	}

	public class CONTACT {
		public String CONTCTTYPE;
		public List<NAME> NAME;
		public String EMAIL;
		public TELEPHONE TELEPHONE;
		public TELEPHONE FAX;
	}

	public class POTERM {
		public String TERMID;
		public Integer DAYSNUM;
		public String DESCRIPTN;
		public USERAREA USERAREA;
		public QUANTITY QUANTITY;
	}

	public class USERAREA_LINE_SCH {
		public List<PARTNER> PARTNERS {
			get {
				if(PARTNERS == null) {
					PARTNERS = new List<PARTNER>();
				}
				return PARTNERS;
			}
			set;
		}
		public PARTNER PARTNER {
			get {
				PARTNER retval = null;
				for(PARTNER p : PARTNERS) {
					retval = p;
					break;
				}
				return retval;
			}
			set {
				if(PARTNERS.isEmpty()) {
					if(value != null) {
						PARTNERS.add(value);
					}
				} else if(value == null) {
					PARTNERS.remove(0);
				}
				else {
					PARTNERS.set(0,value);
				}
			}
		}
		public String TAXCODE;
		public Boolean TAXABLE;
		public String PRICEOVRRD;
		public String DROPSHIPDETAILS;
		public String CONSIGNEDINV;
		public OPERAMT OPERAMT;
	}

	public class USERAREA_LINE {
		public Boolean TAXABLE;
		public String TXNREASONCODE;
		public String CONFIGID;
		public String TYPE1099;
		public KFFITEM KFFITEM;
		public String MARKETPRICE;
		public String LISTPRICE;
		public String CONTRACTORLASTNAME;
		public String PRICENOTTOEXCEED;
		public String CONTRACTORFIRSTNAME;
		public String HAZRDUNNUM;
		public KFFITEM DFFITEM;
		public String VENDORQUOTENUM;
		public Integer CONTRACTPOLINENUM;
		public Boolean GLOBALCONTRACT;
		public String CONTRACTPONUM;
		public OPERAMT AMOUNT;
		public String NEGPRICE;
		public String CATEGORYfID;
		public String CONTRACTNUM;
		public KFFITEM DFFLINE;
		public String JOBTITLE;
		public String LINEORDERTYPE;
		public String REQUESTOR;
		public String GLOBALCONTRACTLIN;
		public String HAZRDUNDESC;
	}
	
	public class SOORDERLIN {
		public String HAZRDMATL;
		public String DESCRIPTN;
		public Integer SOLINENUM;
		public SOLINESCHD SOLINESCHD;
		public USERAREA_LINE USERAREA;
		public String ITEMX;
		public String ITEM;
		public OPERAMT OPERAMT;
		public QUANTITY QUANTITY;
	}
}