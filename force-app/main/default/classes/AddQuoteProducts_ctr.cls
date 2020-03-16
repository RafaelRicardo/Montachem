/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase controladora de la VF AddQuoteProducts_pag que permite agregar productos a la cotización
 Clase de prueba:  AddQuoteProducts_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  07-12-2018 Alejandro iquira         Creación
****************************************************************************************/
public class AddQuoteProducts_ctr
{
    public String soql {get;set;}
    //map<String, Inventario_productos__c> inventario = new map<String, Inventario_productos__c> ();  
    List<QuoteLineItem> quoteProdToInsert;
    
    // Lista de productos resultado de ejecutar una búsqueda
    public List<ProductWrapper> resultProductList = new List<ProductWrapper>();
    
    
    // Lista de productos que han sido seleccionados en la búsqueda
    public List<ProductWrapper> selectedProducts2 {get;set;}
    
    // Lista de productos que han sido seleccionados en la búsqueda
    public integer cantProdAdded{get;set;}
    
    // ports list
    public List<SelectOption> portsOptionList{get;set;}
    
    // Container types list
    public List<SelectOption> containersOptionList{get;set;}
    
    
    //List de cantidad de registros que desea agregar de un mismo Product code
    public List<SelectOption> decRowsQtyList {get; set;}          
      
    //Porcentaje asignado según el término de pago de la cotización. Incrementa el precio de lista
    public decimal decPTermPercentage{get; set;}
    
    //Porcentaje asignado según el término de pago de la cotización. Incrementa el precio de lista
    public String strPTermPercentage;
    
    ApexPages.standardController controller = null;
    public Id idQuote;
    public Quote quote;
    public String idLista{get; set;}
   
    //Paginador
    public  integer totalRecs {get;set;}
    private integer index = 0;
    private integer blockSize = 15;    

    public AddQuoteProducts_ctr(ApexPages.StandardController controller) {
        
        System.debug('selectedProducts2:'+selectedProducts2);
        this.controller=controller;
        
        //Inicializar la lista de puertos
        portsOptionList= getOriginPortsList();
        
        //Inicializar la lista de tipos de contenedor
        containersOptionList= Utilities.getSelectOptions('QuoteLineItem', 'Container_type__c');
        
        // Inicializa lista con cantidad de registros a mostrar de un producto
        decRowsQtyList= new List<SelectOption>();
        decRowsQtyList.add(new selectoption ('1', '1') );
        decRowsQtyList.add(new selectoption ('2', '2') );
                    
        // Inicializa lista de productos seleccionados.
        selectedProducts2= new List<ProductWrapper>();
        
        // Inicializa cantidad de productos
        cantProdAdded= 0;
    
        // Asignar id de la cotización
        idQuote=ApexPages.currentPage().getParameters().get('id');
            SYSTEM.debug('VF controller constructor Id:'+idQuote);
        if(idQuote != null){
            quote=[select quote.Pricebook2Id, opportunity.Pricebook2Id,Payment_Term__c,Place_of_delivery__c from  quote where id = :idQuote];
            
            idLista= (Test.isRunningTest())? Test.getStandardPricebookId(): [select id from  pricebook2 where isStandard = true].get(0).id; 
            
            system.debug('VF controller constructor quote:'+quote + ' Id List:'+idLista);
            
            //inicializa el porcentaje según el término de pago de la cotización.   
                Payment_term_pricelist__c[] ptp = getPaymentTermPercent(quote.Payment_Term__c);
            If(ptp.size()>0){
                decPTermPercentage = ptp[0].Percentage__c;
            
            }else{ 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payment Term does not exist in "Payment terms % - pricelist" table. Contact Your Salesforce admin'));
            }
            
        }
        
        If(idLista==null || idLista==''){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Pricelist invalid'));
             // return null;
        }
         
        // Cantidad de registros totales para el paginador
        //totalRecs=[select count() from QuoteLineItem where quoteId = :idQuote];
        totalRecs=[select count() from PricebookEntry where Pricebook2Id = :idLista and isActive=true];
        soql = 'select Product2id, Product2.name, UnitPrice,Product2.family,Product2.MI__c,Product2.density__c, Product2.ProductCode'+
                ' from PricebookEntry where Pricebook2Id = :idLista and isActive=true '
                // +' and Producto__c not in(SELECT Producto_2__c from QuoteLineItem where Oferta__c= :idQuote)' 
            ;
        system.debug(' constructor soql :'+soql +'-idLista:'+idLista);
             
    }
            
    
    //AI Método que devuelve la propiedad que contiene los productos resultado de la búsqueda
    public List<ProductWrapper> getSearchedProducts()
    {
        resultProductList.clear();
        system.debug('1 getProductos2 soql :'+soql +'-'+'idLista:'+idLista);
        List<PricebookEntry > resultados = Database.query(soql + ' order by product2.name LIMIT : blockSize OFFSET : index  ' ) ;
        if (resultados.size() >0){
            for(PricebookEntry a:  Database.query(soql + ' order by product2.name LIMIT : blockSize OFFSET : index  ' ) )    
            {
              ProductWrapper pwrapper =new ProductWrapper(a,containersOptionList.get(0).getValue());
              resultProductList.add(pwrapper); 
              system.debug('3 getProductos2 resultProductList:'+resultProductList.size()+'-index:'+index+ ' primer registro'+resultProductList.get(0).quantity);
            }
        }else {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No results with criteria inserted.'));
           return null;
        }
        system.debug('4 getProductos2 resultProductList:'+resultProductList.size()+'-index:'+index+ ' primer registro'+resultProductList.get(0).quantity);
        return resultProductList;
    }
        
        
    // AI asigna los productos seleccionados de la VF a otro array
    public PageReference assignSelected()
    {
        
        system.debug('assignSelected 1:'+resultProductList);
        //selectedProducts2.clear();
        for(ProductWrapper p: resultProductList){ 
        
            if(p.selected == true){
                system.debug('assignSelected:'+ p.decRowsQty);
                
                //Agrega tantos productos 
                for(integer i=1;i<=p.decRowsQty;i++){
                    ProductWrapper pw= new ProductWrapper(p.pb2, p.containerType);
                    pw.listPrice = 0; //calculatePriceList(p.originPort, quote.Place_of_delivery__c, p.containerType ,p.costoFOB, quote.Payment_Term__c);
                    pw.salesPrice = String.valueof(0); //p.listPrice;
                    pw.selected   = true;
                    selectedProducts2.add(pw);
                }
                p.selected = false;
            }
            
            cantProdAdded= selectedProducts2.size();
                
        }
        return null;
    }
    
