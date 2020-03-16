/***************************************************************************************************************
* Vass 
* author           Wiliam Dorado
* Proyecto:         Montachem
* Description:      Clase generadora de datos para las clases de pruebas
****************************************************************************************************************/

public  class DataGenerator_cls
{
    
    public static Account createAccount(Boolean blnInsert, String accountCode)
    {
        
        Account a = new Account();
        a.Name = 'Test';
        a.Account_code__c =accountCode;
        a.Status__c = 'Active';
        a.Credit_status__c='Pending information';
        location__c region = createLocation(true, 'LATAM', 'LATAM', null, 'Region', null);
        location__c subregion = createLocation(true, 'SOUTH AMERICA', 'SOUTH AMERICA', null, 'Region', region.Id);
        location__c country = createLocation(true, 'COLOMBIA', 'CO', 'COL', 'country', subregion.id);
        a.country__c = country.id;
        a.Address_Line_1_Bill_1__c='Linea 1';
        a.Bill_main_Country__c =country.id;
        a.BillingCity ='ciudad';
        a.Zip_code_Bill_1__c='20080';
        
        //	integer consec = [select max(Consecutive__c) from account where account_code__c = 'nuk'];
        // 	a.Consecutive__c = (consec==null || consec =='')? 0: consec+1;
        a.Consecutive__c = 3;
        if(blnInsert)insert a;
        
        return a;
        
        
    }
    
    public static Opportunity createOportunity(String AccountId, Id pricebookId, Boolean blnInsert)
    {
        Opportunity o = new Opportunity();
        o.name='Test1';
        o.AccountId=AccountId;
        o.CloseDate=system.today();
        o.StageName='Requirment';
        o.Pricebook2Id = pricebookId;
        
        if(blnInsert) insert o; 
        
        system.debug('oppo:'+o); 
        return o;  
    }
    
    public static Contact createContact(String lName, String fName, String emailAdd, Boolean blnInsert)
    {
        Contact c = new Contact();
        c.firstName = fName;
        c.LastName = lName;
        c.Email = emailAdd;
        
        if(blnInsert) insert c; 
        
        return c;
    }
    
    public static Quote createQuote(id opp, id pricebookId, String status, id port, String pTerm, String incoterm, String curr, Boolean blnInsert)
    {
        Quote q = new Quote();
        q.name='Quote1';
        q.OpportunityId=opp;
        q.expirationDate=system.today().addDays(5);
        q.DocDate__c=system.today();
        q.status=status;
        q.Place_of_delivery__c=port;
        q.Payment_Term__c=pTerm;
        q.incoterm__c=incoterm;
        q.currency__c=curr;
        q.Pricebook2Id = pricebookId;
        
        if(blnInsert) insert q; 
        
        system.debug('oppo:'+q); 
        return q;  
    }
    
    
    public static QuoteLineItem createQuoteProducts(id quoteId, id product2, id priceb2,decimal pterm, id port, Boolean blnInsert)
    {
        
        system.debug('createQuoteProducts:'+priceb2);
        QuoteLineItem q = new QuoteLineItem();
        q.QuoteId = quoteId;
        q.Payment_term_percentage__c = pterm;
        q.Port_of_origin__c = port;
        q.Container_type__c = '20';
        q.Quantity = 2000;
        q.UnitPrice = 3000;
        q.PricebookEntryId = priceb2;
        q.product2id = product2;
        q.List_price__c = pTerm;
        q.Freight_value__c = 300;
        
        if(blnInsert) insert q; 
        
        return q;  
    }
    
    public static Order__c createOrder(String AccountId,id OppId,Boolean blnInsert)
    {
        Order__c o = new Order__c();
        o.name='Test1';
        o.Account__c=AccountId;
        o.Opportunity__c=OppId;
        o.Status__c='Closed';
        o.SAPDoc_Num__c='123';
        o.SAP_Order_ID__c='12345';
        o.Remarks__c='nueva descripcion'; 
        if(blnInsert) insert o;
        return o;  
    }
    
    
    public static Order__c createOrderCust(String AccountId,String Opportunityid,Boolean blnInsert)
    {
        Order__c o = new Order__c();
        o.name='Test1';
        o.Account__c=AccountId;
        o.Opportunity__c=Opportunityid;
        o.Status__c='Open';
        o.SAP_order_ID__c='123';
        
        if(blnInsert) insert o;
        return o;  
    }
    
    public static Order_Product__c createOrderItemCust(String OrderId,String ProductId,Boolean blnInsert)
    {
        
        
        Order_Product__c oi = new Order_Product__c();
        oi.Order__c=OrderId;
        oi.Quantity__c=decimal.valueof('1');
        oi.Product__c=ProductId;
        oi.Sales_price__c=12;
        
        if(blnInsert) insert oi;
        return oi;
        
    }
    
    
    public static Product2 createProduct(id pricebookId, Boolean blnInsert)
    {
        
        Product2 prod = new Product2();
        prod.Name = 'LDPE-DR530G-SM';
        prod.Family = 'Hardware';
        prod.productCode= 'LDPE-DR530G-SM';
        prod.isActive = true;
        
        if(blnInsert)insert prod;
        
        return prod;  
    }
    
    public static Location__c createLocation(Boolean blnInsert, String locName, String preFix, String code, String locType, String locParent)
    {
        
        Location__c objLoc=new Location__c();
        objLoc.Accoun_prefix_code__c=preFix;
        objLoc.Code__c=code;
        objLoc.Name=locName;
        objLoc.parent_location__c=locParent;
        objLoc.Type__c=locType;
        
        if(blnInsert) insert objLoc;
        
        return objLoc;
        
    }
    
    
    public static Port__c createPort(Boolean blnInsert, String country, String code)
    {
        
        Port__c objPort=new Port__c();
        objPort.Country__c=country;
        objPort.Code__c=code;
        objPort.Name=code;
        objPort.Place_of_delivery__c=true;
        objPort.origin__c=true;
        
        if(blnInsert) insert objPort;
        
        return objPort;
        
    }
    
    
    public static Payment_term_pricelist__c createPTermPercent(String pT, Boolean blnInsert) 
    {
        
        Payment_term_pricelist__c pTerm=new Payment_term_pricelist__c();
        pTerm.Payment_term__c=pT;
        pTerm.Percentage__c=10.1;
        
        if(blnInsert) insert pTerm;
        
        return pTerm;
        
    }
    
    
    public static Freight__c createFreight(id PortOri, id PortDelivery,Boolean blnInsert)
    {
        
        Freight__c f=new Freight__c();
        f.Container_type__c='20';
        f.Origin__c=PortOri;
        f.Place_of_delivery__c=PortDelivery;
        f.Value__c=4000;
        
        if(blnInsert) insert f;
        
        return f;
        
    }
    
}