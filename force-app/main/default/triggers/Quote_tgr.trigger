/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro iquira
 Proyecto:         MONTACHEM
 Descripción:      trigger en cuentas
 Clase de prueba:  Quote_tgr_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  02-07-2019  Alejandro Iquira         Creación básica Trigger de Quote
****************************************************************************************/
trigger Quote_tgr on Quote (before insert, before update, after update) {

    if(Trigger.isUpdate && Trigger.isAfter){
        
        Quote_hdl qhdl= new Quote_hdl();
		qhdl.OnAfterUpdate(trigger.old, trigger.new);           
        
    }
}