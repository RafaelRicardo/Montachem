/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro Iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase que tiene lógica para el llamado a WS que utiliza información de la cotizaicón para crear una orden en SAP
 Clase de prueba:  ApproveRejectQuote_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción
 ---- ----------- ----------------------- ------------------------------------------
 1.0  15-11-2018 Alejandro Iquira       Creación de la clase
 1.1  18-04-2019 Alejandro Iquira       Modificación solicitada por Alejandro Fonseca. En caso que la cuenta no tenga ningún "Commission representative" 
										asociado, las ordenes que se envien a SAP tendrán como owner al propietario de la cuenta en SF. De lo contrario, 
										se enviará como owner el SAP code del Commission representative relacionado a la cuenta.
****************************************************************************************/
public class RestClientCreateOrder {

    
    // AI Invocar WS que crea orden en SAP
    public static String[] sendRequest (id quoteId, decimal trm){
                 
        
        String[] invokeResult=new String[]{null,null,null,null};
        List<Quote> lstQuote =[select id,opportunityId,account.Account_code__c,  TRM__c, currency__c,ExpirationDate,DocDate__c,Customer_Ref__c, 
                               quote.opportunity.Consignee__r.Account_code__c, quote.opportunity.notify__r.Account_code__c, 
                               payment_term__c,incoterm__c, Place_of_delivery__c,Place_of_delivery__r.Code__c,Country_comments__c,Commission__c,
                               Remarks__c,Credit_Limit__c,Customer_Past_Due__c, opportunity.owner.SAPcode__c, quote.account.Commission_representative__r.sap_code__c //,DocDueDate__c
                               from quote where id=:quoteId];
        
        if (lstQuote.size()>0){
            
            Quote quote= lstQuote.get(0);
            // variable que contendrá información para autenticación
            API_SAP__c apiSetupAuth = API_SAP__c.getOrgDefaults();
            
            // contiene información de la URL y método apara el WS específico.
            API_SAP_create_order__c apiSetupCreateOrder = API_SAP_create_order__c.getOrgDefaults();
            
            // variables para realizar el llamado
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            HttpResponse response=new HttpResponse();
            system.debug('RestClientCreateOrder quote:'+quote);
            
           
            OrderWrapper orderWrp = new OrderWrapper();
               
            system.debug('RestClientCreateOrder 2 quote:'+quote);
            orderWrp.idOportunidad     =quote.opportunityId;
            orderWrp.AccountCode       =quote.account.Account_code__c;
            orderWrp.Status            ='open';
            // en caso que se envie una TRM como parámetro, se enviará al web service
            orderWrp.TRM               =(trm!=null)? trm:quote.TRM__c;
            orderWrp.orderCurrency     =quote.currency__c;
            
           //DARF 1/3/2020 orderWrp.ShipmentDate      =quote.DocDate__c.month()+'/'+quote.DocDate__c.day()+'/'+quote.DocDate__c.year(); //quote.DocDueDate__c.month()+'/'+quote.DocDueDate__c.day()+'/'+quote.DocDueDate__c.year();
           //DARF 1/3/2020 orderWrp.DocDate           =quote.DocDate__c.month()+'/'+quote.DocDate__c.day()+'/'+quote.DocDate__c.year();
           
            orderWrp.ShipmentDate      =date.today().month()+'/'+date.today().day()+'/'+date.today().year(); 
            orderWrp.DocDate           =date.today().month()+'/'+date.today().day()+'/'+date.today().year();
            orderWrp.DeliveryDate      =quote.ExpirationDate.month()+'/'+quote.ExpirationDate.day()+'/'+quote.ExpirationDate.year();
            
            orderWrp.Customer_Ref      =quote.Customer_Ref__c;
            orderWrp.Consignee         =quote.opportunity.Consignee__r.Account_code__c;
            orderWrp.Notify            =quote.opportunity.notify__r.Account_code__c;
            orderWrp.Payment_Term      =quote.payment_term__c;
            orderWrp.Incoterm          =quote.incoterm__c;
            orderWrp.Place_of_delivery =quote.Place_of_delivery__r.Code__c;
            orderWrp.Country_comments  =quote.Country_comments__c;
            orderWrp.Commission        =String.valueOf(quote.Commission__c);
            orderWrp.Remarks           =quote.Remarks__c    ;
            orderWrp.Credit_Limit      =(quote.Credit_Limit__c);
            
            orderWrp.Customer_Past_Due =quote.Customer_Past_Due__c;
            
            //AI v 1.1.
            orderWrp.OwnerSapCode      = (quote.account.Commission_representative__r.sap_code__c==null)? quote.opportunity.owner.SAPcode__c : quote.account.Commission_representative__r.Sap_code__c;
                 
            system.debug('RestClientCreateOrder 3 orderWrp:'+orderWrp);
            
            orderWrp.lstProductos =  new list<orderProductWrapper>();
            
                                           
            for (QuoteLineItem qp: [select Product2Id, Product2.ProductCode, Quantity, UnitPrice, List_price__c, Port_of_origin__c,Port_of_origin__r.code__c, Container_type__c, 
                                       Product2.MI__c, Product2.density__c
                                       from QuoteLineItem where QuoteId= :quote.id ]){
                                           
                                           system.debug('RestClientCreateOrder quoteProduct:' +qp);
                                           orderProductWrapper opWrp =  new orderProductWrapper();
                                           system.debug('RestClientCreateOrder opWrp:' +opWrp);
                                           opWrp.ItemCode   = qp.Product2.ProductCode;
                                           opWrp.Quantity   = qp.Quantity;
                                           opWrp.Sales_price= qp.UnitPrice;
                                           //DARF 1/03/2020 opWrp.listPrice  = qp.List_price__c;
                                           opWrp.listPrice  = 0;
                                           //DARF 1/03/2020 opWrp.Origin     = qp.Port_of_origin__r.code__c;
                                           opWrp.Origin     = 'NA';
                                           opWrp.Container  = qp.Container_type__c;
                                           opWrp.MI         = qp.Product2.MI__c;
                                           opWrp.Density    = qp.Product2.density__c;
                                           system.debug('RestClientCreateOrder 2 opWrp:' +opWrp);
                                           orderWrp.lstProductos.add(opWrp);
            }
    
            system.debug('RestClientCreateOrder 4 orderWrp:' +orderWrp);
            
            // set Request
            request.setEndpoint(apiSetupCreateOrder.URL__c); 
            system.debug('URL:'+request.getEndpoint());
            request.setMethod(apiSetupCreateOrder.Method__c);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            
            // set Authorization header
            String username = apiSetupAuth.user__c;
            String password = apiSetupAuth.password__c;
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'BASIC ' +
            EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
            
            
            // set body and invoke WS
            String orderJson = JSON.serialize(orderWrp);
            system.debug('request body:'+orderJson);
            request.setBody(orderJson);
            //request.setBody('{"TRM":3275.01,"Status":"open","ShipmentDate":"12/31/2018","Remarks":"aaaa","Place_of_delivery":"CARTAGENA","Payment_Term":"1","orderCurrency":"USD","Notify":null,"lstProductos":[{"Sales_price":3000,"Quantity":1,"Origin":null,"MI":12,"ItemCode":"LDPE-DR530G-SM","Density":33,"Container":20}],"Incoterm":"1","idOportunidad":"006m0000008zzKCAAB","DocDate":"12/28/2018","DeliveryDate":"12/03/2018","Customer_Ref":null,"Customer_Past_Due":false,"Credit_Limit":false,"Country_comments":null,"Consignee":null,"Commission":null,"AccountCode":"Es0002"}');
            response = http.send(request);
            
            
            // Parse the JSON response
            if (response.getStatusCode() != 201 && response.getStatusCode() != 200) {
                System.debug('Integration Error: ' + response.getStatusCode() + ' ' + response.getStatus());
                System.debug('Integration Error Body: ' + response.getBody());
                invokeResult[0]= response.getBody();
                //quoteToUpdate.Integration_Message__c ='Integration Error:'+response.getStatusCode() + ' -'+response.getStatus();
                
            } else {
                System.debug('Integration Ok:'+response.getBody());
                responseCreateOrder result = (responseCreateOrder) JSON.deserialize(response.getBody(), responseCreateOrder.class);
                invokeResult[0]= 'Ok';
                invokeResult[1]=result.Datos.SAPDoc_Entry;
                invokeResult[2]=result.Datos.SAPDoc_Num;
                System.debug('Integration response:'+response);
            }
             
        }
        return invokeResult;
        
    }
    
