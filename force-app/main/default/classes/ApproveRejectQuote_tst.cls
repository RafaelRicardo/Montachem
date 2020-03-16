@isTest
public class ApproveRejectQuote_tst 
{

    @isTest static void myTest() {
       
        // Custom settings para invocación del WS
        API_SAP__c             s       = new API_SAP__c(Authorization__c='BASIC',Method__c='',Password__c='123',User__c='admins');
        API_SAP_cartera_TRM__c cTrm    = new API_SAP_cartera_TRM__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Cartera/');
        API_SAP_create_order__c cOrder = new API_SAP_create_order__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Order');
        insert s;
        insert cTrm;
        insert cOrder;
        
        /*************************************  Creación de datos  ***************************************************/
        Account objCuenta=DataGenerator_cls.createAccount(true, 'CCO1234');
        
        Id pricebookId = Test.getStandardPricebookId();
        Product2 objProd=DataGenerator_cls.createProduct(pricebookId, true); 
        
        //agregar el producto a la lista de precios
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=objProd.Id,UnitPrice=400000, IsActive=true);
        insert pbe;

        // Creación de puertos, fletes y porcentajes de payment terms
        Port__c objPort              = DataGenerator_cls.createPort(true, objCuenta.Country__c, 'MIAMI');
        Payment_term_pricelist__c pt = DataGenerator_cls.createPTermPercent('18', true) ;
        Freight__c f                 = DataGenerator_cls.createFreight(objPort.id, objPort.id,true);
        
        // oportunidad y cotización 
        Opportunity objOportunidad   = DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        Quote objQuote = DataGenerator_cls.createQuote(objOportunidad.id, pricebookId, 'Quotation sent', objPort.id, '18', '1', 'USD', true);  
		
        //sincronizar cotización a la oportunidad
        objOportunidad.SyncedQuoteId = objQuote.id;
        update objOportunidad;
        
        //crear orden
        Order__c objOrden=DataGenerator_cls.createOrder(objCuenta.id,objOportunidad.id,true);
        Order_Product__c objOrdenItem=DataGenerator_cls.createOrderItemCust(objOrden.id,objProd.id,true);
        
        
        /*************************************  Ejecución de tests  ***************************************************/
        
        // Rechazar cuando no está en Pending T.O ni en Pending Credit
        PageReference pageRef = Page.ApproveRejectQuote_pag;
        Test.setCurrentPage(pageRef);
      	ApexPages.StandardController sc = new ApexPages.StandardController(objQuote);
        ApproveRejectQuote_ctr controller = new ApproveRejectQuote_ctr(sc);
        
        PageReference nextPage = controller.rejectRecord();
        
        // Rechazar cuando está en T.O
        objQuote.Status='Pending TO';
        update objQuote;
        
        PageReference pageRef2 = Page.ApproveRejectQuote_pag;
        Test.setCurrentPage(pageRef2);
      	ApexPages.StandardController sc2 = new ApexPages.StandardController(objQuote);
        ApproveRejectQuote_ctr controller2 = new ApproveRejectQuote_ctr(sc);
        nextPage = controller2.rejectRecord();

        
        // Aprobar  cuando está en T.O
        objQuote.Status='Pending TO';
        update objQuote;
        
