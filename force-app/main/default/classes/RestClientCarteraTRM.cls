/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro Iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase que tiene lógica para el llamado a WS que trae información de cartera vencida, límite de crédito y TRM del día
 Clase de prueba:  ApproveRejectQuote_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  15-11-2018 Alejandro Iquira       Creación de la clase
****************************************************************************************/
public class RestClientCarteraTRM {
    
    // AI Invocar WS para consultar TRM, límite de crédito y Cartera
    public static String[] sendRequest (Id quoteId){
		
        try {
            Quote quoteToUpdate = [select id, account.Account_code__c, GrandTotal,Currency__c,Payment_Term__c
                              from quote where id=:quoteId].get(0);
        String[] calloutResults= new String[]{null, null, null, null};
        
        // variable que contendrá información para autenticación
        API_SAP__c apiSetupAuth = API_SAP__c.getOrgDefaults();
        
        // contiene información de la URL y método para el WS específico.
        API_SAP_cartera_TRM__c apiSetupCartera = API_SAP_cartera_TRM__c.getOrgDefaults();
        
        // variables para realizar el llamado
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response=new HttpResponse();
        system.debug('acc new:');
		
        // set Request
        String urlComplement = quoteToUpdate.account.Account_code__c+'/'+quoteToUpdate.GrandTotal+'/'+quoteToUpdate.Currency__c+'/'+quoteToUpdate.Payment_Term__c;
        request.setEndpoint(apiSetupCartera.URL__c+urlComplement); 
        system.debug('URL:'+request.getEndpoint());
        request.setMethod(apiSetupCartera.Method__c);
		request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // set Authorization header
        String username = apiSetupAuth.user__c;
        String password = apiSetupAuth.password__c;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' +
        EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
                
        // set body and invoke WS
        system.debug('before invoke:'+request);
        response = http.send(request);
        
        // Parse the JSON response
        if (response.getStatusCode() != 201 && response.getStatusCode() != 200) {
            System.debug('Integration Error code: ' + response.getStatusCode() + ' ' + response.getStatus());
            System.debug('Integration Error Body: ' + response.getBody());
            //quoteToUpdate.Integration_Message__c ='Integration Error:'+response.getStatusCode() + ' -'+response.getStatus();
            
            calloutResults[0] = response.getBody();
        } else {
            System.debug('Integration Ok:'+response.getBody());
            System.debug('Integration response:'+response);
            //(Account)JSON.deserialize(jsonAccountNew, Sobject.class); 
            TrmCarteraResponse result = (TrmCarteraResponse)JSON.deserialize(response.getBody(), TrmCarteraResponse.Class);
            system.debug('result:'+result);
            calloutResults[0] = 'Ok';
            calloutResults[1] = String.valueOf(result.carteraVencida);
            calloutResults[2] = String.valueOf(result.CreditLimit);
            calloutResults[3] = String.valueOf(result.TRM);
        }
         
        return calloutResults;
        }catch (exception e){
            system.debug('Exception:'+e);
            return new String[]{null, null, null, null};
        }
        
    }

   
    Class TrmCarteraResponse {
        
        String CreditLimit ;
        String carteraVencida;
        decimal TRM;
    }
	
}