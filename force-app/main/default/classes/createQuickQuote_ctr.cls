/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase controladora de la VF createQuickQuote_pag que permite crear de manera rápida una cotización con productos optimizada para mobile. También modificar productos.
 Clase de prueba:  createQuickQuote_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  07-07-2019 Alejandro iquira         Creación
 1.1  28-11-2019 Angela Munevar (AM)	  Se agregaron los campos Notify y Consignee
****************************************************************************************/
public class createQuickQuote_ctr {
 
    public String soql {get;set;}
    public String accCode  {get;set;}
    public List<QuoteLineItem> quoteProdToUpsert;
    public Map<String,QuoteLineItem> mapQuoteProdToUpsert ;
    public List<QuoteLineItem> quoteProdToDelete;
    
        // Guarda los productos que tenía una cotización antes de ser modificada
    public List<QuoteLineItem>       oldProducts     {get; set;}
    
    // Lista de productos resultado de ejecutar una búsqueda
    public List<ProductWrapper> resultProductList = new List<ProductWrapper>();
    
    
    // Mapa con productos resultado de cada búsqueda
    public map<id, ProductWrapper> resultProductMap = new map<id, ProductWrapper> ();
    
    
    // Mapa de productos que han sido agregados carro de productos seleccionados
    public map<integer, ProductWrapper>  selectedProductsCart = new map<integer, ProductWrapper>(); //{get;set;}
    public map<integer, ProductWrapper>  mapSelectedProductsCart = new map<integer, ProductWrapper>();
    
    // Lista de productos que han sido seleccionados en la búsqueda
    public List<ProductWrapper> selectedProducts2 {get;set;}
    
    // Lista de productos que han sido seleccionados en la búsqueda
    public integer cantProdAdded{get;set;}
    
    // ports list
    public List<SelectOption> portsOptionList{get;set;}
    
    // Container types list
    public List<SelectOption> containersOptionList{get;set;}
    
    // Payment terms types list
    public List<SelectOption> paymentTermsOptionList{get;set;}
    
    // incoterms types list
    public List<SelectOption> incotermsOptionList{get;set;}
    
    // currency types list
    public List<SelectOption> currencyOptionList{get;set;}
    
    // Container types list
    public List<SelectOption> contactsOptionList{get;set;}
      
    //Porcentaje asignado según el término de pago de la cotización. Incrementa el precio de lista
    public decimal decPTermPercentage{get; set;}
    
    //Porcentaje asignado según el término de pago de la cotización. Incrementa el precio de lista
    public String strPTermPercentage;
    
    ApexPages.standardController controller = null;
    public String idLista{get; set;}
    public Account acc{get; set;}
   
    //Paginador
    public  integer totalRecs {get;set;}
    private integer index = 0;
    private integer blockSize = 15;    
    
    
    // Quote fields
    public Quote quoteToCreate;
    public String       CustomerRef    {get;set;}  //DARFCUSTOMER
    public String       quoteName    {get;set;}  
    public String       paymentTerm  {get;set;} 
    public String       incoterms    {get;set;} 
    public String       deliveryPlace{get;set;} 
    public String       deliveryPlaceName{get;set;}
    public String       NotifyId{get;set;} 
    public String       NotifyName{get;set;}
    public String       ConsigneeId{get;set;} 
    public String       ConsigneeName{get;set;}
    public String       Consigneedefaul{get;set;}
    public String       ConsigneedefaulId{get;set;}
    public String       Notifydefaul{get;set;}
    public String       NotifydefaulId{get;set;}
    public date         deliveryDate {get;set;} 
    public date         postingDate  {get;set;} 
    public String         deliveryDateOld {get;set;} 
    public String         postingDateOld  {get;set;} 
    public String       contactoID      {get;set;} 
    public String       contactoEmail      {get;set;} 
    public String       contact      {get;set;} 
    public List<String> lstContact   {get;set;} 
    public String       quoteCurrency     {get; set;}
    public String       commission     {get; set;}
    
    //Contacto que se relacionará a la cotización y en caso de no existir, se creará
    public Contact      contactToInsert     {get; set;}
    
    // Oportunidad
    Opportunity opp;
    
    // quote attach
    public ID       templateID;
    public QuoteDocument attachedQuotePDF;
    public String emailBody   {get; set;}
    public String AditionalEmails   {get; set;}
    public String contactEmail      {get; set;}
 
    // contiene el mayor Id generado de los productos (clase ProductWrapper) agregados al carro de compras
    public integer maxWrapperId;
    
    // Propiedad que contiene el producto seleccionado de la lista de productos en la seccion ProductListSection  
    public ProductWrapper currentSelectedProduct {get;set;} 
    public String selectProdDescription {get;set;}   
    
    
    // Campos del nuevo contacto
    public boolean       createNewContact      {get;set;} 
    public String       newContactName      {get;set;} 
    public String       newContacLast      {get;set;} 
    public String       newContacEmail      {get;set;} 

