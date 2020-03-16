/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase que invoca el WS para actualizar o crear cuentas en SAP
 Clase de prueba:  Account_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  07-12-2018 Alejandro iquira         Creación
****************************************************************************************/
public class RestClientAccount {
        
    // AI Este método recibe en 2 JSON que corresponden a la misma cuenta, pero una "jsonAccountOld"es la versión 
    //    antes de ser modificada y la otra, "jsonAccountNew" tiene la cuenta con las modificaciones que guardó el usuario.
    @future(callout=true)
    public static void sendRequest (String jsonAccountNew, String jsonAccountOld, id accountId){
        
        // Obtener JSON de la cuenta con los campos antes de ser modificados y después de ser modificados.
        Account acc    = (Account)JSON.deserialize(jsonAccountNew, Sobject.class);
        Account accOld = (Account)JSON.deserialize(jsonAccountOld, Sobject.class);
        
        // contendrá la cuenta que será actualizada si hubo alguna modificación
        Account acToUpdate = new Account();
        
        // Contiene información para autenticación
        API_SAP__c apiSetupAuth = API_SAP__c.getOrgDefaults();
           
        // contiene información de la URL y método para el WS específico.
        API_SAP_account__c apiSetupAccount = API_SAP_account__c.getOrgDefaults();
        
        // variables para realizar el llamado
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response=new HttpResponse();
        system.debug('RestClientAccount acc new:'+acc);
        system.debug('RestClientAccount accOld:'+accOld);
        
        // Indica si cambió algún campo que debe enviarse por WS a SAP
        boolean blIsChanged = accIsChanged(acc,accOld);
        
        system.debug('RestClientAccount acc:'+acc.Send_To_SAP__c +' accOld.Send_To_SAP__c' +accOld.Send_To_SAP__c);
        // Si cambió alguno de los campos de la integración y/o si el check de enviar a SAP esta activo
        if((blIsChanged && acc.Send_To_SAP__c)||(acc.Send_To_SAP__c==true && accOld.Send_To_SAP__c==false) ) {
            
            acc= getAccountCode(acc, accOld);
            
            UT_Account.AccountWrapper accWrp = setAccWpr(acc);
                       
            // set Request
            request.setEndpoint(apiSetupAccount.URL__c);
            request.setMethod(apiSetupAccount.Method__c);
            request.setHeader('Content-Type', apiSetupAccount.Content_type__c);
            
            
            // set Authorization header
            String username = apiSetupAuth.user__c;
            String password = apiSetupAuth.password__c;
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'BASIC ' +
            EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
            
            // set body and invoke WS
            String accountJson = JSON.serialize(accWrp);
            system.debug('request body:'+accountJson);
            request.setBody(accountJson);
            system.debug('request:'+request);
            response = http.send(request);
                        
            // Parse the JSON response
            if (response.getStatusCode() != 201 && response.getStatusCode() != 200) {
                System.debug('Integration Error: ' + response.getStatusCode() + ' ' + response.getStatus());
                System.debug('Integration Error Body: ' + response.getbody());
                accOld.Integration_Message__c ='Integration Error::'+response.getStatusCode() + ' --'+response.getBody();
                accOld.Send_alert_integration_error__c = true;
                acc.Integration_Error__c=true;
                acToUpdate=  accOld;
            } else {
                System.debug('Integration Ok:'+response.getBody());
                acc.Integration_Message__c ='Successful integration to SAP';
                acc.Last_integration_date__c= DateTime.now();
                acc.Integration_Error__c=false;
                acc.Send_alert_integration_error__c = false;
                acToUpdate= acc;
            }
        }
        
        // Si cambió el credit status de la cuenta y no hubo error de integración, debe enviarse alerta y la cuenta se envió a SAP 
        if (acc.Credit_status__c!=accOld.Credit_status__c  && acToUpdate.Send_alert_integration_error__c!=true && acc.Send_To_SAP__c ){
            system.debug('RestClientAccount Cambio CRedit Status acToUpdate:'+acToUpdate);
            if(acToUpdate.Id == null) {acToUpdate= acc;}
            acToUpdate.Send_change_credit_status_alert__c = true;
        }
        system.debug('RestClientAccount Credit_status__c:'+acc.Credit_status__c + ' old Credit_status__c:'+accOld.Credit_status__c);   
        
        // Si cambió el status de la cuenta y no hubo error de integración, debe enviarse alerta y la cuenta se envió a SAP 
        if (acc.Status__c!=accOld.Status__c  && acToUpdate.Send_alert_integration_error__c!=true && acc.Send_To_SAP__c){
            system.debug('Cambio Status acToUpdate:'+acToUpdate);
            if(acToUpdate.Id == null) {acToUpdate= acc; }
            acToUpdate.Send_change_Status_alert__c = true;
        }
        system.debug('RestClientAccount Status__c:'+acc.Status__c + ' old Status__c:'+accOld.Status__c);         
        
        // Actualizar en caso que algo haya cambiado
        try {
            if(acToUpdate.Id != null){
                update acToUpdate;
                system.debug('actualización finalizada.acToUpdate:'+acToUpdate);
            }
        } catch (exception e) {
            system.debug('Excepción:'+e.getMessage() + 'integration status:'+response.getStatus());
            // se actualiza la cuenta con los datos antiguos que tenía antes que el usuario los modificara
            accOld.Send_alert_integration_error__c = true;
            acc.Integration_Error__c=true;
            update accOld;
        } 
    }
    
    
    //AI genera el accountCode cuando se activa el check "send to SAP" de la cuenta
    public Static UT_Account.AccountWrapper setAccWpr (Account acc){
        
            UT_Account.AccountWrapper accWrp = new UT_Account.AccountWrapper();
            accWrp.AccountSFId=acc.Id;
            accWrp.AccountCode=acc.Account_code__c;
                       
            accWrp.LicTradNum      = acc.Federal_tax_ID__c;
            accWrp.AccountCurrency = acc.Currency__c;
            accWrp.OwnerSAPCode    = acc.owner_SAP_code__c;
            system.debug('RestClientAccount Owner.SAPCode__c:'+accWrp.OwnerSAPCode);
            accWrp.Name            = acc.Name;
            accWrp.Phone1          = acc.Phone;
            accWrp.E_Mail          = acc.Email__c;
            accWrp.Website         = acc.Website;
            accWrp.Celular         = acc.Mobile_number__c;
            accWrp.Status          = acc.Status__c;
            system.debug('RestClientAccount payment term:'+acc.Payment_term__c);
            accWrp.Payment_term    = acc.Payment_term__c;
            accWrp.CreditLimit     = acc.Credit_Limit__c;
            accWrp.NoModifyOwner    =acc.Don_t_update_SAP_user__c;
            accWrp.InternalReference=acc.Internal_reference__c; 
            accWrp.CompanyPresident = acc.Owner_President__c;
        
            // Asignar direcciones
            accWrp.Address_Line_1_Bill_1=acc.Address_Line_1_Bill_1__c;
            accWrp.Address_Line_1_Bill_2=acc.Address_Line_1_Bill_2__c;
            accWrp.Address_Line_1_Ship_1=acc.Address_Line_1_Ship_1__c;
            accWrp.Address_Line_1_Ship_2=acc.Address_Line_1_Ship_2__c;
            accWrp.Address_Line_2_Bill_1=acc.Address_Line_2_Bill_1__c;
            accWrp.Address_Line_2_Bill_2=acc.Address_Line_2_Bill_2__c;
            accWrp.Address_Line_2_Ship_1=acc.Address_Line_2_Ship_1__c;
            accWrp.Address_Line_2_Ship_2=acc.Address_Line_2_Ship_2__c;
            accWrp.City_Bill_1=acc.City_Bill_1__c;
            accWrp.City_Bill_2=acc.City_Bill_2__c;
            accWrp.City_Ship_1=acc.City_Ship_1__c;
            accWrp.City_Ship_2=acc.City_Ship_2__c;
            accWrp.Zip_code_Bill_1=acc.Zip_code_Bill_1__c;
            accWrp.Zip_code_Bill_2=acc.Zip_code_Bill_2__c;
            accWrp.Zip_code_Ship_1=acc.Zip_code_Ship_1__c;
            accWrp.Zip_code_Ship_2=acc.Zip_code_Ship_2__c;
        
        	// asignar paises de la cuenta y de las demás direcciones
            Location__c lo =UT_Account.getLocationInf(acc.Country__c);
            accWrp.AccountCountry=( lo!=null)? lo.code__c:null;  
            lo = UT_Account.getLocationInf(acc.Bill_main_Country__c);
            accWrp.Country_Bill_1   =( lo!=null)? lo.code__c:null;
            lo = UT_Account.getLocationInf(acc.Bill_2nd_Country__c);
            accWrp.Country_Bill_2   =( lo!=null)? lo.code__c:null;
            lo = UT_Account.getLocationInf(acc.Ship_main_Country__c);
            accWrp.Country_Ship_1   =( lo!=null)? lo.code__c:null;
            lo = UT_Account.getLocationInf(acc.Ship_2nd_Country__c);
            accWrp.Country_Ship_2   =( lo!=null)? lo.code__c:null;
          
        return accWrp;
    }

