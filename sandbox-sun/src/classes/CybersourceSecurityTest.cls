/**
 * Test class for CybersourceSecurity class
 *
 * @version 2015-07-31
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-07-31 - Created
 */
@isTest
private class CybersourceSecurityTest {

    @isTest static void signTest() {
        List<Cybersource_Config__c> cybersourceConfig = new List<Cybersource_Config__c>{
            new Cybersource_Config__c(Name='SecretKey', Value__c='12345'),
            new Cybersource_Config__c(Name='TokenCreationURL', Value__c='https://www.example.com'),
            new Cybersource_Config__c(Name='AccessKey', Value__c='67890'),
            new Cybersource_Config__c(Name='ProfileId', Value__c='ABCDE')
        };
        insert cybersourceConfig;

        Map<String,String> params = new Map<String,String>{
            'param1'=>'value1',
            'param2'=>'value2',
            'param3'=>'param3'
        };

        List<String> paramNames = new List<String>{'param1','param2','param3'};

        Test.startTest();

        String signature = CybersourceSecurity.sign(params, paramNames);

        Test.stopTest();

        System.assertEquals('7maFJRGvyc+RUH5Pbv9B62OpzSocxm4P1BcT7AehDlc=', signature);
    }

    @isTest static void buildDataToSignTest() {
        Map<String,String> params = new Map<String,String>{
            'param2'=>'value2',
            'param3'=>'value3',
            'param1'=>'value1'
        };

        //order is important
        List<String> paramNames = new List<String>{'param1','param2','param3'};

        Test.startTest();

        String data = CybersourceSecurity.buildDataToSign(params, paramNames);

        Test.stopTest();

        System.assertEquals('param1=value1,param2=value2,param3=value3', data);
    }

    @isTest static void commaSeparateTest() {
        List<String> dataList = new List<String>{'one','two','three'};

        Test.startTest();

        String data = CybersourceSecurity.commaSeparate(dataList);

        Test.stopTest();

        System.assertEquals('one,two,three',data);
    }

    @isTest static void newGuidTest() {
        Test.startTest();

        String guid = CybersourceSecurity.newGuid();

        Test.stopTest();

        System.assert(!String.isEmpty(guid));
        System.assertEquals(36, guid.length());
    }

    @isTest static void getCharAtIndexTest() {
        Test.startTest();

        String chr = CybersourceSecurity.getCharAtIndex('Raleigh', 4);

        Test.stopTest();

        System.assertEquals('i', chr);
    }

}