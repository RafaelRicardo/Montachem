/***************************************************************************************************************
* Vass 
* @author           Alejandro iquira
* Proyecto:         Montachem
* Description:      Clase de prueba el triger Order_tgr y la clase NumberToWord
****************************************************************************************************************/
@isTest
public class Order_tgr_tst 
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
        objOrdenItem.Sales_price__c = 3000.45;
        update objOrdenItem;
        
        ApexPages.currentPage().getParameters().put('id',objOrden.Id);
        OrderPdf_ctr  obj=new OrderPdf_ctr(); 
        
    }
}