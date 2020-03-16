/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            William Dorado
/* Proyecto:         MONTACHEM
/* Descripción:      Clase controladora para la pagina orden pdf
/* Clase de prueba:  Account_tst

/* Cambios (Versiones)  
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  09-Oct-2018 William Dorado          Controlador de pagina
/*                                          

/*************************************************************************************/
public class OrderPdf_ctr 
{
   
    public StaticData objDatosEstaticos{get;set;}
    public List<Order_Product__c> lstProductos{get;set;}
    public String strCurrency{get;set;}
    public Decimal Total{get;set;}
    public List<Organization> lstOrg{get;set;}
    public List<Order__c>     lstOrden{get;set;}
    public List<Opportunity>  lstOp{get;set;}
    public date   creationDate{get;set;}
    public String incoterms{get;set;}
    public String paymentTerm{get;set;}
    public Opportunity objOportunidad {get;set;}
    public Account  objAccount{get;set;}
    /******************************************************************************************
constructor
*******************************************************************************************/
    
    public OrderPdf_ctr() 
    {   decimal d=5.0;
        object o = d;
        // Obtener valores del picklist de Payment term
        Schema.DescribeFieldResult fR1    = Order__c.Payment_Term__c.getDescribe();
        List<Schema.PicklistEntry> values = fR1.getPicklistValues();
        
        Map<String,String> MapLabelPayment = new Map<String,String>();
        
        for( Schema.PicklistEntry v : values) {
            MapLabelPayment.put(v.getValue(),v.getLabel());        
        }
        
        
        // Obtener valores del picklist de Incoterms 
        fR1    = Order__c.Incoterm__c.getDescribe();
        values = fR1.getPicklistValues();
        
        Map<String,String> MapLabelIncoterms = new Map<String,String>();
        
        for( Schema.PicklistEntry v : values) {
            MapLabelIncoterms.put(v.getValue(),v.getLabel());        
        }
        
        system.debug('OrderPdf_ctr');
        objDatosEstaticos=new StaticData();
        
        lstOrg  =[SELECT City,Country,Fax,Name,Phone,street, state, postalcode FROM Organization];
        lstOrden=[SELECT Place_of_delivery__c,Place_of_delivery__r.name,Place_of_delivery__r.Country__r.Name,Opportunity__c ,Id,SAPDoc_Num__c,DocDate__c,Payment_Term__c,Incoterm__c,Order_total_value_in_words__c,
                  Delivery_Date__c,Account__r.Federal_tax_ID__c,Remarks__c, Customer_Ref__c,Shipment_Date__c, Creation_date__c, Creationdate__c  FROM Order__c  WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        
        lstOp   = [select Owner.name,id,Contact__r.name,Bill_main_Address_Line_1__c,Bill_main_Address_Line_2__c,Bill_main_City__c,Bill_main_Country__c,
                          Ship_mail_Address_Line_2__c, Ship_main_Address_Line_1__c, Ship_main_City__c, Ship_main_Country__c, Ship_main_Zip_code__c, SyncedQuote.Currency__c,
                          Consignee__r.Address_Line_1_Bill_1__c, Consignee__r.Address_Line_2_Bill_1__c, Consignee__r.City_Bill_1__c, 
                          Consignee__r.Bill_main_Country__r.Name, Consignee__r.Zip_code_Bill_1__c,Consignee__r.Name, Consignee__r.Federal_tax_ID__c, account.Commission_representative__r.name 
                   from Opportunity where id=:lstOrden[0].Opportunity__c];
        List<Account>  lstCuenta= [select id,name,Country__c, country__r.Name, country__r.code__c  from account where id=:lstOrden[0].Account__c];
        
        if ( lstCuenta.size()>0)
        {
            objAccount = lstCuenta.get(0);
        }
        
        lstProductos=[select id,Quantity__c,Product__r.Description,FORMAT(Sales_price__c),Order__c,FORMAT(Total_sales_price__c),Density__c,Melt_Index__c, 
                      Product__r.name, Product__r.ProductCode, Product__r.Brand__c, Product__r.Notes__c, Product__r.Product__c, 
                      Product__r.Reference__c,Product__r.Remarks__c,Product__r.Suggested_applications__c, Product__r.Supplier__c, Product__r.Family,
                      Order__r.opportunity__r.SyncedQuote.Currency__c
                      from Order_Product__c where Order__c=:lstOrden[0].id];
        strCurrency = lstProductos[0].Order__r.opportunity__r.SyncedQuote.Currency__c;
        Total=0;
        
        for(Integer i=0;i<lstProductos.size();i++)
            Total =Total+lstProductos[i].Total_sales_price__c;
        
        
        system.debug('7'+total);
        
        //datos de la organizacion
        if(lstOrg.size()>0)
        {
            Organization objOrganizacion=lstOrg[0];
            objDatosEstaticos.NombreOrganizacion=objOrganizacion.name;
            objDatosEstaticos.TelefonoOrganizacion=objOrganizacion.Phone;
            objDatosEstaticos.FaxOrganizacion=objOrganizacion.Fax;
            objDatosEstaticos.DirOrganizacion='200 S Andrew Aveniu Font Laurdedale, FL 333021 USA';
        }
        
        system.debug('8');
        //datos de la cuenta
        if(lstCuenta.size()>0)
        {
            objDatosEstaticos.NombreCuenta=lstCuenta[0].name;
        }
        //datos de la orden
        if(lstOrden.size()>0)
        {
            Order__c objOrder=lstOrden[0];
            objDatosEstaticos.ProformaVoice=objOrder.SAPDoc_Num__c;
            objDatosEstaticos.Terms= ( MapLabelPayment.get(objOrder.Payment_Term__c)==null)? '':MapLabelPayment.get(objOrder.Payment_Term__c); 
            
            // Cambio solicitado corrección de Incotermm, Generación PDF.

            objDatosEstaticos.Icoterms = ( MapLabelIncoterms .get(objOrder.Incoterm__c)==null)? '':MapLabelIncoterms .get(objOrder.Incoterm__c);  
            
            if(objOrder.Place_of_delivery__c!=null)objDatosEstaticos.Icoterms=objDatosEstaticos.Icoterms+' '+objOrder.Place_of_delivery__r.name;
            
            // if(lstOp.size()>0)objDatosEstaticos.Icoterms=objDatosEstaticos.Icoterms+', '+ ((lstOp[0].Bill_main_Country__c==null)? '':lstOp[0].Bill_main_Country__c);
            
            if(objOrder.Place_of_delivery__c != null ) objDatosEstaticos.Icoterms = objDatosEstaticos.Icoterms + ', ' + objOrder.Place_of_delivery__r.Country__r.Name;

            objDatosEstaticos.CustomerRef    =objOrder.Customer_Ref__c;
            
            if(objOrder.Creation_date__c!=null){
                objDatosEstaticos.DateField=objOrder.Creation_date__c.month()+'/'+ objOrder.Creation_date__c.day()+'/'+ objOrder.Creation_date__c.year();
            }
            if(objOrder.Creationdate__c!=null){
                objDatosEstaticos.DateFieldWithOutTime=objOrder.Creationdate__c.month()+'/'+ objOrder.Creationdate__c.day()+'/'+ objOrder.Creationdate__c.year();
            }
            if(objOrder.Delivery_Date__c!=null){
                objDatosEstaticos.DeliveryDate=objOrder.Delivery_Date__c.month()+'/'+ objOrder.Delivery_Date__c.day()+'/'+ objOrder.Delivery_Date__c.year();
            }
            if(objOrder.Shipment_Date__c!=null){
                objDatosEstaticos.EstimatedTime=objOrder.Shipment_Date__c.month()+'/'+ objOrder.Shipment_Date__c.day()+'/'+ objOrder.Shipment_Date__c.year();
            }
            
            objDatosEstaticos.placeOfDelivery=objOrder.Place_of_delivery__r.name;    
            objDatosEstaticos.TaxId          =objOrder.Account__r.Federal_tax_ID__c;
        } 
        system.debug('10');
        //datos de la oportunidad
        if(lstOp.size()>0)
        {
            
            objOportunidad=lstOp[0];    
            objDatosEstaticos.NombreContacto=objOportunidad.Contact__r.name;
            String line2= (objOportunidad.Bill_main_Address_Line_2__c==null)? '':objOportunidad.Bill_main_Address_Line_2__c;
            objDatosEstaticos.DirecionCuenta=objOportunidad.Bill_main_Address_Line_1__c+' '+ line2;
            objDatosEstaticos.Ciudad=objOportunidad.Bill_main_City__c;
            objDatosEstaticos.Pais=objOportunidad.Bill_main_Country__c;
			//AM 28-Nov-2019 ajuste para mostrar el Commission_representative__r
            objDatosEstaticos.SalesRep= (String.IsnotBlank(objOportunidad.account.Commission_representative__r.name))? objOportunidad.account.Commission_representative__r.name: objOportunidad.Owner.name;
            
        }
        
        system.debug('11');
    }
    
    
    /******************************************************************************************
objetos que se usan para mostrar la informacion en el pdf
*******************************************************************************************/
    
    public class StaticData
    {
        //datos de la orgenizacion
        public String NombreOrganizacion{get;set;}
        public String TelefonoOrganizacion{get;set;}
        public String FaxOrganizacion{get;set;}
        public String DirOrganizacion{get;set;}
        //datos de la cuenta
        public String NombreCuenta{get;set;}
        public String NombreContacto{get;set;}
        public String DirecionCuenta{get;set;}
        public String Ciudad{get;set;}
        public String Pais{get;set;}
        //datos de la orden
        public String ProformaVoice{get;set;}
        public String DateField{get;set;}
        public String DateFieldWithOutTime{get;set;}
        public String SalesRep{get;set;}
        public String Terms{get;set;}
        public String Icoterms{get;set;}
        public String CustomerRef{get;set;}
        public String EstimatedTime{get;set;}
        public String deliveryDate{get;set;}
        public String placeOfDelivery{get;set;}
        public String TaxId{get;set;}
        
    }

}