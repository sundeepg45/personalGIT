public with sharing class FormatController {
	// http://en.wikipedia.org/wiki/ISO_4217#Code_formation
	public static final Map<String,Integer> currencyScaleMap = new Map<String,Integer>{
		'BHD'=>3,
		'BIF'=>0,
		'BYR'=>0,
		'CLF'=>0,
		'CLP'=>0,
		'CVE'=>0,
		'DJF'=>0,
		'GNF'=>0,
		'IDR'=>0,
		'IQD'=>0,
		'IRR'=>0,
		'ISK'=>0,
		'JOD'=>3,
		'JPY'=>0,
		'KMF'=>0,
		'KRW'=>0,
		'KWD'=>3,
		'LAK'=>0,
		'LBP'=>0,
		'LYD'=>3,
		'MGY'=>0,
		'MMK'=>0,
		'MOP'=>1,
		'MRO'=>0,
		'OMR'=>3,
		'PYG'=>0,
		'RWF'=>0,
		'SLL'=>0,
		'STD'=>0,
		'TND'=>3 
	};

	private Decimal currencyValue;
	
	public FormatController() {}
	
	public String currencyIsoCode {
		get;
		set;
	}
		
	public String currencyString {
		set {
			currencyValue = null;
			currencyString = null;
			if(value != null && value.length() > 0) {
				try {
					this.currencyValue = Decimal.valueOf(value);
					this.currencyString = value;
				}
				catch(Exception ex) {}
			}
		}
		get;
	}
		
	public String getCurrencyFormatted() {
		String retval = null;
		if(currencyValue != null) {
			Integer scale = currencyScaleMap.get(currencyIsoCode);
			if(scale == null) {
				scale = 2;
			}
			currencyValue.setScale(scale);
			if(scale > 0) {
				currencyValue.setScale(scale+1);
				Decimal offset = 0.1;
				offset.setScale(scale+1);
				offset = offset.pow(scale+1);
				if(currencyValue >= 0) {
					currencyValue += offset;
				}
				else {
					currencyValue -= offset;
				}
			}
			retval = currencyValue.format();
			if(scale > 0) {
				retval = retval.substring(0,retval.length()-1);
			}
		}
		return retval;
	}

	public Integer scale {
		get {
			if(scale == null) {
				scale = currencyScaleMap.get(currencyIsoCode);
			}
			return (scale == null)?2:scale;
		}
		set;
	}
	
	public Date dateValue {
		get;
		set;
	}
	
	public String getDateFormatted() {
		String retval = null;
		if(dateValue != null) {
			retval = dateValue.format(); 
		}
		return retval;
	}
}