    public class OrderWrapper {
        
      Public String idOportunidad {get; set;}
      Public String AccountCode {get; set;}
      Public String Status {get; set;}
      Public decimal TRM {get; set;}
      Public String orderCurrency {get; set;}
      Public String ShipmentDate {get; set;}
      Public String DocDate {get; set;}
      Public String Customer_Ref {get; set;}
      Public String Consignee {get; set;}
      Public String Notify {get; set;}
      Public String Payment_Term {get; set;}
      Public String Incoterm {get; set;}
      Public String Place_of_delivery {get; set;}
      Public String Country_comments {get; set;}
      Public String Commission {get; set;}
      Public String Remarks {get; set;}
      Public boolean Credit_Limit {get; set;}
      Public String DeliveryDate {get; set;}
      Public boolean Customer_Past_Due {get; set;}
      Public String OwnerSapCode {get; set;}
      Public list<orderProductWrapper> lstProductos {get; set;}
        
        
    }
    
    public class orderProductWrapper {
        Public String ItemCode   {get; set;}
        Public decimal Quantity   {get; set;}
        Public decimal Sales_price   {get; set;}
        public decimal listPrice {get; set;} 
        Public String Origin   {get; set;}
        Public String Container   {get; set;}
        Public decimal MI   {get; set;}
        Public decimal Density   {get; set;}
    }
    
    public class responseCreateOrder {
        
        String Estado;
        String Mensaje;
        DatosResponse Datos;
        
    }
    
    public class DatosResponse {
        
        String SAPDoc_Entry;
        String SAPDoc_Num;
    }
    
}