    //AI genera el accountCode cuando se activa el check "send to SAP" de la cuenta
    public Static Account getAccountCode (Account aNew, Account aOld){
        
        // Crear código identificador de la cuenta, sólo una vez cuando se activa el botón enviar a SAP
        if(aNew.Send_To_SAP__c && aOld.Send_To_SAP__c==false && aNew.Account_code__c==null)
        {
                    List<Location__c> lstLocation=[select id,Accoun_prefix_code__c from Location__c where id=:aNew.Country__c];
                    if(lstLocation.size()>0)
                    {
                        aNew.Account_code__c=UT_Account.getCodeAccount(lstLocation[0].Accoun_prefix_code__c);
                        system.debug('1.1 RestClientAccount Account_code__c:'+aNew.Account_code__c);
                        
                        aNew.Country_Prefix_Code__c=lstLocation[0].Accoun_prefix_code__c;
                        system.debug('1.2 RestClientAccount Country_Prefix_Code__c:'+aNew.Country_Prefix_Code__c);
                        aNew.Consecutive__c=UT_Account.getNextCodeAccount(lstLocation[0].Accoun_prefix_code__c);
                        system.debug('1.1 RestClientAccount Consecutive__c:'+aNew.Consecutive__c);
                    }
        }
     
        return aNew;
    }
     
