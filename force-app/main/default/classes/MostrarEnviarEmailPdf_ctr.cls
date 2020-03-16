/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            William Dorado
/* Proyecto:         MONTACHEM
/* Descripción:      Clase controladora para la pagina que envia por correo o muestra un pdf
/* Clase de prueba:  MostrarEnviarEmailPdf_ctr_tst

/* Cambios (Versiones) 
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  09-Oct-2018 William Dorado          Controlador de pagina
/* 1.1  25-Sep-2019 Alejandro Iquira        Mejora en la clase, se pasa un método a una clase handler de la orden
/*                                          

/*************************************************************************************/ 

public class MostrarEnviarEmailPdf_ctr 
{
   public String  OrdenId;
   public String  orderName;
   public Boolean bolEnviarEmail{get;set;}
   public String  AditionalEmail{get;set;}
   public String  ContactoEmail{get;set;}
   public String  UrlPdf{get;set;}
   
   /******************************************************************************************
   constructor
   *******************************************************************************************/
   public MostrarEnviarEmailPdf_ctr()
   {
       List<Order__c> lstOrden   = [SELECT Name, Opportunity__r.Contact__c,Opportunity__r.Contact__r.Email,Id  FROM Order__c  WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
      
       if(lstOrden.size()>0)
       {
           OrdenId=lstOrden[0].id;
           orderName=lstOrden[0].name;
           UrlPdf='/apex/OrderPdf_pag?id='+OrdenId;
           if(lstOrden[0].Opportunity__r.Contact__c!=null&&lstOrden[0].Opportunity__r.Contact__r.Email!=null)
               ContactoEmail=lstOrden[0].Opportunity__r.Contact__r.Email;
       }
   }

  
   /******************************************************************************************
   Boton Volver
   *******************************************************************************************/
   public PageReference volver()
   {
   
       PageReference pageRef = new PageReference('/'+OrdenId);
       return pageRef;
   }
    
   /******************************************************************************************
   Guardar y/o Enviar un PDF  por Email
   *******************************************************************************************/
    
    public PageReference GuardarEnviarEmailPdf()
   {
       if(bolEnviarEmail&&(ContactoEmail==null||ContactoEmail.Trim().length()==0))
       {
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The contact Email is required'));
           return null;
       }
       
       try
       {
       Order_hdl.sendOrderSavePdf(OrdenId,ContactoEmail,AditionalEmail,bolEnviarEmail, true, orderName, false);
       ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Successful operation.'));
       }catch(exception ex)
       {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Successful operation.'));
       
       }
       return null;
   }   
  
}