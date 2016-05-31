public with sharing class PartnerConst {

    //
    // WARNING: Do not change any of these values unless you are sure of what you are impacting.
    // Most of them my remain in sync with various picklist values
    //

    //
    // Partner Types
    //
    public static final String  OEM = 'Alliance Partner/OEM';
    public static final String  RESELLER = 'Solution Provider';
    public static final String  ISV = 'Independent Software Vendor';
    public static final String  DISTRIBUTOR = 'Distributor';
    public static final String  CCNSP = 'Certified Cloud & Service Provider';
    public static final String  SCP = 'Service/Cloud Provider';
    public static final String  EMBED = 'Embedded';
    public static final String  EMBEDDED = 'Embedded';
    public static final String  SI = 'Systems Integrator';
    public static final String  CCP = 'Certified Cloud Provider';
    public static final String  HOSTING = 'Hosting';

    //
    // Partner Tiers
    //
    public static final String  AFFILIATED = 'Affiliated';
    public static final String  READY = 'Ready';
    public static final String  ADVANCED = 'Advanced';
    public static final String  PREMIER = 'Premier';
    public static final String  UNAFFILIATED = 'Unaffiliated';
    public static final String  UNAFFILIATED_RENEWAL = 'Unaffiliated Renewal Not Met';

    //
    // Partner Record Type IDs
    //
    public static final ID NA_PARTNER = '012600000004yfaAAA';
    public static final ID EMEA_PARTNER  = '012600000004yfVAAQ';
    public static final ID LATAM_PARTNER = '0126000000053LWAAY';
    public static final ID APAC_PARTNER  = '012600000004yfQAAQ';

    //
    // Partner Record Type Developer Names
    //
    public static final String NA_PARTNER_DN = 'NAPartner';
    public static final String EMEA_PARTNER_DN = 'EMEAPartner';
    public static final String LATAM_PARTNER_DN = 'LATAMPartner';
    public static final String APAC_PARTNER_DN = 'APACPartner';
    public static final String FEDSLED_PARTNER_DN = 'DLT';
    public static final String CONTRACT_RECORD_TYPE = 'Partner_Agreement';

}