    //Variable que especificará si se cerrará la ventana despues de guardar o no
    public String       saveNoClose      {get;set;} 
    
    public createQuickQuote_ctr (ApexPages.StandardController controller) {
        
        this.controller=controller;
        
        //ApexPages.currentPage().getParameters().put('id','001m000000p1msfAAA');
        //accountId = ApexPages.currentPage().getParameters().get('id');
        acc = (Account)controller.getRecord();
        system.debug('constructor cuenta:'+ acc);
        accCode= ApexPages.currentPage().getParameters().get('code');
        System.debug('+++accCode '+accCode);
        //Inicializar la lista de puertos
        portsOptionList= getOriginPortsList();
        
        //Inicializar la lista de tipos de contenedor
        containersOptionList  = Utilities.getSelectOptions('QuoteLineItem', 'Container_type__c');
        
        //Inicializar la lista de tipos de contenedor
        paymentTermsOptionList = Utilities.getSelectOptions('Quote', 'Payment_Term__c');
        
        //Inicializar la lista de tipos de contenedor
        incotermsOptionList= Utilities.getSelectOptions('Quote', 'Incoterm__c');
        incotermsOptionList.add(0, new selectoption('', '--Select--'));
        
        //Inicializar la lista de tipos de contenedor
        currencyOptionList= Utilities.getSelectOptions('Quote', 'Currency__c');
        
        //Inicializar la lista de contactos de cuenta
        contactsOptionList=getContactList(acc.id);
                            
        // Inicializa lista de productos seleccionados.
        selectedProducts2= new List<ProductWrapper>();
        selectedProductsCart  = new map<integer, ProductWrapper>  ();
        
        // Inicializa cantidad de productos
        cantProdAdded= 0;
    
        idLista= (Test.isRunningTest())? Test.getStandardPricebookId(): [select id from  pricebook2 where isStandard = true].get(0).id; 
        system.debug('contructo idlista:'+idLista);
        If(idLista==null || idLista==''){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Pricelist invalid'));
             // return null;
        }
        
        createNewContact= false;
         
        // Cantidad de registros totales para el paginador
        //totalRecs=[select count() from QuoteLineItem where quoteId = :idQuote];
        totalRecs=[select count() from PricebookEntry where Pricebook2Id = :idLista and isActive=true and Product2.isActive = true];
        soql = 'select Product2id, Product2.name, UnitPrice,Product2.family,Product2.MI__c,Product2.density__c, Product2.ProductCode'+
                ' from PricebookEntry where Pricebook2Id = :idLista and isActive=true and Product2.isActive = true '
                // +' and Producto__c not in(SELECT Producto_2__c from QuoteLineItem where Oferta__c= :idQuote)' 
            ;
        system.debug(' constructor soql :'+soql +'-idLista:'+idLista);
        maxWrapperId = 0;
        
        // Inicializa cotización, en caso de modificar una existente se asignan campos.
        quoteToCreate = initiateQuote(ApexPages.currentPage().getParameters().get('QuoteId'));
                
    }

    public boolean isEditMode;
    
    // Inicializa cotización, en caso de enviarse un id de cotización significa que lsa VF está en modo de modificación para una quote existente y se asignan campos de la VF.
    public Quote initiateQuote (String quoteID){ 
        
        isEditMode = false;

        // inicialización básica
        
        newContacLast ='';
        quoteName   = 'Q - '+ acc.name + ' - '+ date.today().format();
        paymentTerm = acc.payment_term__c;
        postingDate = date.today();
        quoteCurrency = 'USD';
        commission ='0';
        AditionalEmails='';
        emailBody = 'Dear '+ acc.name + ', please find attached a copy of the quote. Thank you.';
        Quote q= new Quote();
        oldProducts   = new List<QuoteLineItem> ();
        if(String.IsNotBlank(accCode)){
            Consigneedefaul = acc.name;
            ConsigneedefaulId= acc.Id;
            Notifydefaul= acc.name;
        	NotifydefaulId= acc.Id;
        }
        
        // Si es una edición dado que se envió como parámetro una cotización
        if  (quoteID!= null && quoteID!=''){

            isEditMode = true;

            q = [ SELECT name, opportunityId, opportunity.Contact__c,opportunity.Contact__r.Email, payment_Term__c, incoterm__c , 
                        Place_of_delivery__c,Customer_Ref__c, Place_of_delivery__r.Name, ExpirationDate, DocDate__c,Pricebook2Id,currency__c, Commission__c, 
                        opportunity.Consignee__c, opportunity.Consignee__r.name, opportunity.Notify__c, opportunity.Notify__r.name FROM quote where id=:quoteID];
            
            
            opp = [SELECT id, contact__c from opportunity where id = :q.opportunityId];
            
            quoteName= 			q.name;
            CustomerRef=		q.Customer_Ref__c; //DARFCUSTOMER
            paymentTerm = 		q.payment_Term__c;
            incoterms= 			q.incoterm__c;
            deliveryPlace = 	q.Place_of_delivery__c;
            deliveryPlaceName = q.Place_of_delivery__r.Name;
            NotifyId =			q.opportunity.Notify__c;
            NotifyName =		q.opportunity.Notify__r.name;
            ConsigneeId =		q.opportunity.Consignee__c;
            ConsigneeName =		q.opportunity.Consignee__r.name;
            deliveryDate  = 	q.ExpirationDate;
            deliveryDateOld  = 	deliveryDate.year()+'-'+deliveryDate.month()+'-'+deliveryDate.day();
            postingDate = 		q.DocDate__c;
            postingDateOld = 	postingDate.year()+'-'+postingDate.month()+'-'+postingDate.day();
            quoteCurrency = 	q.currency__c;
            commission = 		(q.Commission__c ==null)? '0':String.Valueof(q.Commission__c);
            idLista  = 			(idLista==null || idLista=='')? q.Pricebook2Id:idLista ;
            contactoId = 		q.opportunity.Contact__c;
            contactoEmail = 	q.opportunity.Contact__r.Email;
            
            // obtener productos de la cotización y agregarlos al mapa de productos deleccionado o carrito
            initiateQuoteProducts(quoteID);
            
        }
        return q;
        
    }    
    