    // AI Refresca los precios de los productos una vez seleccionado el tipo de contenedor.
    public PageReference refreshListPrices(){
    
        system.debug('refreshListPrices inicial selectedProducts2:'+selectedProducts2);
        for(ProductWrapper p: selectedProducts2){
                
            If(decPTermPercentage==null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payment Term does not exist in "Payment terms % - pricelist" table. Contact Your Salesforce admin'));
            }
            
            p.pTermPercentage = decPTermPercentage;
            
            system.debug('refreshListPrices Product2:'+ p.pb2.Product2.Name+ ' container:'+p.containerType);
            
            p.freigthValue    = getFreightValue(p.originPort, null, quote.Place_of_delivery__c,null, p.containerType);
            
            system.debug('refreshlistprices 2 freigthValue:'+ p.freigthvalue+ ' p.costoFOB:'+p.costoFOB + ' p.pTermPercentage:'+p.pTermPercentage); 
            p.listPrice       = (p.freigthValue==0)? 0: (p.costoFOB +p.freigthValue ) * (1+ (p.pTermPercentage/100)); //calculatePriceList(p.originPort, quote.Place_of_delivery__c, p.containerType ,p.costoFOB, quote.Payment_Term__c);
            p.salesPrice      = String.valueOf(p.listPrice);
            
            system.debug('refreshlistprices 2 freight value:'+ p.freigthvalue); 
            

            if(p.listPrice<0){
                p.listPrice=0;
                p.salesPrice = String.valueOf(0);
            }
        }
        system.debug('refreshListPrices final selectedProducts2:'+selectedProducts2);
        return null;
    }
        
