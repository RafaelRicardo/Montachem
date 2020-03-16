/***************************************************************************************************************
* Vass 
* @author           Alejandro iquira
* Proyecto:         Montachem
* Description:      Clase de prueba para la clase OrderService
****************************************************************************************************************/
@isTest
private class OrderService_tst 
{
    //crea datos
    @testSetup static void setup()
    {
        Account objCuenta=DataGenerator_cls.createAccount(true,'CCO123');
        Id pricebookId = Test.getStandardPricebookId();
        Product2 objProd=DataGenerator_cls.createProduct(pricebookId, true); 
        
        //agregar el producto a la lista de precios
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=objProd.Id,UnitPrice=400000, IsActive=true);
        insert pbe;

        Opportunity objOportunidad=DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        Port__c objPort= DataGenerator_cls.createPort(true, objCuenta.Country__c);
        Order__c objOrden=DataGenerator_cls.createOrder(objCuenta.id,objOportunidad.id,true);
        Order_Product__c objOrdenItem=DataGenerator_cls.createOrderItemCust(objOrden.id,objProd.id,true);
       
    
    }

    @isTest static void myTest() {
       
        // code_block
        OrderService.jsonOrder  objOrer=new OrderService.jsonOrder();
        OrderService.jsonOrderProduct  objProduc=new OrderService.jsonOrderProduct();
        OrderService.Response   objResponse=new OrderService.Response();
        
        list<Account> lstOrd= OrderService.getAccount('CCO123');
        
        RestRequest req = new RestRequest();
  
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ActualizarOrder';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof('{"SAPDoc_Entry":12345,"SAPDoc_Num":81600,"modifyOrderHeader":false,"Status":"open","DocDate":"12/21/2018","Delivery_Date":"12/28/2018","Shipment_Date":"12/21/2018","Customer_Ref":"","Consignee":"","Notify":"","Payment_Term":"1","Incoterm":1,"Place_of_delivery__c":"","Commission":null,"Remarks":"modificada en SAP. 28-12-2018","CRD":"12/21/2018","ETD":"12/21/2018","ETA":"12/21/2018","Booking_BL":"6","S_Line":"6","Vessel":"6","Voyage":"6","orderCurrency":"USD","lstProductos":[{"ItemCode":"LDPE-DR530G-SM","Quantity":10,"Sales_price":100,"Origin":"MIAMI","Container":"20","MI":12.1,"Density":0.5}]}');
        RestContext.request = req;
    	RestContext.response = res;
        String strResponse=OrderService.send();
        system.debug('======='+strResponse);
    }
}