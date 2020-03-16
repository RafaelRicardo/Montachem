/***************************************************************************************************************
* Vass 
* @author           Wiliam Dorado
* Proyecto:         Montachem
* Description:      Clase de prueba para la clase OrderService
****************************************************************************************************************/
@isTest
private class OrderPdf_ctr_tst
{
    

    @isTest static void myTest() {
        Account objCuenta=DataGenerator_cls.createAccount(true, null);
        
        Id pricebookId = Test.getStandardPricebookId();
        Product2 objProd=DataGenerator_cls.createProduct(pricebookId, true); 
        
        //agregar el producto a la lista de precios
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=objProd.Id,UnitPrice=400000, IsActive=true);
        
        insert pbe;

        Opportunity op=DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        Order__c objOrden=DataGenerator_cls.createOrderCust(objCuenta.id,op.id,true);
        
        Order_Product__c  objOrdenItem=DataGenerator_cls.createOrderItemCust(objOrden.id,objProd.id,true);
        
        ApexPages.currentPage().getParameters().put('id',objOrden.Id);
        OrderPdf_ctr  obj=new OrderPdf_ctr(); 
        
    }
}