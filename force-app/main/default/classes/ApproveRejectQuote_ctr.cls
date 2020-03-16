/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase controladora de la VF que permite aprobar y rechazar soclitudes de aprobación de quotes.
 Clase de prueba:  ApproveRejectQuote_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  07-12-2018 Alejandro iquira         Creación
****************************************************************************************/
public without sharing class ApproveRejectQuote_ctr {

    public String comments   {get;Set;}
    public String approver   {get;Set;}
    public Quote currentQuote{get;Set;}
    public Opportunity opp   {get;Set;}
    public pageReference pg;
    public String validationError='';
    
    // option lists of lost reasons
    public List<SelectOption> lostReasonOptionList{get;set;}
    
    // selected lost reason
    public String lostReason{get;set;}
    
    // deshabilita el picklist de lost reason
    public boolean disableLostReason{get;set;}
    
    // vuelve obligatorio el picklist de lost reason
    public boolean requiredLostReason {get;set;}
    
    
    public ApproveRejectQuote_ctr(ApexPages.StandardController controller) {
    
        
        Quote q = (Quote) controller.getRecord();
        
        requiredLostReason = false;
        disableLostReason    = true;
        
        if(q.id!=null){
            
            // obtener demás campos de la cotización
            currentQuote = [SELECT id,OpportunityId,SAP_order_Id__c, opportunity.OwnerId, SAPDoc_Num__c   , Credit_Limit__c, Customer_Past_Due__c, status, 
                                   name, TRM__c,GrandTotal,Currency__c, Payment_Term__c, accountid, account.Payment_Term__c, account.Account_code__c 
                                  FROM quote WHERE Id = :q.id].get(0);
            system.debug('ApproveRejectQuote_ctr:'+currentQuote);
            
            
            // obtener oportunidad
            opp=[select id,lost_reason__c, StageName from opportunity where id= :currentQuote.opportunityid];
            
            //verificar aprobador actual según el status
            if(currentQuote.status=='Pending TO'){
                approver='T.O. analyst'; 
            } else if(currentQuote.status=='Pending Credit')  {
                approver          ='Credit analyst';
                disableLostReason = false;
            } else {
                approver='';             
            }
                        
            // Si el registro no ha sido enviado a aprobación
            if(!Utilities.hasPendingApproval(currentQuote.id)){
            
                validationError= 'There is not pending an approval process for this quote.';  
                system.debug('VF contructor has error:'+ validationError);
            }
            
            system.debug('VF contructor opportunity woner:'+ currentQuote.opportunity.OwnerId);
            
            // Si el propietario de la oportunidad no tiene asignado un rol
            if(!Utilities.userHasRole(currentQuote.opportunity.OwnerId)){
            
                validationError= 'Opportunity owner has not Role. Contact the sys admin.';  
                system.debug('VF contructor has error:'+ validationError);
            }
            
            pageReference pg= new pageReference('/'+currentQuote.Id);
            system.debug('VF contructor quote:'+ currentQuote.status);
        } 
        
        
        system.debug('VF contructor approver:'+ approver);
        if(approver=='' || approver==null){
        
            system.debug('VF constructor no approver:'+ approver);
        
            validationError= 'You can Approve/Reject only if the quote has "pending T.O" or "pending credit" status".';  
        }
        
        //Inicializar la lista de tipos de contenedor
        lostReasonOptionList= Utilities.getSelectOptions('opportunity', 'Lost_Reason__c');
        
        lostReasonOptionList.add(0,new selectoption( '','--None--'));
     
 
    }
    
    //AI si presionan "Approve"
    public pageReference approveRecord (){
        
        boolean isOk;
        Id profileId=userinfo.getProfileId();
        String profileUserName=[Select Id,Name from Profile where Id=:profileId].Name;
        
        if ((profileUserName == 'Credit Analyst'||profileUserName == 'Sales Representative')&& currentQuote.status=='Pending TO' )
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'You are not the assigned approver'));
            return null;            
        } 
        if (profileUserName == 'T.O. Analyst'&& currentQuote.status=='Pending Credit' )
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'You are not the assigned approver'));
            return null;            
        }         
        
        system.debug('approveRecord approver:'+ approver + ' currentQuote.id:'+currentQuote.id + ' validationError:'+validationError );
        try{
            
            if(currentQuote.id!=null  && approver=='T.O. analyst' && validationError==''){
                
                isOk=ApprovalTO ();
                
            }else if(currentQuote.id!=null && approver=='Credit analyst' && validationError==''){
            
                isOk=ApprovalCredit();
                
            }else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, validationError));                  
            }
            
            return null;
        }catch (Exception e) {
                    system.debug('VF approveReject error aprobando registro:'+e);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error approving the record. Contact de sys admin:'+ e));
                    return null;
        }
    
    }
    
    //AI si presiona rechazar registro
    public pageReference rejectRecord (){
        
        
        try{            
            
            if(currentQuote.id!=null  && (approver=='T.O. analyst' || approver=='Credit analyst') && validationError==''){
    
                // si el aprobador es Credito, no puede estar vacío el campo Razón de pérdida
                if((lostReason==null || lostReason=='') && approver=='Credit analyst' ){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lost reason is mandatory')); 
                }else{
                    opp.lost_reason__c= lostReason;
                    opp.Description= comments;
                    update opp;
                    
                    Utilities.apprRejRecord(currentQuote.id, 'Reject', comments);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successful transaction. Click "Back" to continue'));
                    
                }
            }else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, validationError));                  
            }
            
            return pg;
        }catch (Exception e) {
                    system.debug('VF approveReject error guardar T.O. reject:'+e);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error rejecting the record. Contact de sysadmin:'+ e));
                    return null;
        }
    
    }
    
    //AI si presiona Back to Draft, se rechaza la aprobación pero no se cierra perdida.
    public pageReference backToDraft (){
        
        try{         
            
            if (currentQuote.id != null  && (approver == 'T.O. analyst' || approver == 'Credit analyst') && validationError == ''){
             
                opp.Description = comments;
                opp.Dont_close_lost_opp__c = true; // evita cerrar perdida la oportunidad cuando el Approv. Process. cambie la cotización a estado cancelado
                update opp;
                
                Utilities.apprRejRecord(currentQuote.id, 'Reject', comments);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successful transaction. Click "Back" to continue'));
                /*
                currentQuote.status= 'Draft';  
                update currentQuote;
               */
              
            }else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, validationError));                  
            }
            
            return pg;
        }catch (Exception e) {
                    system.debug('VF approveReject error guardar T.O. reject:'+e);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error rejecting the record. Contact de sysadmin:'+ e));
                    return null;
        }
    
    }
    
    // Ejecuta todas las acciones necesarias para aprobación por parte del T.O. Si alguno de 
    public boolean ApprovalTO(){
    
        // If one of the WS has failed, this variable is false
        boolean transactionOK = false;
        
        // This variable gets the result of the WS with TRM, Credit limit and Cartera
        String[] resultTRMCredit;
        
        // This variable gets the result of create order WS invocation 
        String[] resultCreateOrder;
        
        // invoke WS that gets TRM, cartera and credit limit
        resultTRMCredit =  RestClientCarteraTRM.sendRequest(currentQuote.id);
        system.debug('VF approveReject 1 resultTRMCredit:');
           
        // if response is OK
        if (resultTRMCredit[0] == 'Ok') {
        
            transactionOK=true;
            system.debug('VF approveReject2 WS RestClientCarteraTRM OK');
                    
            currentQuote.TRM__c              = decimal.valueOf(resultTRMCredit[3]);
            currentQuote.Credit_Limit__c     = (resultTRMCredit[2]=='true')? true:false;
            currentQuote.Customer_Past_Due__c= (resultTRMCredit[1]=='true')? true:false;
            
            system.debug('VF approveReject3 ApprovalTO TRM__c:'+currentQuote.TRM__c + ' Credit_Limit__c:'+ currentQuote.Credit_Limit__c + ' Customer_Past_Due__c:'+currentQuote.Customer_Past_Due__c  );
            system.debug('VF approveReject4 ApprovalTO currentQuote.account.Payment_Term__c:'+currentQuote.account.Payment_Term__c + ' currentQuote.Payment_Term__c:'+ currentQuote.Payment_Term__c );
                            
            if (resultTRMCredit[1] == 'true' || resultTRMCredit[2] == 'true' || (currentQuote.account.Payment_Term__c!=currentQuote.Payment_Term__c && currentQuote.Payment_Term__c  != '18' )){ // Quote needs Credit Approval
                currentQuote.status              = 'Pending Credit';
                system.debug('VF approveReject5 va a credito');
                
                try{
    
                    if (transactionOK) {
                        
                        Utilities.apprRejRecord(currentQuote.id, 'Approve', comments);
                        update currentQuote;
                                system.debug('VF approveReject 6');
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successful transaction. Click "Back" to continue'));
               
                    }
                    return transactionOK;
                } catch (Exception e) {
                    system.debug('VF approveReject error guardar T.O. approval e:'+e);
                    system.debug('VF approveReject error guardar T.O. approval message:'+e.getMessage());
                    system.debug('VF approveReject error guardar T.O. approval getCause e:'+e.getCause());
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error updating the quote by TO analyst:'+ e));
                    return false;
                }
            
            
            }else { // If credit limit or customer past due are false, invoke WS to create order in SAP and SF
                
                system.debug('VF approveReject 7');
                transactionOK = ApprovalCredit();
               
            }
           
        }else {
               transactionOK = false;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error fetching TRM, Past due portfolio and credit limit:'+ resultTRMCredit[0]));
               system.debug('VF approveReject Error WS RestClientCarteraTRM');
        }
        
        
       return transactionOK;
        
    }
    
    
    
    // AI Logica que permite aprobar un registro por parte de un analista de crédito
    public boolean ApprovalCredit() {
    
        boolean opportunityHasOrder = hasOpportunityOrder(currentQuote.OpportunityId);
        boolean transactionOK = false;
        
        // si no tiene order, se invoca WS y se ejecuta lógica de creación de orden
        if (!opportunityHasOrder) {
            // This variable gets the result of create order WS invocation 
            String[] resultCreateOrder = RestClientCreateOrder.sendRequest(currentQuote.id,currentQuote.TRM__c);
                            
            
            system.debug('ApprovalCredit resultCreateOrder:'+resultCreateOrder);
            // Si la respuesta es OK y no se ha creado una orden en la oportunidad en SF, se crea solicita crear una orden en SAP 
            if(resultCreateOrder[0]=='Ok' && opportunityHasOrder ==false ){
                
                currentQuote.SAP_order_Id__c =  resultCreateOrder[1];            
                currentQuote.SAPDoc_Num__c   =  resultCreateOrder[2];        
                currentQuote.Create_Order__c =  true; //crea orden en SF   
                currentQuote.status          = 'Order To SAP';
                
                // actualiza oportunidad a cerrada ganada
                opp.SAP_order_ID__c = resultCreateOrder[1];           
                //opp.sap   = resultCreateOrder[2]; 
                
                
                system.debug('ApprovalCredit WS ok');
                transactionOK = true;
                           
            }else {
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error creating an order in SAP. Contact your sys admin. Error:'+ resultCreateOrder[0]));
                transactionOK = false;
            }
            
        }else { // existe orden asociada a la oportunidad
            
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Order has not been created in SAP because already exist an order related to the opportunity.'));
            
                transactionOK = false;
            
        } // end if Opportunity has order
        
        try{
            
            if (transactionOK) {
                
                Approval.unlock(currentQuote.id);
                system.debug('VF approveReject quote unlocked');
                //update opp;
                update currentQuote;
                system.debug('VF approveReject quote updated');
                Utilities.apprRejRecord(currentQuote.id, 'Approve', comments);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successful transaction. Click "Back" to continue'));
                
            }        
           return transactionOK;
        } catch (Exception e) {
            system.debug('VF approveReject error guardar credit approval:');
            system.debug('VF approveReject error guardar T.O. approval message:'+e.getMessage());
            system.debug('VF approveReject error guardar T.O. approval message:'+e.getCause());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error updating the opportunity '+ e));
            return false;
        }
        
       
    }
    
    // AI Indica si tiene alguna orden relacionada a la oportunidad
    public static boolean hasOpportunityOrder (id opportunityId){
    
        list<order__c> o = [SELECT Name,id FROM order__c WHERE opportunity__c= :opportunityId];
        if ( o.size() > 0 ){
            
            return true;
            
        }else { 
            
            return false; 
        }
    
    }
    
    

}