/*****************************************************************************************
    Name    : OrderXMLGeneratorTest
    Desc    : Test class for OrderXMLGenerator

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Scott Coleman          03 Sep 2015     Created
******************************************************************************************/
@isTest
private class OrderXMLGeneratorTest {

    public static final String amexType = 'American Express';
    public static final String mastercardType = 'MasterCard';
    public static final String visaType = 'Visa';

    @isTest static void mapCardTypeTest() {
        Test.startTest();

        String mappedAmexType = OrderXMLGenerator.mapCardType(amexType);
        String mappedMastercardType = OrderXMLGenerator.mapCardType(mastercardType);
        String mappedVisaType = OrderXMLGenerator.mapCardType(visaType);
        String mappedShortUnknownType = OrderXMLGenerator.mapCardType('Paycard');
        String mappedLongUnknownType = OrderXMLGenerator.mapCardType('Payments Are Us Card');

        Test.stopTest();

        System.assertEquals('AMEX', mappedAmexType);
        System.assertEquals('MC', mappedMastercardType);
        System.assertEquals('VISA', mappedVisaType);
        System.assertEquals('PAYCARD', mappedShortUnknownType);
        System.assertEquals('PAYMENTS A', mappedLongUnknownType);
    }

    @isTest static void buildCardholderNameTest() {
        String cardholderName = 'Bates Battaglia';
        String cardType = visaType;
        String cardNumber = '4111111111111111';

        Test.startTest();

        String fullCardholderName = OrderXMLGenerator.buildCardholderName(true,cardholderName, cardType, cardNumber);
        String fullCardholderNameNullName = OrderXMLGenerator.buildCardholderName(true,null, cardType, cardNumber);
        String fullCardholderNameNullType = OrderXMLGenerator.buildCardholderName(true,cardholderName, null, cardNumber);
        String fullCardholderNameNullNumber = OrderXMLGenerator.buildCardholderName(true,cardholderName, cardType, null);

        Test.stopTest();

        System.assertEquals(cardholderName + ' ' + OrderXMLGenerator.mapCardType(cardType) + ' ' + cardNumber.right(4), fullCardholderName);
        System.assertEquals(null, fullCardholderNameNullName);
        System.assertEquals(cardholderName + ' ' + cardNumber.right(4), fullCardholderNameNullType);
        System.assertEquals(cardholderName + ' ' + OrderXMLGenerator.mapCardType(cardType), fullCardholderNameNullNumber);
    }
}