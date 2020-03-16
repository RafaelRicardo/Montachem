/***************************************************************************************************************
* Vass 
* @author           Wiliam Dorado
* Proyecto:         Montachem
* Description:      Servicio rest para actualizar las ordenes
****************************************************************************************************************/
@RestResource(urlMapping='/UpdateOrder/*')
global with sharing class OrderService
{ 

  /*******************************************************************************************
  ACTUALIZA LAS ORDENES
  ********************************************************************************************/
    @HttpPost
    global static String send()
    {   
   
		RestRequest req = RestContext.request;
        RestResponse res = RestContext.response; 
        String reqBody = req.requestBody.toString();        
        
        try
        {

            system.debug('OrderService 0 RestContext:'+res);
            system.debug('OrderService 0 reqBody:'+reqBody);
            jsonOrder objOrdenIn=(jsonOrder)JSON.deserialize(reqBody,jsonOrder.class);
            system.debug('OrderService 1 SAPDoc_Entry:'+objOrdenIn.SAPDoc_Entry+ '-objOrdenIn:'+objOrdenIn);
            
            List<Order__c> lstOrden=[select id,Account__c,Opportunity__c,Name,SAP_Order_ID__c,SAPDoc_Num__c,Status__c,DocDate__c,Delivery_Date__c,Shipment_Date__c,
                                     Customer_Ref__c,Consignee__c,Notify__c,Payment_Term__c,Incoterm__c,Place_of_delivery__c,Commission__c,
                                     Remarks__c,CRD__c,ETA__c,ETD__c,Booking_BL__c,S_Line__c,Vessel__c,Voyage__c,Country_comments__c
                                     from order__c where SAP_Order_ID__c=:objOrdenIn.SAPDoc_Entry];
            
            map<string, Port__c> mapPorts = getPorts();
            
            system.debug('OrderService 2:'+lstOrden);
            //actualiza la orden y sus productos
            if(lstOrden.size()>0)
            {
                Order__c objOrden=lstOrden[0];
                //actualiza el objeto orden
                //IF(objOrden.id!=null)objOrden.id=objOrdenIn.id;
                IF(objOrdenIn.Status!=null)objOrden.Status__c=objOrdenIn.Status;
                IF(objOrdenIn.DocDate!=null)objOrden.DocDate__c=date.parse(objOrdenIn.DocDate);
                IF(objOrdenIn.Delivery_Date!=null)objOrden.Delivery_Date__c=date.parse(objOrdenIn.Delivery_Date);
                IF(objOrdenIn.Shipment_Date!=null)objOrden.Shipment_Date__c=date.parse(objOrdenIn.Shipment_Date);
                IF(objOrdenIn.Customer_Ref!=null)objOrden.Customer_Ref__c=objOrdenIn.Customer_Ref;
                
                system.debug('Order service Consignee'+objOrdenIn.Consignee + '-Notify:'+objOrdenIn.Notify);
                
                // Asigna consignee
                IF(objOrdenIn.Consignee!=null && objOrdenIn.Consignee!=''){
                    
                    // variable temp. para asignar cuenta de SF en consignee y notify
                    list<Account> acTmp =getAccount(objOrdenIn.Consignee);
                	system.debug('1.3:'+acTmp.size());
                        
                    if (acTmp.size()>0){
                    	objOrden.Consignee__c= acTmp.get(0).id;
                    } else {
                        return ArmaResponse('ERROR','Consignee code:'+objOrdenIn.Consignee+' does not exist in Salesforce. ');
                    }
                }   
                
                // Asigna notify 
                IF(objOrdenIn.Notify!=null && objOrdenIn.Notify!=''){
                    
                    // variable temp. para asignar cuenta de SF en consignee y notify
                    list<Account> acTmp =getAccount(objOrdenIn.Consignee);
                        
                    if (acTmp.size()>0){
                    	objOrden.Notify__c= acTmp.get(0).id;
                    } else {
                        system.debug('Error: producto no existe');
                        return ArmaResponse('ERROR','Notify code:'+objOrdenIn.Notify+' does not exist in Salesforce. ');
                    }
                }
                                
                
                IF(objOrdenIn.Payment_Term!=null)objOrden.Payment_Term__c=objOrdenIn.Payment_Term;
                IF(objOrdenIn.Incoterm!=null)objOrden.Incoterm__c=objOrdenIn.Incoterm;
                
                IF(objOrdenIn.Place_of_delivery!=null){
                    
                    if(mapPorts.containskey(objOrdenIn.Place_of_delivery)){
                        objOrden.Place_of_delivery__c=mapPorts.get(objOrdenIn.Place_of_delivery).id;
                    }else {
                        
                        res.statusCode=500;
                        return ArmaResponse('ERROR','Place of delivery:'+objOrdenIn.Place_of_delivery+' does not exist in Salesforce. ');
                    }
                }
                 
                IF(objOrdenIn.Commission!=null)objOrden.Commission__c=decimal.ValueOf(objOrdenIn.Commission);
                IF(objOrdenIn.Remarks!=null)objOrden.Remarks__c=objOrdenIn.Remarks;
                IF(objOrdenIn.CRD!=null)objOrden.CRD__c=date.parse(objOrdenIn.CRD);
                IF(objOrdenIn.ETA!=null)objOrden.ETA__c=date.parse(objOrdenIn.ETA);
                IF(objOrdenIn.ETD!=null)objOrden.ETD__c=date.parse(objOrdenIn.ETD);
                IF(objOrdenIn.Booking_BL!=null)objOrden.Booking_BL__c=objOrdenIn.Booking_BL;
                IF(objOrdenIn.S_Line!=null)objOrden.S_Line__c=objOrdenIn.S_Line;
                IF(objOrdenIn.Vessel!=null)objOrden.Vessel__c=objOrdenIn.Vessel;
                IF(objOrdenIn.Voyage!=null)objOrden.Voyage__c=objOrdenIn.Voyage;
                IF(objOrdenIn.Country_comments!=null)objOrden.Country_comments__c=objOrdenIn.Country_comments;
                 
                update objOrden;
                
                // si además del encabezado de la orden, se solicita actualizar productos 
                if(objOrdenIn.modifyOrderHeader!=null&&objOrdenIn.modifyOrderHeader!='true'  //valida si solo se actualizara la orden
                   && objOrdenIn.lstProductos!=null&&objOrdenIn.lstProductos.size()>0)       // si hay productos de la orden en el WS 
                {	
                    //setOrderProducts();
                    
                    system.debug('2:'+objOrdenIn.lstProductos);
                    //  Contendrá lista con códigos de productos obtenidos en el WS
                    list<string> servicePrdCodes = new list<string>();
                    
                    // recorrer productos obtenidos en el WS para obtener listado de prpoductCodes
                    for(jsonOrderProduct prdCode: objOrdenIn.lstProductos)
                    {
                        servicePrdCodes.add(prdCode.ItemCode);
                    }
                    system.debug('3 servicePrdCodes:'+servicePrdCodes);
                    
                    // Obtener mapa con productos del catálogo de SF
                    map<string, product2> mapProducts = getProductsMap(servicePrdCodes); 
                    
                    
                    //Lista que contendrá los productos que actuamente existen en la orden para ser borrados
                    List<Order_Product__c> lstOrderProdToDelete=[SELECT id FROM Order_Product__c 
                                                             where Order__r.SAP_Order_ID__c=:objOrdenIn.SAPDoc_Entry];
                    
                    // Lista con productos que se insertarán
                     List<Order_Product__c> lstOrderProducts=new List<Order_Product__c>();
                    
                    // recorrer listado de producto obtenidos enviados en el WS
                    for(jsonOrderProduct jsonOrdPrd:objOrdenIn.lstProductos)
                    {
                        system.debug('5 JsonOrdPrd:'+JsonOrdPrd);
                        Order_Product__c OrderProduct = new Order_Product__c();
                        OrderProduct.Sales_price__c   = JsonOrdPrd.Sales_price;
                        OrderProduct.Quantity__c 	  = JsonOrdPrd.Quantity;
                        OrderProduct.Order__c 		  = objOrden.id;
                        OrderProduct.Container__c     = String.ValueOf(JsonOrdPrd.Container);
                        OrderProduct.density__c       = (JsonOrdPrd.density ==null)?    '':JsonOrdPrd.density;                          
                        OrderProduct.Melt_Index__c    = (JsonOrdPrd.MI ==null)? '': JsonOrdPrd.MI;  
                        
                        IF(JsonOrdPrd.Origin!=null){
                    
                            if(mapPorts.containskey(JsonOrdPrd.Origin)){
                                OrderProduct.Port_of_origin__c=mapPorts.get(JsonOrdPrd.Origin).id;
                            }else {
                                
                                res.statusCode=500;
                                return ArmaResponse('ERROR','Port of Origin:'+JsonOrdPrd.Origin+' does not exist in Salesforce. ');
                            }
                        }
                        
                        system.debug('6 ordPJsonOrdPrd.ItemCode:'+JsonOrdPrd.ItemCode+JsonOrdPrd.density+JsonOrdPrd.MI);
                        
                        // se relaciona producto de la orden al producto del catálogo de prod. 
                        if(mapProducts.containsKey(JsonOrdPrd.ItemCode+OrderProduct.density__c+OrderProduct.Melt_Index__c)){
                            
                            system.debug('6.1. ordPJsonOrdPrd.ItemCode:'+JsonOrdPrd.ItemCode+JsonOrdPrd.density+JsonOrdPrd.MI);
                            OrderProduct.Product__c=  mapProducts.get(JsonOrdPrd.ItemCode+OrderProduct.density__c+OrderProduct.Melt_Index__c).id;
                        }else{
                            // si no existe con el MI y density, se busca sólo por código
                            if(mapProducts.containsKey(JsonOrdPrd.ItemCode)){
                                system.debug('6.2. ordPJsonOrdPrd.ItemCode:'+JsonOrdPrd.ItemCode);
                                OrderProduct.Product__c=  mapProducts.get(JsonOrdPrd.ItemCode).id;
                            }else{
                                res.statusCode=500;
                                return ArmaResponse('ERROR','ProductCode:'+ JsonOrdPrd.ItemCode+ ' does not exist.');
                            }
                        }
                        
                        system.debug('7 ordPJsonOrdPrd.ItemCode:'+JsonOrdPrd.ItemCode+ '-JsonOrdPrd.density:'+JsonOrdPrd.density+ '-JsonOrdPrd.MI:'+JsonOrdPrd.MI);
                        
                        
                        lstOrderProducts.add(OrderProduct);
                    }// end loop recorrer productos enviados en el WS
                    
                    
                    if(lstOrderProdToDelete.size()>0)
                    	delete lstOrderProdToDelete;
                    
                    if(lstOrderProducts.size()>0)
                        insert lstOrderProducts;
                }
                
            }else
            {
                res.statusCode=500;
                system.debug('Error:Order does not exist');
                return ArmaResponse('ERROR','Order does not exist in Salesforce.');
            } // end if lstOrden.size()>0
            
        }catch(Exception ex)
        {			
            system.debug('Error: General Exception'+ex);
            res.statusCode=500;
            return ArmaResponse('ERROR','An error ocurred:'+ ex.getMessage() + '. Line:'+ex.getLineNumber()+ ' cause:'+ex.getCause());
        } 
        
        //arma la respuesta
        
        system.debug('Terminado exitosamente');
        return ArmaResponse('OK','Operación Exitosa');

	}
  
    // Este método recibe una lista de ProductCodes y devuelve un mapa con todos los productos
    // que coinciden con dichos Productcodes. La clave del mapa es el prpoduct Code
    public static map<string, product2> getProductsMap(List<String> servicePrdCodes){
        
		map<string, product2> mapProducts = new map<string, product2>();
        
        // llenar mapa de con productos de catálogo según lista de productCodes
        for(Product2 prd: [select id, productcode, MI__c, Density__c 
                           from Product2 where productCode in :servicePrdCodes order by MI__c, Density__c ])
        {		
            if(!mapProducts.containsKey(prd.productcode+prd.MI__c+prd.Density__c)){
                mapProducts.put(prd.productcode+prd.Density__c+prd.MI__c, prd);
            }
        }
        
        // En caso de no existir un prod. en el catálogo de SF cuyo density y MI son vacíos, se agrega al Mapa 
        // para relacionar aquellos productos enviados en el WS a los que no les detallaron dichos valores.
        for(Product2 prd: [select id, productcode, MI__c, Density__c 
                           from Product2 where productCode in :servicePrdCodes order by MI__c, Density__c ])
        {		
            // Se agrega el primer producto de catálogo que se retorne en el Query
            if(!mapProducts.containsKey(prd.productcode)){
                mapProducts.put(prd.productcode, prd);
            }
        }
        
        system.debug('4 mapProducts:'+mapProducts);
        
        return mapProducts;
        
    }
     
    // Función que devuelve un map con todos los puertos
    public static map<string, Port__c> getPorts()
    {	
		map<string, port__c> mapPorts = new map<string, port__c>();
        for(port__c p:[select id, Code__c from port__c]){
            mapPorts.put(p.code__c, p);
        }
        
        return mapPorts;
    
    }
    
    
    // Devuelve la cuenta perteneciente al código enviado como parámetro
    public static list<Account> getAccount(String accountCode)
    {
    
		list<Account> acc = [select id, name,Account_code__c  from Account where Account_code__c=:accountCode ];
        return acc;
    }
    
  /*******************************************************************************************
  OBJETOS JSON
  ********************************************************************************************/
  public static String ArmaResponse(String Estado,String Mensaje)
  {
      Response objResponse=new Response();
      objResponse.Mensaje=Mensaje;
      objResponse.Estado=Estado;
      
      return JSON.serialize(objResponse);
  }
  
  global class jsonOrder { 

      Global String id;
      Global String Name;
      Global String SAPDoc_Entry;
      Global String SAPDoc_Num;
      Global String Status;
      Global String DocDate;
      Global String Delivery_Date;
      Global String Shipment_Date;
      Global String Customer_Ref;
      Global String Consignee;
      Global String Notify;
      Global String Payment_Term;
      Global String Incoterm;
      Global String Place_of_delivery;
      Global String Commission;
      Global String Remarks;
      Global String CRD;
      Global String ETA;
      Global String ETD;
      Global String Booking_BL;
      Global String S_Line;
      Global String Vessel;
      Global String Voyage;
      Global String country_comments;
      Global String orderCurrency;
      
      global String modifyOrderHeader;//true,false      
      global List<jsonOrderProduct> lstProductos;
  }

  global class jsonOrderProduct { 
 
        global String ItemCode; 
        global decimal Sales_price; 
        global decimal Quantity; 
        global String Origin; 
        global integer Container;  
        global String MI; 
        global String density; 
 
  }  

  global class Response { 

        global String Estado; 
        global String Mensaje; 

  }
}