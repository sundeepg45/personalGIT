/*****************************************************************************************
    Name    : OrderJSONGenerator
    Desc    : The class that serializes an order into an OAGI JSON message

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    John Herson            2014-07-16      Created
    Scott Coleman          2014-07-31      Updated with new outbound format
    
******************************************************************************************/

public with sharing class OrderJSONGenerator {

    public static String generateOrderJSON(IntegrationObjects.Order order, Boolean xmlPayload) {
        if(xmlPayload) {
            String jsonXml = OrderXMLGenerator.generateOrderXML(order);

            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeString(jsonXml);
            String jsonString = gen.getAsString();
            System.debug(jsonString);

            return jsonString;
        }
        else {
            return generateOrderJSON(order);
        }

    }

    public static String generateOrderJSON(IntegrationObjects.Order order) {
        throw new OrderJSONGeneratorException('Not supported. Use generateOrderJSON(IntegrationObjects.Order order, Boolean xmlPayload) with xmlPayload = true');
    }

    public class OrderJSONGeneratorException extends Exception{}
}