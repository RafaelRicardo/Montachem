/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro iquira
 Proyecto:         MONTACHEM
 Descripción:      clase usada por el controlador de la VF createQuickQuote_pag. Tiene métodos que permiten el envío de la cotización por medio de correo electrónico
 Clase de prueba:  createQuickQuote_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  07-07-2019 Alejandro iquira         Creación
****************************************************************************************/
public class SaveSendQuotePDF {

        
    public static QuoteDocument createQuoteTemplate (id quoteID, id templateID){
        
         
         system.debug('createQuoteTemplate 0:'+QuoteID);    
         
        //This Url create the pdf for quote
        String quoteUrl = '/quote/quoteTemplateDataViewer.apexp?id=';
         
        system.debug('createQuoteTemplate 1');    
        quoteUrl +=QuoteID;
         
        system.debug('createQuoteTemplate 2');    
        quoteUrl +='&headerHeight=190&footerHeight=188&summlid=';
         
        system.debug('createQuoteTemplate 3');    
        quoteUrl +=templateID ;
         
        system.debug('createQuoteTemplate 4');    
        quoteUrl +='#toolbar=1&navpanes=0&zoom=90';
         
        system.debug('createQuoteTemplate 5 quoteUrl:'+quoteUrl);    
        //Create pdf content
        PageReference pg = new PageReference(quoteUrl) ;
         
        system.debug('createQuoteTemplate 7:'+pg);    
        //Document object of quote which hold the quote pdf
        QuoteDocument quotedoc = new QuoteDocument(); 
         
        system.debug('createQuoteTemplate 8:'+pg);    
        
        //Get the content of Pdf.
        Blob b;
        if(Test.isRunningTest()) {
            b = blob.valueOf('Unit.Test');
        } else {
            b = pg.getContentAsPDF();
        }
         
        system.debug('createQuoteTemplate 9:'+b);    
        //content assign to document
        quotedoc.Document = b;
         
        system.debug('createQuoteTemplate 10');    
        //assign quote id where pdf should attach
        quotedoc.QuoteId = QuoteID ;
        system.debug('createQuoteTemplate 11:'+QuoteID);
        
        insert quotedoc; 
        system.debug('createQuoteTemplate 12');    
        return quotedoc;
        
    }
    
    
        
    public static void sendTemplate (QuoteDocument att,String ContactoEmail,String AditionalEmail, String message){
        
        
        
         system.debug('sendTemplate 1 ContactoEmail:'+ContactoEmail+' AditionalEmail:'+AditionalEmail);
           List<String> EmailIds = new List<String>();
           EmailIds.add(ContactoEmail);
        if( AditionalEmail.length() > 0 ){
            
            
            String[] arrayAditionalEmail = AditionalEmail.split(',');
            
         system.debug('sendTemplate 2 arrayAditionalEmail:'+arrayAditionalEmail);
            
            for ( string e : arrayAditionalEmail){
                
                
         			system.debug('sendTemplate 2.1 e:'+e);
              		EmailIds.add(e);         
                	system.debug('sendTemplateEmailIds:'+EmailIds);
                
            }
        }
             
           Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
           Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
         system.debug('sendTemplate 5');
           efa1.setFileName('Quote.pdf');
           efa1.setBody(att.document);
           String addresses;
           email.setSubject( 'Montachem - Quote PDF' + String.valueOf(DateTime.now()));
           email.setToAddresses( EmailIds  );
           email.setPlainTextBody(message);
           email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa1});
           if(!Test.isRunningTest())Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        
		        
    }        
    
}