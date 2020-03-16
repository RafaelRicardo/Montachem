/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro Iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase con métodos utilitarios para diferentes propósitos en el sistema
 Clase de prueba:  ApproveRejectQuote_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción
 ---- ----------- ----------------------- ------------------------------------------
 1.0  15-11-2018 Alejandro Iquira       Creación de la clase
****************************************************************************************/
public class Utilities {

    // AI Approve or reject a record
    public static void apprRejRecord(Id recordId, String action, String Comments)
    {
                
        system.debug('Utilities apprRejRecord 0');
        //Class used for Approving Record
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(Comments);
        
        //Approve or Reject Record
        req.setAction(action);
        system.debug('Utilities apprRejRecord 1');
        //Getting Work Item Id
        list<ProcessInstanceWorkitem> lstAppItems = [Select Id from ProcessInstanceWorkitem 
                                         where ProcessInstance.TargetObjectId =:recordId];
        
        system.debug('Utilities apprRejRecord 2'+lstAppItems);
        if(lstAppItems.size()>0){
            
        system.debug('Utilities apprRejRecord 4');
            req.setWorkitemId(lstAppItems.get(0).Id);
        system.debug('Utilities apprRejRecord 4.1.');
            // Submit the request for approval
            Approval.ProcessResult result = Approval.process(req);
        system.debug('Utilities apprRejRecord 5');
        }
        
    }
    
    
    // AI Metodo auxiliar para generar a partir de un describe la data para un combobox
    private static Map<String, Schema.DescribeSobjectResult> describes {
        get{
            if(describes == null){
                describes = new Map<String, Schema.DescribeSobjectResult>();
            }
            return describes;
        }
        
        set;
    }
    
    //AI  Devuelve la lista de opciones de cualquier picklist de cualquier objeto
    public static List<SelectOption> getSelectOptions(String objectName, String fielName){
        
        if(! describes.containsKey(objectName) ){
            
            String[] types = new String[]{objectName};
                
			// Make the describe call
			Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
            describes.put(objectName, results[0]);
        }
        
        // For each returned result, get some info
        List<selectoption> options = new List<selectoption>();
        for( Schema.PicklistEntry f : describes.get(objectName).fields.getMap().get(fielName).getDescribe().getPicklistValues()){
            options.add(new selectoption ( f.getValue(),f.getLabel()) );
        }
        
        return options;
    }
    
    // AI indica si el registro enviado como parámetro tiene o no un proceso de aprobación pendiente.
    public static boolean hasPendingApproval(Id recordId){
        boolean isPending=false;
    	list<ProcessInstanceWorkitem> pi= [SELECT Id FROM ProcessInstanceWorkitem 
                                           where ProcessInstance.TargetObjectId =:recordId];        
        
        
        if(pi.size()>0){
            isPending= true;
        }
        system.debug('Utilities.hasPendingApproval '+isPending);
        return isPending;
	}        
    
    
    // AI Indica si el usuario tiene Role asignado
    public static boolean userHasRole (id userId){
    
        list<user> u =[SELECT UserRoleId FROM user WHERE id= :userId];
        if(u.size()>0){
            return (u.get(0).UserRoleId ==null)? false:true;
        }else {
            return false;
        }
    }
    
}