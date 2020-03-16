/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            William Dorado
/* Proyecto:         MONTACHEM
/* Descripción:      Clase administradora de los eventos de Cuenta (Account)
/* Clase de prueba:  Account_tst

/* Cambios (Versiones) 
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  09-Oct-2018 William Dorado          Creación del handler correspondiente al
/*                                          Trigger de Account
/*************************************************************************************/ 
public with sharing class Account_hdl {
    
    // Campos
    private boolean blnIsExecuting = false;
    private integer intBatchSize = 0;
    public static Boolean isFirstTime = true;
    
    
    // Constructor
    public Account_hdl(boolean isExecuting, integer size){
        blnIsExecuting = isExecuting;
        intBatchSize = size;
    }
    
    // Métodos de atención a evento
    //public void OnBeforeInsert(Account[] newRecords){
    
    //}
    
    public void OnBeforeUpdate(Account[] oldRecords, Account[] newRecords, Map<ID, Account> recordMap)
    {   
        system.debug('1 Account_hdl newRecords[0].Send_To_SAP__c:'+newRecords[0].Send_To_SAP__c + ' oldRecords[0].Send_To_SAP__c:'+oldRecords[0].Send_To_SAP__c);   
        
        // Si no se envió a SAP, en caso de cambios en "Status" o "Credit Status" se debe activar flag para enviar correo
        if (!newRecords[0].Send_To_SAP__c){
            
            // Si cambió el credit status de la cuenta y no hubo error de integración
            if (newRecords[0].Credit_status__c!=oldRecords[0].Credit_status__c){
                newRecords[0].Send_change_credit_status_alert__c = true;
            }
            system.debug('Accoun_hdl Credit_status__c:'+newRecords[0].Credit_status__c + ' old Credit_status__c:'+oldRecords[0].Credit_status__c);   
            
            // Si cambió el status de la cuenta y no hubo error de integración
            if (newRecords[0].Status__c!=oldRecords[0].Status__c){
                newRecords[0].Send_change_Status_alert__c = true;
            }
            system.debug('Accoun_hdl Status__c:'+newRecords[0].Status__c + ' old Status__c:'+oldRecords[0].Status__c);  
            
        }
        
    }
    
    
    public void OnAfterUpdate(Account[] oldRecords, Account[] newRecords, Map<ID, Account> recordMap)
    {
        system.debug('2 Account_hdl newRecords[0].Send_To_SAP__c:'+newRecords[0].Send_To_SAP__c + ' oldRecords[0].Send_To_SAP__c:'+oldRecords[0].Send_To_SAP__c+ ' isFuture():'+system.isFuture());   
        
        // AI Invocar Web service que envía información de la cuenta a SAP
        if(newRecords.size()==1 && !(system.isFuture()) && isFirstTime)
        {
            system.debug('3 Account_hdl newRecords[0].Send_To_SAP__c:'+newRecords[0].Send_To_SAP__c + ' oldRecords[0].Send_To_SAP__c:'+oldRecords[0].Send_To_SAP__c);   
            
            String aNew= JSON.serialize(newRecords[0]);
            String aOld= JSON.serialize(oldRecords[0]);
            RestClientAccount.sendRequest(aNew,aOld,newRecords[0].id);
            system.debug('4 Account_hdl newRecords[0].Send_To_SAP__c:'+newRecords[0].Send_To_SAP__c + ' oldRecords[0].Send_To_SAP__c:'+oldRecords[0].Send_To_SAP__c);   
            isFirstTime = false;

        }
        
    }
    
    /* public void OnAfterInsert(Account[] newRecords){

}
public void OnAfterUpdate(Account[] oldRecords, Account[] updatedRecords, Map<ID, Account> recordMap){

}

public void OnBeforeDelete(Account[] recordsToDelete, Map<ID, Account> recordMap){

}

public void OnAfterDelete(Account[] deletedRecords, Map<ID, Account> recordMap){

}*/
    
    
}