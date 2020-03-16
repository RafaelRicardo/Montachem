/*************************************************************************************/
/* Desarrollado por: VASS 
/* Autor:            Alejandro Iquira
/* Proyecto:         MONTACHEM
/* Descripción:      Clase manejadora del trigger order_tgr. También tiene m[etodos utilitarios relacionados a la orden 
/* Clase de prueba:  Order_tgr_tst
/* Cambios (Versiones) 
/* ----------------------------------------------------------------------------------- 
/* No.  Fecha       Autor                   Descripción 
/* ---- ----------- ----------------------- ------------------------------------------
/* 1.0  09-Sep-2019 Alejandro Iquira        
/*                                 
/*************************************************************************************/ 
public class Order_hdl {
 
    // Método que invoca el envio del pdf al propietario de la oportunidad relacionada a la orden
    public static void sendOrderToOwner(list<order__c> lstOrder){
        
        Id recordId = lstOrder.get(0).id;
        
        id opp = lstOrder.get(0).opportunity__c;
        String ownerEmail = [select owner.email from opportunity where id = :opp].get(0).owner.email;
        
        Order_hdl.sendOrderSavePdf(recordId,OwnerEmail,'',true, false, lstOrder.get(0).Name, true);
        
    }
    
    // Método que guarda PDF y envía al correo enviado como parámetro 
    @future(callout=true)
    public static void sendOrderSavePdf(String OrdenId,String ContactoEmail,String AditionalEmail,Boolean bolEnviarEmail, Boolean bolSaveAttach,String orderName, Boolean isNewORder)
    {
        PageReference ref = Page.OrderPdf_pag;
        ref.getParameters().put('id',OrdenId);
        Blob b=null;
        
        List<order__c> o =[select account__r.name from order__c where id=:OrdenId];
        
        String accName = (o.size() >0)? o.get(0).account__r.name:'';
        
        // custom setting with configuration of email for order pdf
        Order_email__c emailConf = Order_email__c.getOrgDefaults();
        
        if(!Test.isRunningTest())b = ref.getContentAsPDF();
     
       	//crea el archivo adjunto
        Attachment attach1= new Attachment();
        attach1.ParentId = OrdenId;
        attach1.Name = (orderName == null || orderName =='')? emailConf.attachmentName__c+'.pdf': emailConf.attachmentName__c+' '+orderName+'.pdf';
        attach1.Body = b;
        
        // Si se desea guardar el pdf como adjunto al registro
        if(!Test.isRunningTest() && bolSaveAttach)insert attach1;
        
        //si debe enviar por correo el Pdf
        if(bolEnviarEmail)
        {
            List<String> EmailIds = new List<String>();
            EmailIds.add(ContactoEmail);
            if(AditionalEmail.length()>0)
                EmailIds.add(AditionalEmail);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
            efa1.setFileName(attach1.Name);
            efa1.setBody(b);
            String addresses;
            email.setSubject( emailConf.email_subject__c+' '+ orderName +' PDF' + String.valueOf(DateTime.now()));
            email.setToAddresses( EmailIds  );
            
            //Set email body
            if(isNewOrder)
            {
            	email.setPlainTextBody(emailConf.NewBody_prefix__c+' '+orderName+' '+emailConf.NewBody_sufix__c+' Client:'+ accName);
            }else{
            	email.setPlainTextBody(emailConf.Body_prefix__c+' '+orderName+' '+emailConf.Body_sufix__c);
            }
            
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa1});
            if(!Test.isRunningTest())Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }
    
}