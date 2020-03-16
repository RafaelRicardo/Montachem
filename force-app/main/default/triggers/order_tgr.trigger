/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            Alejandro Iquira
/* Proyecto:         MONTACHEM
/* Descripción:      Trigger del obeto orden que calcula el valor en letras de la orden y envia pdf de la orden al propietario
/* Clase de prueba:  Order_tgr_tst

/* Cambios (Versiones) 
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  09-Sep-2019 Alejandro Iquira        
/*                                 
/*************************************************************************************/ 
trigger order_tgr on Order__c (before insert, after insert, before update) {

    if ((Trigger.isInsert || Trigger.isUpdate ) && Trigger.IsBefore){
        for (Order__c o : Trigger.new)  
        {
            if (o.Order_total_value__c != null && o.Order_total_value__c >= 0) 
            {
                //Long n = o.Order_total_value__c.longValue();
                o.Order_total_value_in_words__c = UT_NumberToWord.english_number(o.Order_total_value__c);
            }  
        }
        
    }
    
    
    
    if (Trigger.isInsert && Trigger.IsAfter && Trigger.new.size()==1)
    {        
        system.debug('order tgr owner opp :');
        // Se envia el pdf al correo del propietario de la oportunidad
        if ( Trigger.new.get(0).opportunity__c != null ) Order_hdl.sendOrderToOwner(Trigger.new);
    }
    
    
}