        PageReference pageRef3 = Page.ApproveRejectQuote_pag;
        Test.setCurrentPage(pageRef3);
      	ApexPages.StandardController sc3 = new ApexPages.StandardController(objQuote);
        ApproveRejectQuote_ctr controller3 = new ApproveRejectQuote_ctr(sc3);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpGetTRMCartera());
        nextPage = controller3.approveRecord();
        Test.stopTest();
        
        
    }
    
    // Método para cubrir código de la aprobación por parte del credit Analyst.
    @isTest static void myTest2() {
       
        // Custom settings para invocación del WS
        API_SAP__c             s       = new API_SAP__c(Authorization__c='BASIC',Method__c='',Password__c='123',User__c='admins');
        API_SAP_cartera_TRM__c cTrm    = new API_SAP_cartera_TRM__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Cartera/');
        API_SAP_create_order__c cOrder = new API_SAP_create_order__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Order');
        insert s;
        insert cTrm;
        insert cOrder;
        
        /*******************************************  Creación de datos  ***************************************************/
                
        //Creación del producto y lista de precios
        Id pricebookId = Test.getStandardPricebookId();
        Product2 objProd=DataGenerator_cls.createProduct(pricebookId, true); 
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=objProd.Id,UnitPrice=400000, IsActive=true);
        insert pbe;
        
        //Creación del producto y lista de precios
        Account objCuenta=DataGenerator_cls.createAccount(true, 'CCO1234');
        
        // Creación de puertos, fletes y porcentajes de payment terms
        Port__c objPort              = DataGenerator_cls.createPort(true, objCuenta.Country__c, 'MIAMI');
        Payment_term_pricelist__c pt = DataGenerator_cls.createPTermPercent('18', true) ;
        Freight__c f                 = DataGenerator_cls.createFreight(objPort.id, objPort.id,true);
        
        // oportunidad cotización y productos de la cotización
        Opportunity objOportunidad   = DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        Quote objQuote = DataGenerator_cls.createQuote(objOportunidad.id, pricebookId, 'Quotation sent', objPort.id, '18', '1', 'USD', true);  
        QuoteLineItem qproduct= DataGenerator_cls.createQuoteProducts(objQuote.id, objProd.Id, pbe.Id, 1, objPort.id, true);
        
        //Sincronizar oportunidad
        objOportunidad.SyncedQuoteId = objQuote.id;
        update objOportunidad;
        
        /*************************************  Ejecución de tests  ***************************************************/
        
        // Aprobar cuando esta en pending credit
        objQuote.Status='Pending Credit';
        objQuote.TRM__c= 1.1;
        update objQuote;
        
        system.debug('Test ApproveReject objQuote status:'+objQuote.Status + ' objQuote.id:'+objQuote.id);
        
        PageReference pageRef3 = Page.ApproveRejectQuote_pag;
        Test.setCurrentPage(pageRef3);
      	ApexPages.StandardController sc3 = new ApexPages.StandardController(objQuote);
        ApproveRejectQuote_ctr controller3 = new ApproveRejectQuote_ctr(sc3);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpPostCreateOrder());
        
        // Test la Excepción  del registro
        pageReference p = controller3.approveRecord();
        
        
        // Dejar la variable de validación vacía, asignar quote y approver para probar el caso exitoso
        controller3.validationError = '';
        controller3.currentQuote    = objQuote;
        controller3.approver = 'Credit analyst';
        p = controller3.approveRecord();
           
        // Probar excepción cuando la oportunidad ya tiene una orden.
        controller3.validationError = '';
        controller3.currentQuote    = objQuote;
        controller3.approver = 'Credit analyst';       
        Order__c objOrden=DataGenerator_cls.createOrder(objCuenta.id,objOportunidad.id,true);
        
        p = controller3.approveRecord();
        
        
        // Probar cuando crédito devuelve la cotización al vendedor.
        controller3.validationError = '';
        controller3.currentQuote    = objQuote;
        controller3.approver = 'Credit analyst';               
        p = controller3.backToDraft() ;
        
        
    }
    
    
    
	public class MockHttpGetTRMCartera implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"CreditLimit": "true","CarteraVencida": "false","TRM": 0}');
            return res;
        }
    }   
	
	// Clase que emula la respuesta del WS que crea la Orden en SAP    
	public class MockHttpPostCreateOrder implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Estado": true,"Mensaje": "Exitoso","Datos": {"SAPDoc_Entry": "27076","SAPDoc_Num": "81664"}}');
            return res;
        }
    }
}