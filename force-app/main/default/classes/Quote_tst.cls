/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            Alejandro Iquira
/* Proyecto:         MONTACHEM
/* Descripción:      Clase de pruebas para el trigger quote_tgr y clase Quote_hdl

/* Cambios (Versiones) 
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  09-Jul-2019 Alejandro Iquira          Controlador de pagina
/*                                          

/*************************************************************************************/ 

@isTest
public class Quote_tst 
{ 

    @isTest static void myTest() {
       
        //////////////////////////////////////////////////////////////////////////
        /******************** Crear datos   **********************************/
        //////////////////////////////////////////////////////////////////////////
        Account objCuenta = DataGenerator_cls.createAccount(true, 'CCOL001');
        
        Contact objContact = DataGenerator_cls.createContact('Pedro', 'Perez', 'alejandro.iquira@gmail.com', true);
        
        Id pricebookId = Test.getStandardPricebookId();
        
        system.debug('quote_tst pricebookId:'+pricebookId);
        Product2 objProd=DataGenerator_cls.createProduct(pricebookId, true); 
        
        //agregar el producto a la lista de precios
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=objProd.Id,UnitPrice=400000, IsActive=true);
        
        insert pbe;

        Opportunity objOportunidad   = DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        Port__c objPort              = DataGenerator_cls.createPort(true, objCuenta.Country__c, 'MIAMI');
        Port__c objPort2             = DataGenerator_cls.createPort(true, objCuenta.Country__c, 'HOUSTON');
        Payment_term_pricelist__c pt = DataGenerator_cls.createPTermPercent('18', true) ;
        Payment_term_pricelist__c pt2 = DataGenerator_cls.createPTermPercent('20', true) ;
        Freight__c f                 = DataGenerator_cls.createFreight(objPort.id, objPort.id,true);
        Order__c objOrden=DataGenerator_cls.createOrder(objCuenta.id,objOportunidad.id,true);
        Order_Product__c objOrdenItem = DataGenerator_cls.createOrderItemCust(objOrden.id,objProd.id,true);
        
        Quote objQuote = DataGenerator_cls.createQuote(objOportunidad.id, pricebookId, 'Quotation sent', objPort.id, '18', '1', 'USD', true);  
        
        QuoteLineItem objQuoteItem = DataGenerator_cls.createQuoteProducts(objQuote.Id, objProd.Id, pbe.Id, 0.5 ,objPort.id, true);
                
        objQuote.Place_of_delivery__c = objPort2.id;
        update objQuote;
               
    }
}