     // AI Método que obtiene freghts según puerto de origen, destino y contenedor.
    public decimal getFreightValue(Id originId, String originName, Id pDeliveryId, String deliveryName, String container){
        
        system.debug('getFreightValue Container:'+ container+ ' originId:'+originId + ' pDeliveryId:'+pDeliveryId);
                decimal total=0;        
        if( originId !=  null && pDeliveryId !=  null && container !=  null ){
            Freight__c freight=new Freight__c();
            try {
                    
                system.debug('getFreightValue 1 entra');
                freight= [select id, name, Origin__c,Origin__r.name, Place_of_delivery__c,Place_of_delivery__r.name, Value__c,Container_type__c from Freight__c 
                where Origin__c= :originId
                and Place_of_delivery__c = :pDeliveryId
                and Container_type__c = :container];
                system.debug('getFreightValue 2 freight'+freight);
                system.debug('getFreightValue 3 origin'+freight.Origin__r.name+ 'place of delivery:'+freight.Place_of_delivery__r.name);
                total=freight.Value__c;
            }catch (exception e) {
                    
                system.debug('excepción');
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Port of Origin: ' +originName+ ', Delivery port:'+deliveryName+ ' and container type: '+container+' are not set in Freights table.Contact Sys admin.'));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Port of Origin, Delivery port and container type are not set in Freights table.Contact Sys admin.'));
               
            return 0;
            }
        }
        return total;
    }
     
    
     // AI Método que guarda los elementos que han sido seleccionados.
    public Payment_term_pricelist__c[]  getPaymentTermPercent(String pTerm){
    
        map<String, decimal> mapPTP = new map<String, decimal>();
        Payment_term_pricelist__c[] ptp=[select id, Payment_term__c,Percentage__c from Payment_term_pricelist__c
                                       Where Payment_term__c=:pTerm];
            
        
        return ptp;
        
    }

     // AI Método que guarda los elementos que han sido seleccionados.
    public PageReference continuar(){
        return null;
    }        
    
    // AI Método que guarda los elementos que han sido seleccionados.
    public PageReference guardar(){
        
        Boolean existError=false;
        String errorMess=null;
        quoteProdToInsert = new List<QuoteLineItem>();
        
        try {
            system.debug('guardar 2. sise selected products:'+ selectedProducts2 );
       
            if(selectedProducts2.size()>0){
            
                For(ProductWrapper p: selectedProducts2){
                
                    // agregar sólo si el producto ha sido seleccionado
                    if(p.selected==true){                       
                        
                        system.debug('guardar 2.1product2:' + p.pb2.Product2 );
                        
                        QuoteLineItem quotProdTmp  = new QuoteLineItem ();
                        quotProdTmp.QuoteId                    = idQuote;
                        quotProdTmp.Product2                   = p.pb2.Product2;
                        decimal salePrice= decimal.valueof(p.salesPrice.remove(','));
                        system.debug('guardar unitPrice'+ p.salesPrice);
                        system.debug('guardar unitPrice sin coma'+ salePrice); 
                        
                        If( salePrice > 0 ){                    
                            quotProdTmp.UnitPrice                  = salePrice;         
                        }else{
                            existError= true;
                            errorMess ='Sales price must be greater than 0 for all products';       
                        }  
    
                        quotProdTmp.List_price__c              = p.listPrice;
                        quotProdTmp.PricebookEntryId           = p.pb2.id;  
                        quotProdTmp.Freight_value__c           = p.freigthValue;
                        quotProdTmp.Payment_term_percentage__c = p.pTermPercentage; 
                        quotProdTmp.Container_type__c          = p.containerType;
                        
                        If( p.quantity > 0 ){
                            quotProdTmp.Quantity                = p.quantity;          
                        }else{
                            existError= true;
                            errorMess ='Quantity for all products must be greater than 0';       
                        }
    
               
                        
                        system.debug('guardar 2.3 port:');
                        
                        If( p.originPort==null ){
                            existError= true;
                            errorMess ='Select a port of origin';                
                        }else{
                            quotProdTmp.Port_of_origin__c= p.originPort; 
                        }
                        
                        system.debug('guardar 2.4 port:' +p.originPort);
                        quoteProdToInsert.add(quotProdTmp);
                    }
                 }
             }  else{
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You have to select at least one product!'));
              return null;
            } 
            
            if(existError){
                system.debug('Guradar 3:'+errorMess);
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMess ));
              return null;
            }else{
                
                system.debug('quote Pricebook2Id:'+quote.Pricebook2Id);
                 
                if(quote.Pricebook2Id== null){
                    quote.Pricebook2Id= idLista;
                    update quote;
                }
                
                system.debug('guardar 3:'+quoteProdToInsert);
                insert quoteProdToInsert;
                
                PageReference oPageRef = new PageReference('/'+idQuote); 
                system.debug('guardar 4:'+idQuote + ' URL:'+ oPageRef.getUrl());
                oPageRef.setRedirect(false); //indicate that the redirect should be performed on the client side
                return oPageRef;
            }// end if exist error
              
         } catch (Exception e) {
              system.debug('guardar 6:'+e );
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'General Exception: '+ e + ' -cause:'+e.getCause()+' -msg:'+e.getMessage()));
              return null;
          }
    }
    
    // AI método ejecutado cada vez que se acciona algún campo de búsqueda
    public PageReference runSearch() {
    
        String familia= Apexpages.currentPage().getParameters().get('family');
        String grupo= Apexpages.currentPage().getParameters().get('Reference ');
        String subgrupo= Apexpages.currentPage().getParameters().get('Brand');
        String nombProd= Apexpages.currentPage().getParameters().get('productName');
        system.debug('1 runSearch familia:'+familia+'-grupo:'+grupo+'-subgrupo:'+subgrupo+'-nombProd:'+nombProd);
       
        soql = 'select Product2id, Product2.name, UnitPrice,Product2.family,Product2.MI__c,Product2.density__c,Product2.ProductCode'+
                ' from PricebookEntry where Pricebook2Id = :idLista and isActive=true  '
                // +' and Producto__c not in(SELECT Producto_2__c from QuoteLineItem where Oferta__c= :idQuote)' 
            ;
                //Lista_de_precios__c <> null ';
                 system.debug('1.1 runSearch soql :'+soql );
        if (!nombProd.equals('')){
              soql += ' and (Product2.name LIKE \'%'+String.escapeSingleQuotes(nombProd)+'%\' or Product2.productCode LIKE \'%'+String.escapeSingleQuotes(nombProd)+'%\')';
                 system.debug('2 runSearch nombProd no vacio:'+nombProd+'-');
                 }
        if (!familia.equals('')){
                 system.debug('3 runSearch -familiano vacio:'+familia+'-');
                 soql += ' and Product2.family LIKE \'%'+String.escapeSingleQuotes(familia)+'%\'';
          }
/*        if (!grupo.equals('')){     
                 system.debug('4 runSearch -grupono vacio:'+grupo+'-');
              soql += ' and Product2.MI__c LIKE \'%'+String.escapeSingleQuotes(grupo)+'%\'';
              }
        if (!subgrupo.equals('')){
                 system.debug('5 runSearch -subgrupono vacio:'+subgrupo+'-');
              soql += ' and Product2.density__c LIKE \'%'+String.escapeSingleQuotes(subgrupo)+'%\'';
              }
*/    
         system.debug('6 runSearch soql :'+soql );
         return null;
    }
    
     // returns the PageReference of the original page, if known, or the home page.
     public PageReference cancel() {
        return controller .cancel();
     }
     
        
    public void beginning()
    {
        index = 0;
    }
  
    public void previous()
    {   
            system.debug('previous index:' +index );
            index = index - blockSize;
    }
  
    public void next()
    {
        index = index + blockSize;
    }

    public void end()
    {
        index = totalrecs - math.mod(totalRecs,blockSize);
    }   
  
    public boolean getEnablePrev()
    {
            system.debug('previous getEnablePrev:' +index );
        if(index == 0)
        return true;
        else
        return false;
    }
  
    public boolean getEnableNxt()
    {
        system.debug('getEnableNxt index :'+index + ' blockSize:'+blockSize+ ' totalRecs:'+totalRecs);
        if((index + blockSize) >= totalRecs)
        return true;
        else
        return false;
    }  
    
    public List<SelectOption> getOriginPortsList()
    {
        List<SelectOption> ports= new List<SelectOption>();
        ports.add(new selectoption ('', '--Select--') );
        for(port__c p:[select id, name, Code__c, Country__c, Origin__c, Place_of_delivery__c from port__c where is_active__c= true order by name]){
            ports.add(new selectoption (p.id, p.name));
        }
        return ports;
    }
         
       public class ProductWrapper
    {
        public PricebookEntry pb2{get; set;}
        public Boolean selected {get; set;}
        public decimal costoFOB{get; set;}
        public decimal freigthValue{get; set;}
        public decimal pTermPercentage{get; set;}
        public decimal priceList{get; set;}
        public decimal listPrice{get; set;}
        
        public String salesPrice {get; set;}
        public decimal quantity {get; set;} // cantidad ingresada por el usuario
        
        public decimal decRowsQty {get; set;}  //cantidad de registros que desea ver para un producto seleccionado
        public String mensajeError{get; set;}
        public id listID {get; set;}
        
        public String containerType {get;set;}
        public id originPort  {get;set;}
        
        public ProductWrapper(PricebookEntry a,String container)
        {
            pb2 = a;
            selected    = false;
            quantity = 0;
//          mensajeError='Error'; 
            decRowsQty= 1;
            costoFOB= a.UnitPrice; 
            listPrice = a.UnitPrice; 
            salesPrice = String.ValueOf(a.UnitPrice); 
                        
            // Se agrega por defecto el primer valor encontrado en la lista.
            containerType=container;
        }
        
    }
    
}