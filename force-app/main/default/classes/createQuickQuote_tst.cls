/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            Alejandro Iquira
/* Proyecto:         MONTACHEM
/* Descripción:      Clase de pruebas para la visualforce createQuickQuote_pag, el controlador createQuickQuote_ctr y la clase SaveSendQuotePDF

/* Cambios (Versiones) 
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  09-Jul-2019 Alejandro Iquira          Controlador de pagina
/*                                          

/*************************************************************************************/ 

@isTest
public class createQuickQuote_tst
{ 

    @isTest static void myTest() {
       
        //////////////////////////////////////////////////////////////////////////
        /******************** Crear datos   **********************************/
        //////////////////////////////////////////////////////////////////////////
        USD_Template_Setting__c usdTempl = new USD_Template_Setting__c(Template_Id__c = '0Q0m0000000An2ACAS');
        insert usdTempl;
        
        Foreign_currency_template__c foreignTempl = new Foreign_currency_template__c(Template_Id__c = '0Q0m0000000An2ACAS');
        insert foreignTempl;
        
        Account objCuenta = DataGenerator_cls.createAccount(true, 'CCOL001');
        
        Contact objContact = DataGenerator_cls.createContact('Pedro', 'Perez', 'alejandro.iquira@gmail.com', true);
        
        Id pricebookId = Test.getStandardPricebookId();
        
        system.debug('createQuickQuote_tst pricebookId:'+pricebookId);
        Product2 objProd=DataGenerator_cls.createProduct(pricebookId, true); 
        
        //agregar el producto a la lista de precios
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=objProd.Id,UnitPrice=400000, IsActive=true);
        insert pbe;

        Opportunity objOportunidad   = DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        Port__c objPort              = DataGenerator_cls.createPort(true, objCuenta.Country__c, 'MIAMI');
        Payment_term_pricelist__c pt = DataGenerator_cls.createPTermPercent('18', true) ;
        Freight__c f                 = DataGenerator_cls.createFreight(objPort.id, objPort.id,true);
        Order__c objOrden=DataGenerator_cls.createOrder(objCuenta.id,objOportunidad.id,true);
        Order_Product__c objOrdenItem = DataGenerator_cls.createOrderItemCust(objOrden.id,objProd.id,true);
        
        Quote objQuote = DataGenerator_cls.createQuote(objOportunidad.id, pricebookId, 'Quotation sent', objPort.id, '18', '1', 'USD', true);  
        
        QuoteLineItem objQuoteItem = DataGenerator_cls.createQuoteProducts(objQuote.Id, objProd.Id, pbe.Id, 0.5 ,objPort.id, true);
        
        objOportunidad.SyncedQuoteId = objQuote.id;
        update objOportunidad;
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////
        /******************************* Realizar test de la visualforce   **********************************/
        //////////////////////////////////////////////////////////////////////////////////////////////////////
       
        // Crear Visualforce 
        PageReference pageRef = Page.createQuickQuote_pag;
        Test.setCurrentPage(pageRef);
        String idLista; 
        system.debug('createQuickQuote_tst createQuickQuote_tst idLista:'+idLista);
        
        // asignar parámetros
        System.currentPageReference().getParameters().put('id',objCuenta.Id );
        System.currentPageReference().getParameters().put('QuoteId',objQuote.Id );
        
        // Instanciar controlador
        ApexPages.StandardController sc = new ApexPages.StandardController(objCuenta);
        createQuickQuote_ctr  controller = new createQuickQuote_ctr (sc);
        system.debug('createQuickQuote_tst 2 idLista:'+idLista);
        controller.idLista= pricebookId;
        
        // probar método que busca los productos en la visualforce
        Map<id,createQuickQuote_ctr.ProductWrapper>  mapSearchedProducts = controller.getMapSearchedProducts();
        
        // Obtener el primer producto resultado de la búsqueda
        id selectedProductId = (new list<id>(mapSearchedProducts.keyset()))[0];
        // asignar parametro con id del producto de la lista de resultado de la búsqueda
        System.currentPageReference().getParameters().put('productId', selectedProductId);
        
        // Método que asigna valores del producto seleccionado a campos de la visualforce
        controller.assignProductDetailFields();
        
        // Método que agrega elel producto al carrito
        controller.addToCart();
        
        system.debug('createQuickQuote_tst selectedProductsCart map:'+controller.selectedProductsCart);
        // Obtener el primer producto agregado al carro de compras
        integer addedProductId = (new list<integer> (controller.selectedProductsCart.keySet()) )[0];
        
        system.debug('createQuickQuote_tst addedProductId:'+mapSearchedProducts);
        // Asignar parametro con id del producto agregado al carro de compras
        System.currentPageReference().getParameters().put('productId', String.valueOf(addedProductId));
        
        // Método que asigna valores del producto seleccionado para editar
        controller.assignEditProductDetailFields();
        
        // Método que agrega edición del producto de nuevo al carro
        controller.addEdition();
        
        // probar excepción del metodo que calcula precios
        controller.refreshPrice();
                
		// asignar parametros y volver a ejecutar refresh price para cubrir el otro camino
        System.currentPageReference().getParameters().put('paymentTerm', objQuote.Payment_Term__c); 
        System.currentPageReference().getParameters().put('incoterms', objQuote.Incoterm__c); 
        System.currentPageReference().getParameters().put('deliveryDate', String.valueOf(objQuote.expirationDate)); 
        System.currentPageReference().getParameters().put('deliveryPlace', objQuote.Place_of_delivery__c); 
        System.currentPageReference().getParameters().put('postingDate', String.valueOf(objQuote.DocDate__c)); 
        System.currentPageReference().getParameters().put('contact', objContact.id);    
        
        controller.refreshPrice();
        
        controller.recalculateSalesPrices();
        
        createQuickQuote_ctr.queryPorts('MIAMI'); 
        
        controller.getMapAddedProd();
                
        controller.guardar();
        
        controller.guardarNoCerrar();
        
        //controller.guardarEnviar();
        
        //controller.enviarPDF();
          
        system.currentPageReference().getParameters().put('productName','Formolene');
        controller.runSearch ();
        // borrar producto agregado al carro.
        System.currentPageReference().getParameters().put('prodIdTodelete', String.valueOf(addedProductId));
        controller.removeFromCart();
        
        controller.assignQuoteValues(); 
        
		// probar clase SaveSendQuotePDF
		//SaveSendQuotePDF.passTest();
        QuoteDocument qd = SaveSendQuotePDF.createQuoteTemplate(objQuote.id, '0EHm0000000DuQv');
        
        SaveSendQuotePDF.sendTemplate (qd,'alejandroiquira3@gmail.com','', 'message');
        
		        
    }
}