    public static boolean accIsChanged (Account accOld, Account accNew) {
            
        boolean ischanged=false;
        if(accOld.Federal_tax_ID__c!=accNew.Federal_tax_ID__c ||accOld.Name!=accNew.Name ||accOld.Phone!=accNew.Phone ||
           accOld.Email__c!=accNew.Email__c ||accOld.Website!=accNew.Website ||accOld.Mobile_number__c!=accNew.Mobile_number__c ||
           accOld.Status__c!=accNew.Status__c ||accOld.Payment_term__c!=accNew.Payment_term__c ||accOld.owner_SAP_code__c != accNew.owner_SAP_code__c||
           accOld.Credit_Limit__c!=accNew.Credit_Limit__c ||accOld.Address_Line_1_Bill_1__c!=accNew.Address_Line_1_Bill_1__c ||
           accOld.Address_Line_1_Bill_2__c!=accNew.Address_Line_1_Bill_2__c ||accOld.Address_Line_1_Ship_1__c!=accNew.Address_Line_1_Ship_1__c 
           ||accOld.Address_Line_1_Ship_2__c!=accNew.Address_Line_1_Ship_2__c ||accOld.Address_Line_2_Bill_1__c!=accNew.Address_Line_2_Bill_1__c 
           ||accOld.Address_Line_2_Bill_2__c!=accNew.Address_Line_2_Bill_2__c ||accOld.Address_Line_2_Ship_1__c!=accNew.Address_Line_2_Ship_1__c 
           ||accOld.Address_Line_2_Ship_2__c!=accNew.Address_Line_2_Ship_2__c ||accOld.City_Bill_1__c!=accNew.City_Bill_1__c 
           ||accOld.City_Bill_2__c!=accNew.City_Bill_2__c ||accOld.City_Ship_1__c!=accNew.City_Ship_1__c ||accOld.City_Ship_2__c!=accNew.City_Ship_2__c 
           ||accOld.Zip_code_Bill_1__c!=accNew.Zip_code_Bill_1__c ||accOld.Zip_code_Bill_2__c!=accNew.Zip_code_Bill_2__c ||accOld.Zip_code_Ship_1__c!=accNew.Zip_code_Ship_1__c 
           ||accOld.Zip_code_Ship_2__c!=accNew.Zip_code_Ship_2__c ||accOld.Bill_main_Country__c!=accNew.Bill_main_Country__c 
           ||accOld.Bill_2nd_Country__c!=accNew.Bill_2nd_Country__c ||accOld.Ship_main_Country__c!=accNew.Ship_main_Country__c 
           ||accOld.Ship_2nd_Country__c!=accNew.Ship_2nd_Country__c || accNew.Country__c!=accOld.Country__c  || accNew.owner_President__c!=accOld.owner_President__c){
               
               ischanged=true;             
               
           }
        
         System.debug('RestClientAccount ischanged:'+ischanged);
        return ischanged;
    }    
    

}