/***************************************************************************************************************
* Vass 
* @author           Wiliam Dorado
* Proyecto:         Montachem
* Description:      Clase de prueba para el triger de cuenta
****************************************************************************************************************/
@isTest
private class Account_tgr_tst
{ 
    //crea la data
    @testSetup static void setup()
    {
        API_SAP__c         s    = new API_SAP__c(Authorization__c='BASIC',Method__c='',Password__c='123',User__c='admins');
        API_SAP_account__c c    = new API_SAP_account__c(Content_type__c = 'Value',Method__c='GET',URL__c='http://rdp.montachem.xyz/consensusapi/public/Cartera/');
        insert s;
        insert c;
        
        Account objCuenta = DataGenerator_cls.createAccount(false, 'CES002');
        insert objCuenta;
        objCuenta.Send_To_SAP__c=true;
        update objCuenta;
        UT_Account.getNextCodeAccount('COL');
        UT_Account.getCodeAccount('COL');
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpPostCreateAccount());
       
    }

    @isTest static void myTest() {
       
        
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