/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            Alejandro iquira
/* Proyecto:         MONTACHEM
/* Descripción:      Clase administradora de los eventos de Quote.
/* Clase de prueba:  Quote_tgr_tst

/* Cambios (Versiones) 
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  02-07-2019  Alejandro Iquira         Creación básica de la cotización
/*************************************************************************************/ 
public class Quote_hdl {
    
    
	public static boolean firstRunWS = true;
    
    public Quote_hdl(){}

    public void OnAfterUpdate(Quote[] oldRecords, Quote[] newRecords){   
	
        // si el payment term o place of delivery cambian 
        if(firstRunWS && (oldRecords[0].payment_term__c != newRecords[0].payment_term__c || oldRecords[0].place_of_delivery__c != newRecords[0].place_of_delivery__c) && newRecords.size()==1){
            
            
            list<QuoteLineItem> quoteProducts =[ select id,Port_of_origin__c, Port_of_origin__r.Name, Container_type__c, Payment_term_percentage__c, UnitPrice, ListPrice, List_price__c
                                                 from QuoteLineItem where quoteID=:newRecords[0].id];
            firstRunWS=false;
            
            list<QuoteLineItem> productsToUpdate = new list<QuoteLineItem>();
            if(quoteProducts.size()>0){
                
                productsToUpdate = recalculatePrices(quoteProducts, newRecords[0]);
                
                if( productsToUpdate == null ){
                    
                    newRecords[0].addError('Place of delivery are not set in freight table or payment term are no set Payment Term % table. Contact T.O.');
                    
                }else{
                    
        			update productsToUpdate;
                    
                }
            }
            
            
            
        }
    }
    
    // AI Calcula los precios de venta de un grupo de una lista de productos
    public static list<QuoteLineItem> recalculatePrices(list<QuoteLineItem> products, Quote q){   
        
        list<QuoteLineItem> productsToUpdate = new list<QuoteLineItem>();
        if( products.size() < 100 ){
                
                
            for( QuoteLineItem p:products ){
                
                p.Freight_value__c = getFreightValue(p.Port_of_origin__c, p.Port_of_origin__r.Name, q.Place_of_delivery__c, q.Place_of_delivery__r.Name, p.Container_type__c);
                                
                Payment_term_pricelist__c[] ptp = getPaymentTermPercent(q.Payment_Term__c);
                
                system.debug('quote_hdl 1 Payment term:'+ptp);
                   
                If( ptp.size()>0 ){
                    
                    p.Payment_term_percentage__c = ptp[0].Percentage__c;
                    
                }else{
                    
                    system.debug('quote_hdl 2 Payment term inextente en la tabla de porcentages de payment term');
                    q.addError('quote_hdl Payment term are no set in Payment Term % table. Contact T.O.');
                    
                }
                
                decimal listPrice= (p.ListPrice==null)? 0:p.ListPrice;
                system.debug('quote_hdl 3 p.ListPrice:'+p.ListPrice + ' p.Freight_value__c:'+p.Freight_value__c + ' Payment_term_percentage__c:'+p.Payment_term_percentage__c + ' p.UnitPrice :'+p.UnitPrice );
                p.List_price__c = (p.Freight_value__c==0)? 0: ( listPrice+p.Freight_value__c ) * (1+ (p.Payment_term_percentage__c/100)); 
                system.debug('quote_hdl 4');
                p.UnitPrice = p.List_price__c;
                system.debug('quote_hdl 5');
                productsToUpdate.add(p);
                system.debug('quote_hdl 6');
            }
        }
        
        return productsToUpdate;
	
    }
    
    public static decimal getFreightValue(Id originId, String originName, Id pDeliveryId, String deliveryName, String container){
        
        system.debug('quote_hdl  getFreightValue Container:'+ container+ ' originId:'+originId + ' pDeliveryId:'+pDeliveryId);
                decimal total=0;        
        if( originId !=  null && pDeliveryId !=  null && container !=  null ){
            Freight__c freight=new Freight__c();
            try {
                    
                system.debug('getFreightValue 1 entra');
                freight= [select id, name, Origin__c,Origin__r.name, Place_of_delivery__c,Place_of_delivery__r.name, Value__c,Container_type__c from Freight__c 
							where Origin__c= :originId
							and Place_of_delivery__c = :pDeliveryId
							and Container_type__c = :container];
                system.debug('quote_hdl  getFreightValue 2 freight'+freight);
                system.debug('quote_hdl  getFreightValue 3 origin'+freight.Origin__r.name+ 'place of delivery:'+freight.Place_of_delivery__r.name);
                total=freight.Value__c;
            }catch (exception e) {
                    
                system.debug('excepción:'+e);
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Port of Origin: ' +originName+ ', Delivery port:'+deliveryName+ ' and container type: '+container+' are not set in Freights table.Contact Sys admin.'));
                return 0;
            }
        }
        return total;
    }
    
    
     // AI Método que guarda los elementos que han sido seleccionados.
    public static Payment_term_pricelist__c[]  getPaymentTermPercent(String pTerm){
    
        map<String, decimal> mapPTP = new map<String, decimal>();
        Payment_term_pricelist__c[] ptp=[select id, Payment_term__c,Percentage__c from Payment_term_pricelist__c
                                       Where Payment_term__c=:pTerm];
            
        return ptp;
        
    }
         
         

}