    // obtener productos de la cotización y agregarlos al mapa de productos deleccionado o carrito
    public void initiateQuoteProducts (String quoteID){ 
      
        
        
        for (quoteLineItem qi : [ SELECT id, PricebookEntryId, Product2id,List_price__c,Freight_value__c,Payment_term_percentage__c,
                                    Container_type__c,Quantity,Port_of_origin__c, UnitPrice FROM quoteLineItem WHERE quoteId= :quoteID])
        {
            PricebookEntry pbE = [select id, UnitPrice,product2.Name, product2.Density__c,product2.MI__c, product2.ProductCode  from PricebookEntry where id= :qi.PricebookEntryId ].get(0);
            ProductWrapper pwr = new ProductWrapper(pbE,qi.Container_type__c);
            
            oldProducts.add(qi);  
                
            pwr.productId = qi.Id;
            pwr.listPrice = qi.List_price__c;
            pwr.freigthValue =qi.Freight_value__c;
            pwr.pTermPercentage =qi.Payment_term_percentage__c;
            pwr.containerType =qi.Container_type__c;
            pwr.quantity = qi.quantity;
            pwr.originPort = qi.Port_of_origin__c;
            pwr.salesPrice = String.Valueof(qi.UnitPrice);
            
            maxWrapperId = maxWrapperId+1;
            pwr.wrapperId = maxWrapperId;
            
            selectedProductsCart.put(maxWrapperId,pwr);
            cantProdAdded= selectedProductsCart.size();
        }
         
    }
     
    
    //AI Método que devuelve la propiedad que contiene los productos resultado de la búsqueda
    public Map<id,ProductWrapper> getMapSearchedProducts()
    {
        resultProductMap.clear();
        system.debug('0 getProductos2 incoterms:'+incoterms + ' deliveryPlace:'+deliveryPlace);
        system.debug('1 getProductos2 soql :'+soql +'-'+'idLista:'+idLista);
        List<PricebookEntry > resultados = Database.query(soql + ' order by product2.name LIMIT 30  ' ) ;
        if (resultados.size() >0){
            for(PricebookEntry p:  resultados )    
            {
              ProductWrapper pwrapper =new ProductWrapper(p,containersOptionList.get(0).getValue());
              resultProductMap.put(p.id, pwrapper); 
              system.debug('3 getProductos2 resultProductMap:'+resultProductMap.size());
            }
        }else {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No results with criteria inserted.'));
           return null;
        }
        system.debug('4 getProductos2 resultProductMap:'+resultProductMap.size());
        return resultProductMap;
    }
     
    
    // Usado para asignar el valor de los campos del detalle de un producto seleccionado de la lista resultado de búsqueda
    public void assignProductDetailFields(){
    
        system.debug('Mapa:'+resultProductMap);
        system.debug('id:'+Apexpages.currentPage().getParameters().get('productId'));
        currentSelectedProduct= resultProductMap.get(Apexpages.currentPage().getParameters().get('productId'));
        system.debug('Mapa:'+currentSelectedProduct);
                
        
        if(currentSelectedProduct!=null){
            
            selectProdDescription = currentSelectedProduct.pb2.product2.Name+'/'+currentSelectedProduct.pb2.product2.ProductCode+'/'+currentSelectedProduct.pb2.product2.Density__c+'/'+currentSelectedProduct.pb2.product2.MI__c;
        }else{
            selectProdDescription = '';
        }
    }
    
