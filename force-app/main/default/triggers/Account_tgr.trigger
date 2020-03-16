/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            William Dorado
 Proyecto:         MONTACHEM
 Descripción:      trigger en cuentas
 Clase de prueba:  Account_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  15-11-2018 William Dorado         Creación básica Trigger de Account
 1.1  15-11-2018 Alejandro Iquira       Agregar lógica
****************************************************************************************/
trigger Account_tgr on Account (before insert, before update, after update) 
{
    system.debug('0 trigger');   
    Account_hdl handler = new Account_hdl(Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isUpdate && Trigger.isBefore){
      
        system.debug('0 trigger update before');   
        if(Trigger.new.size()==1)
            
        	{	
        		handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap);
            }                
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        system.debug('0 trigger update after');  
        handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.newMap);
    }
}