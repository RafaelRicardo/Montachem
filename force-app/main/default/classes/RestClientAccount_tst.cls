@isTest
public class RestClientAccount_tst  
{
    
    // Test credit approval.
    @isTest static void myTest2() {
       
        // Custom settings para invocación del WS
        API_SAP__c             s  = new API_SAP__c(Authorization__c='BASIC',Method__c='',Password__c='123',User__c='admins');
        API_SAP_account__c cAcc   = new API_SAP_account__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Order');
        insert s;
        insert cAcc;
        
        /*************************************  Creación de datos  ***************************************************/
                       
        // creación de la cuenta
        Account objCuenta=DataGenerator_cls.createAccount(true, null);
        
        //actualiza cuenta para ejecutar invocación del WS
        objCuenta.Send_To_SAP__c    = true; 
        objCuenta.Credit_status__c  = 'Approved';
        objCuenta.Federal_tax_ID__c = '12344555';
        objCuenta.Payment_term__c   =  '3';
        objCuenta.Credit_Limit__c   = 3000;
        update objCuenta;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpPostCreateAccount());
                    
    }
    
    
  
	// Clase que emula la respuesta del WS que crea la Orden en SAP    
	public class MockHttpPostCreateAccount implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Estado": true,"Mensaje": "Exitoso","Datos": {"SAPDoc_Entry": "27076","SAPDoc_Num": "81664"}}');
            return res;
        }
    }  
    
}