    // AI agrega el producto seleccionado en la VF al mapa que contiene los productos agregados
    public PageReference addToCart()
    {   
        system.debug('addToCart currentSelectedProduct 1:'+currentSelectedProduct);
        system.debug('addToCart currentSelectedProduct.wrapperId:'+currentSelectedProduct.wrapperId);
        maxWrapperId = maxWrapperId+1;
        currentSelectedProduct.wrapperId= maxWrapperId;
        
        // la clave del mapa selectedProductsCart es un consecutivo
        selectedProductsCart.put(maxWrapperId, currentSelectedProduct);
        //mapSelectedProductsCart.put(maxWrapperId, currentSelectedProduct);
        cantProdAdded= selectedProductsCart.size();
        return null;
    }
   
   
    // Usado para asignar el valor de los campos de un producto agregado al carro con el fin de editarlo
    public void assignEditProductDetailFields(){
    
        system.debug('assignEditProductDetailFields Mapa:'+selectedProductsCart);
        system.debug('assignEditProductDetailFields id:'+Apexpages.currentPage().getParameters().get('productId'));
        currentSelectedProduct= selectedProductsCart.get(integer.valueOf(Apexpages.currentPage().getParameters().get('productId')));
        system.debug('assignEditProductDetailFields Mapa:'+selectedProductsCart);
                
        if(currentSelectedProduct!=null){
            selectProdDescription = currentSelectedProduct.pb2.product2.Name+'/'+currentSelectedProduct.pb2.product2.ProductCode+'/'+currentSelectedProduct.pb2.product2.Density__c+'/'+currentSelectedProduct.pb2.product2.MI__c;
        }else{
            selectProdDescription = '';
        }
    }
        
    // Devuelve el mapa con los productos agregados a carro de compras
    public map<integer, ProductWrapper> getMapAddedProd()
    {   
        return selectedProductsCart;
        
    }
         

    public integer prodIdToEdit {get; set;}
    
    // AI agrega el producto seleccionado en la VF al mapa que contiene los productos agregados
    public PageReference addEdition()
    {   
        system.debug('addEdition Produt ID to edit :'+Apexpages.currentPage().getParameters().get('prodIdToEdit'));
        system.debug('addEdition currentSelectedProduct:'+currentSelectedProduct);
        system.debug('addEdition currentSelectedProduct.wrapperId:'+currentSelectedProduct.wrapperId);
        prodIdToEdit=currentSelectedProduct.wrapperId; //integer.valueof(Apexpages.currentPage().getParameters().get('prodIdToEdit'));
        // la clave del mapa selectedProductsCart es un consecutivo
        selectedProductsCart.put(prodIdToEdit, currentSelectedProduct);
        
        system.debug('addEdition selectedProductsCart keys:'+selectedProductsCart.keyset());
        //mapSelectedProductsCart.put(maxWrapperId, currentSelectedProduct);
        cantProdAdded= selectedProductsCart.size(); 
        return null;
    }
        
    // AI agrega el producto seleccionado en la VF al mapa que contiene los productos agregados
    public PageReference removeFromCart()
    {   
        integer prodIdTodelete=integer.valueof(Apexpages.currentPage().getParameters().get('prodIdTodelete'));
        system.debug('removeFromCart 1 prodIdTodelete:'+prodIdTodelete);
        
        // la clave del mapa selectedProductsCart es un consecutivo
        selectedProductsCart.remove(prodIdTodelete);
        //mapSelectedProductsCart.remove(prodIdTodelete);
        cantProdAdded= selectedProductsCart.size();
        return null;
    }
        
    // AI Refresca los precios de los productos una vez seleccionado el tipo de contenedor.
    public PageReference refreshPrice(){
    
        assignQuoteValues();
        calculatePrice();
        return null;
    }
    
    
     // calcula el precio de lista y de venta del producto actualmente asignado en currentSelectedProduct.
    public void calculatePrice(){
        
            system.debug('0 calculatePrice paymentTerm param:'+Apexpages.currentPage().getParameters().get('paymentTerm')+ ' incoterms:'+incoterms + ' deliveryPlace:'+deliveryPlace+ ' paymentTerm:'+paymentTerm);
            
            //inicializa el porcentaje según el término de pago de la cotización.   
            Payment_term_pricelist__c[] ptp = getPaymentTermPercent(paymentTerm);
            
            If ( ptp.size() > 0 ){
                
                decPTermPercentage = ptp[0].Percentage__c;
                system.debug(' 1 calculatePrice P.Term percent:'+decPTermPercentage);
            
            }else{ 
            
                system.debug('Entra a error de payment term');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payment Term does not exist in "Payment terms % - pricelist" table. Contact T.O'));
            }

            If ( decPTermPercentage==null ){
                
                system.debug('Entra a error2 de payment term');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payment Term does not exist in "Payment terms % - pricelist" table. Contact T.O.'));
                
            }
            
            currentSelectedProduct.pTermPercentage = decPTermPercentage;
            
            system.debug('calculatePrice Product2:'+ currentSelectedProduct.pb2.Product2.Name+ ' container:'+currentSelectedProduct.containerType + ' originPort:'+currentSelectedProduct.originPort+ ' delivery:'+deliveryPlace);
            
            
            If( currentSelectedProduct.originPort == null || deliveryPlace == null ){
                
                system.debug('Entra a error2 de payment term');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Delivery place and port of origin are mandatories.'));
                
            }else{
                
                currentSelectedProduct.freigthValue     = getFreightValue(currentSelectedProduct.originPort, null, deliveryPlace,null, currentSelectedProduct.containerType);
                 
                system.debug('calculatePrice 2 freigthValue:'+ currentSelectedProduct.freigthvalue+ ' currentSelectedProduct.costoFOB:'+currentSelectedProduct.costoFOB + ' currentSelectedProduct.pTermPercentage:'+currentSelectedProduct.pTermPercentage); 
                currentSelectedProduct.listPrice  = (currentSelectedProduct.freigthValue == null)? null: ((currentSelectedProduct.costoFOB +currentSelectedProduct.freigthValue ) * (1+ (currentSelectedProduct.pTermPercentage/100)) ).setScale(2, RoundingMode.HALF_UP); 
               //DARF currentSelectedProduct.salesPrice = String.valueOf(currentSelectedProduct.listPrice);
                
                system.debug('calculatePrice 2 freight value:'+ currentSelectedProduct.freigthvalue); 
                
                if( currentSelectedProduct.listPrice < 0 ){
                    
                    currentSelectedProduct.listPrice=0;
                    currentSelectedProduct.salesPrice = String.valueOf(0);
                    
                }
                
            }

        system.debug('refreshPrice inicial selectedProducts2:'+currentSelectedProduct);
        
    }
    
