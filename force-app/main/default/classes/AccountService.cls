/***************************************************************************************************************
* Vass 
* @author           Wiliam Dorado
* Proyecto:         Montachem
* Description:      Servicio rest para actualizar las ordenes
****************************************************************************************************************/
@RestResource(urlMapping='/UpdateAccount/*')
global with sharing class AccountService
{

  /*******************************************************************************************
  ACTUALIZA LAS ORDENES
  ********************************************************************************************/
  @HttpPost
  global static String updateAccountSource()
  {    
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response; 
        String reqBody = req.requestBody.toString();
        list<String> transactionResults= new list<String>();
      	list<Account> lstAccountToUpdate = new  list<Account> ();
        
      
       try
      {          
          // obtener listado del WS y serializarlo con la clase jsonListAccounts
          jsonListAccounts objAccountsIn=(jsonListAccounts)JSON.deserialize(reqBody,jsonListAccounts.class);
          
          
          system.debug('0 service updateAccount 0 objAccountsIn:'+objAccountsIn);
          
          // Obtener listado de Ids de cuentas enviado en el WS
          List<String>  lstAccountIds =new List<String>();
          for (jsonAccount a: objAccountsIn.listAccounts){
              lstAccountIds.add(a.AccountSFId);
          }
          
          system.debug('1 service updateAccount lstAccountIds:'+lstAccountIds);
          // Crear mapa con cuentas según los Ids enviados en el WS
          map<id,Account> mapAccount = new  map<id,Account> ();
          for (Account a:[select id,Account_code__c, name , Available__c 
                          from account where id=:lstAccountIds]){
              mapAccount.put(a.id, a);
          }

          system.debug('2 service updateAccount mapAccount:'+mapAccount);          
          
          //actualiza la orden y sus productos
          if(mapAccount.size()>0)
          {
              
              for (jsonAccount a: objAccountsIn.listAccounts){
                  
                  if(mapAccount.containsKey(a.AccountSFId)){
         			  system.debug('4 service updateAccount Account gotten:'+ a);  
                      Account accTmp = mapAccount.get(a.AccountSFId);
                      accTmp.available__c = a.available;
                      accTmp.Last_integration_date_from_SAP__c = DateTime.now();
                      lstAccountToUpdate.add(accTmp);
                      transactionResults.add('Account:'+ a.AccountSFId + ' updated successfully');
                  }else
                  {
                      transactionResults.add('Account:'+ a.AccountSFId + ' does not exist' );
                  }
              }
                                
          }else
          {
              res.statusCode=500;
              return ArmaResponse('ERROR','None of the accounts ids sent, exist in Salesforce.', null);
          }
          update lstAccountToUpdate;

      }catch(Exception ex)
      {			
          res.statusCode=500;
          system.debug('service updateAccount Error:'+ex);     
          return ArmaResponse('ERROR','An error ocurred:'+ ex.getMessage() + '. Line:'+ex.getLineNumber(), null);
      } 
      
      //arma la respuesta
      return ArmaResponse('OK','Operación Exitosa',transactionResults);

  }
      
    /*/ Devuelve un mapa con las cuentas pertenecientes al listado de Accountcodes enviados como parámetro
    public static map<string, Account> getAccounts(List<String> lstAccountCodes)
    {
    
		map<string, Account> mapAcc = new map<string, Account>();
        for(Account a:[select id, name,Account_code__c  from Account where Account_code__c in :lstAccountCodes ]){
            mapAcc.put(a.Account_code__c, a);
        }
        
        return mapAcc;
    }
  /*******************************************************************************************
  OBJETOS JSON
  ********************************************************************************************/
  public static String ArmaResponse(String Estado,String Mensaje, list<String> results)
  {
      Response objResponse          =new Response();
      objResponse.Mensaje           =Mensaje;
      objResponse.Estado            =Estado;
      objResponse.transationResults = results;
      
      return JSON.serialize(objResponse);
  }
  
    
  global class jsonListAccounts { 

      Global list <jsonAccount> listAccounts;
      
  }      
    
    
  global class jsonAccount { 

      Global String AccountSFId;
      Global Decimal available;
      
  }      
    
  global class Response { 

        global String Estado; 
        global String Mensaje; 
      	global list<String> transationResults;

  }
}