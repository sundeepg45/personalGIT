/**
 * Class that implements Cybersource signing method for credit card payment integration
 *
 * @version 2015-07-31
 * @author Scott Coleman <scoleman@redhat.com> 
 * 2015-07-27 - Created
 * 2015-07-31 - Moved key to config and updated for testability
 */
public class CybersourceSecurity {

    private static final String HMAC_SHA256 = 'HmacSHA256';
    private static final String kHexChars = '0123456789abcdef';

    public static String sign(Map<String, String> params, List<String> paramNames) {
        Cybersource_Config__c secretKeyConfig = Cybersource_Config__c.getInstance('SecretKey');
        String secretKey = secretKeyConfig.Value__c + secretKeyConfig.Value2__c;
        return sign(buildDataToSign(params, paramNames), secretKey);
    }

    public static String sign(String data, String secretKey) {
        Blob mac = Crypto.generateMac(HMAC_SHA256, Blob.valueOf(data), Blob.valueOf(secretKey));
        return EncodingUtil.base64encode(mac).replace('\n', '');
    }

    @TestVisible
    private static String buildDataToSign(Map<String, String> params, List<String> paramNames) {
        List<String> dataToSign = new List<String>();
        for (String paramName : paramNames) {
            dataToSign.add(paramName + '=' + String.valueOf(params.get(paramName)));
        }
        String commaSeparatedData = commaSeparate(dataToSign);
        return commaSeparatedData;
    }

    @TestVisible
    private static String commaSeparate(List<String> dataToSign) {
        String csv = '';
        for (String data : dataToSign) {
            if (!String.isEmpty(csv)) {
                csv = csv + ',';
            }
            csv = csv + data;
        }
        return csv;
    }

    public static String newGuid() {
        String returnValue = '';
        Integer nextByte = 0;

        for (Integer i=0; i<16; i++) {
            if (i==4 || i==6 || i==8 || i==10)
                returnValue += '-';
            nextByte = (Math.round(Math.random() * 255)-128) & 255;
            if (i==6) {
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }
            if (i==8) {
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }
            returnValue += getCharAtIndex(kHexChars, nextByte >> 4);
            returnValue += getCharAtIndex(kHexChars, nextByte & 15);
        }

        return returnValue;
    }

    @TestVisible
    private static String getCharAtIndex(String str, Integer index) {
        if (str == null) return null;
        if (str.length() <= 0) return str;
        if (index == str.length()) return null;
        return str.substring(index, index+1);
    }
}