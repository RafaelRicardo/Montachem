@isTest
public class AddQuoteProducts_tst
{ 

    @isTest static void myTest() {
       
        //////////////////////////////////////////////////////////////////////////
        /******************** Crear datos   **********************************/
        //////////////////////////////////////////////////////////////////////////
        API_SAP__c             s       = new API_SAP__c(Authorization__c='BASIC',Method__c='',Password__c='123',User__c='admins');
        API_SAP_cartera_TRM__c cTrm    = new API_SAP_cartera_TRM__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Cartera/');
        API_SAP_create_order__c cOrder = new API_SAP_create_order__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Order');
        insert s;
        insert cTrm;
        insert cOrder; 
        
        Account objCuenta=DataGenerator_cls.createAccount(true, 'CCOL001');
        
        Id pricebookId = Test.getStandardPricebookId();
        
        
        system.debug('pricebookId:'+pricebookId);
        Product2 objProd=DataGenerator_cls.createProduct(pricebookId, true); 
        
        //agregar el producto a la lista de precios
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=objProd.Id,UnitPrice=400000, IsActive=true);
        insert pbe;

        Opportunity objOportunidad   = DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        Port__c objPort              = DataGenerator_cls.createPort(true, objCuenta.Country__c);
        Payment_term_pricelist__c pt = DataGenerator_cls.createPTermPercent('18', true) ;
        Freight__c f                 = DataGenerator_cls.createFreight(objPort.id, objPort.id,true);
                
        Order__c objOrden=DataGenerator_cls.createOrder(objCuenta.id,objOportunidad.id,true);
        Order_Product__c objOrdenItem=DataGenerator_cls.createOrderItemCust(objOrden.id,objProd.id,true);
        
        Quote objQuote = DataGenerator_cls.createQuote(objOportunidad.id, pricebookId, 'Quotation sent', objPort.id, '18', '1', 'USD', true);  
        
        objOportunidad.SyncedQuoteId = objQuote.id;
        update objOportunidad;
        
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////
        /******************************* Realizar test de la visualforce   **********************************/
        //////////////////////////////////////////////////////////////////////////////////////////////////////
       
        // Crear Visualforce 
        PageReference pageRef = Page.AddProductsMobile_pag;
        Test.setCurrentPage(pageRef);
        String idLista; 
        system.debug('idLista:'+idLista);
        
        // asignar parámetros
        System.currentPageReference().getParameters().put('id',objQuote.Id );
        
        // Instanciar controlador
        ApexPages.StandardController sc = new ApexPages.StandardController(objQuote);
        AddQuoteProducts_ctr controller = new AddQuoteProducts_ctr(sc);
        system.debug('2 idLista:'+idLista);
        controller.idLista= pricebookId;
        system.debug('3 idLista:'+idLista);
        
                
        // asignar parámetros para búsqueda
        System.currentPageReference().getParameters().put('productName', objProd.Name);
        System.currentPageReference().getParameters().put('family','');
        System.currentPageReference().getParameters().put('Brand', '');
        System.currentPageReference().getParameters().put('Reference', '');
        
        // Ejecutar búsqueda
        PageReference pR =  controller.runSearch();
        
        controller.resultProductList=controller.getSearchedProducts();
        
        //seleccionar un producto
        controller.resultProductList.get(0).selected= true;
        
        //asignar los productos seleccionados
        pR =  controller.assignSelected();
        
        // guardar sin puerto de origen
        pR = controller.guardar();
        
        //guardar con puerto de origen y con cantidad pero sin un Payment term percentage para cubrir la exception de guardar
        controller.selectedProducts2.get(0).originPort= objPort.id;
        controller.selectedProducts2.get(0).quantity  = 3000;
        pR = controller.guardar();
        
        
        //guardar con puerto de origen y con cantidad pero sin un Payment term percentage para cubrir la exception de guardar
        controller.selectedProducts2.get(0).pTermPercentage= 1.1;
        pR = controller.guardar();
        
        //guardar con puerto de origen y con cantidad
        controller.selectedProducts2.get(0).originPort= objPort.id;
        controller.selectedProducts2.get(0).quantity  = 3000;
        pR = controller.guardar();
        
        system.debug('Test segundo guardar');
        
        pR =  controller.refreshListPrices();
        decimal fValue= controller.getFreightValue(objPort.id,null, objPort.id,null,'20');
        Payment_term_pricelist__c[] pTerm=  controller.getPaymentTermPercent('3');
        
        pR =  controller.cancel();
        
        controller.continuar();
        controller.beginning();
        controller.previous();
        controller.next();
        controller.end();
        
        boolean  ok =  controller.getEnableNxt();
        
        ok  =  controller.getEnablePrev();
        
        
        
            
        
    }
}