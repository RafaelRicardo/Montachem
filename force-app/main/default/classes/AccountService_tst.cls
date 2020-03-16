/***************************************************************************************************************
* Vass 
* @author           Alejadnro Iquira
* Proyecto:         Montachem
* Description:      Clase de prueba para la clase OrderService
****************************************************************************************************************/
@isTest
public class AccountService_tst 
{
    //crea la data
    @testSetup static void setup()
    {
        Account objCuenta=DataGenerator_cls.createAccount(true);
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity objOportunidad   = DataGenerator_cls.createOportunity(objCuenta.id, pricebookId, true);
        
        Port__c objPort= DataGenerator_cls.createPort(true, objCuenta.Country__c);
       
    
    }

    @isTest static void myTest() {
       
        // code_block
        AccountService.jsonListAccounts  objOrer=new AccountService.jsonListAccounts();
        AccountService.jsonAccount     objProduc=new AccountService.jsonAccount();
        AccountService.Response   objResponse=new AccountService.Response();
        
        
        RestRequest req = new RestRequest();
  
        RestResponse res = new RestResponse();
        
        Account a=[select id,Account_code__c, name , Available__c 
                         from account].get(0);
        system.debug('AccountService_tst class 0 Account :'+a.id );
            
        req.requestURI = '/services/apexrest/UpdateAccount';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof('{"listAccounts": [ {"AccountSFId": "'+a.id +'","available": 300}]}');
        RestContext.request = req;
    	RestContext.response = res;
        String strResponse=AccountService.updateAccountSource();
        
        // test la excepción
        req.requestBody = Blob.valueof('{"listAccounts": [ {"AccountSFId": "001m000000m265iBBB","available": 300}]}');
        RestContext.request = req;
    	RestContext.response = res;
        strResponse=AccountService.updateAccountSource();
        system.debug('======='+strResponse);
    }
}