    // AI Refresca los precios de los productos una vez seleccionado el tipo de contenedor.
    public PageReference recalculateSalesPrices(){
        
        
        for ( integer k: selectedProductsCart.KeySet()){
            
            ProductWrapper tmpProd =  selectedProductsCart.get(k);
            
            currentSelectedProduct = selectedProductsCart.get(k);
            
            system.debug('recalculateSalesPrices salesprice antes :'+currentSelectedProduct.salesPrice);
            
            calculatePrice();
            
            system.debug('recalculateSalesPrices salesprice despues:'+currentSelectedProduct.salesPrice);
            
            // colocar producto modificado en el mapa deproductos agregados al carrito
            selectedProductsCart.put(k, currentSelectedProduct);
            
            
        }
        
      
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
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Port of Origin, Delivery port and container type are not set in Freights table.Contact T.O.'));
               
            return null;
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

    
       
    @RemoteAction
    public static List<Port__c> queryPorts(String keyword) {
        List<Port__c> portList = new List<Port__c>();
        if (keyword != null && keyword.trim() != '') {
            keyword = '%' + keyword + '%';
            portList = [select id, name, Code__c, Country__c, Origin__c, Place_of_delivery__c from port__c where is_active__c= true and name like :keyword order by name];
        }
        return portList;
    }
    
    @RemoteAction
    public static List<Account> queryAccounts(String keyword) {
        List<Account> accountList = new List<Account>();
        if (keyword != null && keyword.trim() != '') {
            keyword = '%' + keyword + '%';
            accountList = [select id, name from account where Account_code__c!= '' and name like :keyword order by name limit 100];
        }
        return accountList;
    }
    
    // AI Método que guarda los elementos que han sido seleccionados.
    public Contact assignContactToInsert(){
        
        Contact c;
        system.debug('assignContactToInsert quoteName:'+quoteName);
        
        system.debug('assignContactToInsert:'+createNewContact+ ' contactoID:'+contactoID + '-contact name:'+newContactName+ '-contact lastName:'+newContacLast+ '-Email:'+newContacEmail);
        if(createNewContact){
            c = new contact (firstName=newContactName, lastName=newContacLast, email=newContacEmail, accountid = acc.id);
            insert c;
        }else {
            c= new contact();
            c = [select id, email, firstName, LastName from contact where id=:contactoID];
        }
        system.debug('assignContactToInsert 2 c:'+c);
        return c;   
    } 
    
    public String savedCorrectly {get;set;}
    
    
    // AI Método que guarda los elementos que han sido seleccionados.
    public PageReference guardar(){
        assignQuoteValues();
        Boolean existError = false;
        String errorMess = null;
        quoteProdToUpsert = new List<QuoteLineItem>();
        
        quoteProdToUpsert = new List<QuoteLineItem>(); 
                mapQuoteProdToUpsert = new Map<String,QuoteLineItem>();
                quoteProdToDelete = new List<QuoteLineItem>();
        
        try {
            contactToInsert= new contact();
            contactEmail = contactToInsert.email;
            
            system.debug('guardar0 antes deliveryPlace :'+deliveryPlace+' incoterms:'+incoterms+ ' deliveryDate:'+deliveryDate+ + ' postingDate:'+postingDate);
        
            system.debug('guardar 1 selectedProductsCart:'+ selectedProductsCart.size() );
            
            contactToInsert = assignContactToInsert();

            system.debug('guardar 1.1 contactToInsert:'+ contactToInsert);
            quoteToCreate.name = quoteName;
            quoteToCreate.Customer_Ref__c=CustomerRef;//DARFCUSTOMER
            system.debug('CustomerRef'+CustomerRef);//DARFCUSTOMER
            quoteToCreate.payment_Term__c = paymentTerm;
            quoteToCreate.incoterm__c = incoterms;
            quoteToCreate.Place_of_delivery__c = deliveryPlace;
            quoteToCreate.ExpirationDate = deliveryDate;
            quoteToCreate.DocDate__c = postingDate;
            quoteToCreate.currency__c = quoteCurrency;
            system.debug('custom==>'+quoteToCreate.Customer_Ref__c);
            system.debug('guardar 1.1.1 quoteToCreate.Commission__c:'+ quoteToCreate.Commission__c + ' commission:'+commission);
            quoteToCreate.Commission__c = decimal.valueof(commission.remove(','));
            

            system.debug('guardar 1.2 contactToInsert:'+ quoteToCreate);
            system.debug('guardar 1.3 quoteToCreate.id:'+ quoteToCreate.id);
            system.debug('guardar 1.4 isEditMode:'+ isEditMode);
            system.debug('guardar 1.4 NotifyId = '+ NotifyId + ' ConsigneeId ='+ ConsigneeId);
            // Si es creación de una nueva cotización
            if (quoteToCreate.id==null) {
				//AM 28-Nov-2019 se agregaron los campos Notify y Consignee
                opp = new opportunity();
                
                opp.name = 'O - '+ acc.name + ' - '+ date.today().format(); 
                opp.accountid = acc.id; 
                opp.StageName = 'Requirement';
                opp.closeDate = date.today() + 30; 
                opp.Contact__c= contactToInsert.id;
                // AM 28-Nov-2019 se agregaron nuevos campos 
                opp.Notify__c = (String.IsNotBlank(NotifyId))? NotifyId : NotifydefaulId;
                //if(String.IsNotBlank(NotifyId)) opp.Notify__c = NotifyId;
                opp.Consignee__c = (String.IsNotBlank(ConsigneeId))? ConsigneeId : ConsigneedefaulId;
                //if(String.IsNotBlank(ConsigneeId)) opp.Consignee__c = ConsigneeId;
                insert opp;

                system.debug('guardar 2. opp:'+ opp );
                                        
                quoteToCreate.opportunityId = opp.id;
                quoteToCreate.Pricebook2Id = idLista;                   
                insert quoteToCreate;
                
                system.debug('guardar 2. quoteToCreate:'+ quoteToCreate );
                
                opp.SyncedQuoteId = quoteToCreate.id;
                update opp;

            }else {

               	opp.Contact__c = contactToInsert.id;
                // AM 28-Nov-2019 se agregaron nuevos campos 
               /* if(String.IsNotBlank(NotifyId)) opp.Notify__c = NotifyId;
                if(String.IsNotBlank(ConsigneeId)) opp.Consignee__c = ConsigneeId;*/
                opp.Notify__c = (String.IsNotBlank(NotifyId))? NotifyId : NotifydefaulId;
                opp.Consignee__c = (String.IsNotBlank(ConsigneeId))? ConsigneeId : ConsigneedefaulId;
				update opp;
                system.debug('guardar 2.1 quoteToCreate.Pricebook2Id:'+ quoteToCreate.Pricebook2Id + ' idLista:'+idLista );
                system.debug('guardar 2.1 quoteToCreate:'+ quoteToCreate );
                quoteToCreate.Pricebook2Id = (quoteToCreate.Pricebook2Id==null)? idLista:quoteToCreate.Pricebook2Id ;
               system.debug('guardar 2.2 quoteToCreate.Pricebook2Id:' + quoteToCreate.id);
                 update quoteToCreate;
                system.debug('guardar 2.3 quoteToCreate.Pricebook2Id:');
                
            }

            for (ProductWrapper p: selectedProductsCart.values() ){
                        
                    QuoteLineItem quotProdTmp  = new QuoteLineItem ();
                    quotProdTmp.QuoteId        = quoteToCreate.id;
                    quotProdTmp.Product2       = p.pb2.Product2;
                    system.debug('guardar unitPrice sin coma'+ p);
                    decimal salePrice= decimal.valueof(p.salesPrice.remove(','));
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
                    
                    // si tiene un id es porque es un producto existente en una cotización guardada anteriormente
                    if(p.productId!= null){
                        
                        quotProdTmp.id= p.productId;
                        mapQuoteProdToUpsert.put(String.valueOf(p.productId),quotProdTmp);
                        
                    }
                    
                    system.debug('guardar 2.4 port:' +p.originPort);
                    system.debug('guardar 2.5 product id:' +p.productId);
                    quoteProdToUpsert.add(quotProdTmp);
            }
             
                        // obtener productos que existían antes que ahora han sido eliminado del carro de compras.
                        for ( QuoteLineItem p:  oldProducts)
                        {
                if( !mapQuoteProdToUpsert.containsKey(p.id) ){
                    
                    quoteProdToDelete.add(p);
                    
                }
                                
                        }
            system.debug('guardar 3:'+quoteProdToUpsert);
            upsert quoteProdToUpsert;
            
            delete quoteProdToDelete;
            
            savedCorrectly='Ok';
            
            PageReference oPageRef;
            
            system.debug('guardar 4 saveNoClose:'+saveNoClose);
            if ( saveNoClose =='noCerrar' ){
                
                oPageRef= null;
                contactEmail = contactToInsert.email;
                
            }else {
                
                oPageRef = new PageReference('/'+quoteToCreate.id); 
                system.debug('guardar 5:'+quoteToCreate.id + ' URL:'+ oPageRef.getUrl());
                oPageRef.setRedirect(false); //indicate that the redirect should be performed on the client side
            }
            system.debug('guardar 5.1 oPageRef:'+oPageRef);
            
            return oPageRef;
            
              
         } catch (Exception e) {
              system.debug('guardar 6:'+e );
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'General Exception: '+ e + ' -cause:'+e.getCause()+' -msg:'+e.getMessage() + ' Line number:'+e.getLineNumber()));
              return null;
          }
    }
    
    // Guarda la cotización pero no se redirecciona a la página de la cotización creada/modificada
    public PageReference guardarNoCerrar (){
        PageReference oPageRef = guardar();
        contactEmail = contactToInsert.email;
        return null;    
    }
    
     // Guarda y envía el PDF generado  
    public PageReference guardarEnviar(){
       return null;
    }
    
    // Método que sólo envía el PDF y lo adjunta a la cotización creada/modificada
    public PageReference enviarPDF(){
        
        if(quoteCurrency== 'USD'){
            templateID = USD_Template_Setting__c.getOrgDefaults().Template_Id__c; 
        }else{
            templateID = Foreign_currency_template__c.getOrgDefaults().Template_Id__c;
        }
        
        system.debug('guardarEnviar 1:'+quoteToCreate.id );
        system.debug('guardarEnviar 2 attachedQuotePDF:'+attachedQuotePDF );
        system.debug('guardarEnviar 3 contactToInsert.email:'+contactToInsert.email + ' contactEmail:'+contactEmail);
        system.debug('guardarEnviar 4 AditionalEmails:'+AditionalEmails );
        system.debug('guardarEnviar 5 emailBody:'+emailBody );
    
        PageReference oPageRef = new PageReference('/'+quoteToCreate.id);

        try{            
                 
                // Genenare PDF and attach to created quote.
                attachedQuotePDF= SaveSendQuotePDF.createQuoteTemplate (quoteToCreate.Id, templateID);
                
                oPageRef = new PageReference('/'+quoteToCreate.id); 
                system.debug('guardarEnviar 4:'+quoteToCreate.id);
                oPageRef.setRedirect(false); //indicate that the redirect should be performed on the client side
                
                SaveSendQuotePDF.sendTemplate (attachedQuotePDF,contactEmail,AditionalEmails, emailBody);
                return oPageRef;  

                            
        }catch(System.EmailException e){
                system.debug('Exception sending message:'+e.getMessage() );
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() ));
                return null;
        }  

        
    }
       
    
    // AI método ejecutado cada vez que se acciona algún campo de búsqueda
    public PageReference runSearch() {
    
        String nombProd= Apexpages.currentPage().getParameters().get('productName');
        system.debug('1 runSearch nombProd:'+nombProd);
               
        soql = 'select Product2id, Product2.name, UnitPrice,Product2.family,Product2.MI__c,Product2.density__c,Product2.ProductCode'+
                ' from PricebookEntry where Pricebook2Id = :idLista and isActive=true and Product2.isActive = true  '
                // +' and Producto__c not in(SELECT Producto_2__c from QuoteLineItem where Oferta__c= :idQuote)' 
            ;
                //Lista_de_precios__c <> null ';
                 system.debug('1.1 runSearch soql :'+soql );
        if (!nombProd.equals('')){
              soql += ' and (Product2.name LIKE \'%'+String.escapeSingleQuotes(nombProd)+'%\' or Product2.productCode LIKE \'%'+String.escapeSingleQuotes(nombProd)+'%\')';
                 system.debug('2 runSearch nombProd no vacio:'+nombProd+'-');
                 }


        system.debug('6 runSearch soql :'+soql );
        return null;
    }
    
     // returns the PageReference of the original page, if known, or the home page.
     public PageReference cancel() {

            PageReference oPageRef = new PageReference('/'+acc.id); 
            system.debug('guardar 4:'+acc.id + ' URL:'+ oPageRef.getUrl());
            oPageRef.setRedirect(false); //indicate that the redirect should be performed on the client side
            return oPageRef;
     }
     
        
    // Obtener puertos de origen
    public List<SelectOption> getOriginPortsList()
    {
        List<SelectOption> ports= new List<SelectOption>();
        ports.add(new selectoption ('', '--Select--') );
        for(port__c p:[select id, name, Code__c, Country__c, Origin__c, Place_of_delivery__c from port__c where is_active__c= true and Origin__c= true order by name]){
            ports.add(new selectoption (p.id, p.name));
        }
        return ports;
    }
    
    // AI Obtener contactos de la cuenta
    public List<SelectOption> getContactList(id accId)
    {
        List<SelectOption> c= new List<SelectOption>();
        //c.add(new selectoption ('', '--Select--') );
        for(contact con:[SELECT Id, Name, Main_Contact__c FROM contact where accountid= :accId order by Main_Contact__c desc]){
            c.add(new selectoption (con.id, con.name));
        }
        return c;
    }
    
        
    // Usado para garantizar que se asignan los valores de la cotización ingresados en la visualforce
    public void assignQuoteValues(){
    
        system.debug('asignQuoteValues deliveryPlace antes:'+deliveryPlace);
        system.debug('asignQuoteValues deliveryDate antes:'+deliveryDate);
        system.debug('asignQuoteValues postingDate antes:'+postingDate);
        system.debug('asignQuoteValues incoterms antes:'+incoterms);
        system.debug('asignQuoteValues commission antes:'+commission);
        system.debug('asignQuoteValues newContacLast antes:'+newContacLast);
        system.debug('asignQuoteValues NotifyId antes:'+NotifyId);
        system.debug('asignQuoteValues ConsigneeId antes:'+ConsigneeId);
        system.debug('asignQuoteValues CustomerRef :'+CustomerRef);
        
        CustomerRef=  (Apexpages.currentPage().getParameters().get('CustomerRef'));//DARFCUSTOMER
        system.debug('asignQuoteValues CustomerRef POS:'+CustomerRef);//DARFCUSTOMER
        paymentTerm=  (Apexpages.currentPage().getParameters().get('paymentTerm'));
        incoterms=    (Apexpages.currentPage().getParameters().get('incoterms'));
        NotifyId=     (Apexpages.currentPage().getParameters().get('NotifyId'));
        ConsigneeId=  (Apexpages.currentPage().getParameters().get('ConsigneeId'));
        system.debug('@@@ asignQuoteValues ConsigneeId despues:'+(Apexpages.currentPage().getParameters().get('ConsigneeId')));
        deliveryDate= setStringToDateFormat(Apexpages.currentPage().getParameters().get('deliveryDate'));
        
        system.debug('asignQuoteValues deliveryDate:'+deliveryDate);
        deliveryPlace= (Apexpages.currentPage().getParameters().get('deliveryPlace'));
        system.debug('asignQuoteValues deliveryPlace:'+deliveryPlace);
        postingDate=  setStringToDateFormat(Apexpages.currentPage().getParameters().get('postingDate'));
        contactoID= (Apexpages.currentPage().getParameters().get('contact'));
        //commission= (Apexpages.currentPage().getParameters().get('Commission'));
        system.debug('asignQuoteValues commission:'+commission);
        system.debug('asignQuoteValues newContacLast:'+newContacLast);
                
        system.debug('asignQuoteValues contactoID:'+contactoID);
        
    }
    
    // transforma un string con formato 'yyyy-mm-dd' en fecha
    private Date setStringToDateFormat(String myDate) {
        
        Date d;
        if (myDate != null && myDate != ''){
                    
            String[] myDateOnly = myDate.split(' ');
            String[] strDate = myDateOnly[0].split('-');
            system.debug('setStringToDateFormat strDate:'+strDate);
            Integer myIntDate = integer.valueOf(strDate[2]);
            Integer myIntMonth = integer.valueOf(strDate[1]);
            Integer myIntYear = integer.valueOf(strDate[0]);
            d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
        }
        
        return d;
        
    }
    
    public void spin() {
        long now = datetime.now().gettime();
        while(datetime.now().gettime()-now<5000); // Busy loop for 5000 ms

    }
    
       public class ProductWrapper
    {
        public Id productId {get; set;}
        public integer wrapperId {get; set;}
        
        public PricebookEntry pb2{get; set;}
        public Boolean selected {get; set;}
        public decimal costoFOB{get; set;}
        public decimal freigthValue{get; set;}
        public decimal pTermPercentage{get; set;}
        
        // Precio FOB mas fletes (freights) y % de termino de pago
        public decimal listPrice{get; set;}
        
        public String salesPrice {get; set;}
        public decimal quantity {get; set;} // cantidad ingresada por el usuario
        
        public String mensajeError{get; set;}
        public id listID {get; set;}
        
        public String containerType {get;set;}
        public id originPort  {get;set;}
        
        public ProductWrapper(PricebookEntry a,String container)
        {   
            wrapperId= 0;
            pb2 = a;
            selected    = false;
            quantity = 0;
//          mensajeError='Error'; 
            costoFOB= a.UnitPrice; 
                        
            // Se agrega por defecto el primer valor encontrado en la lista.
            containerType=container;
        }
        
        
        
    }
    
}