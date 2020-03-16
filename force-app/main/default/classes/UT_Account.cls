/***************************************************************************************************************
* Vass 
* @author           Wiliam Dorado
* Proyecto:         Montachem
* Description:      Clase de Utilidades
****************************************************************************************************************/
public class UT_Account
{

    /*******************************************************************************************
      RETORNA EL CODIGO CONSECUTIVO DE LA CUENTA EN BASE AL PAIS
      ********************************************************************************************/

     public static String getCodeAccount(String Code)
     {
         String CodeAccount='';
         
         
         AggregateResult[] maxConseAgr=[select max(Consecutive__c) consec from account where Country_Prefix_Code__c=:Code];
         
         
         if(maxConseAgr[0].get('consec') != null)
         {	
             integer maxConsec = integer.valueOf(maxConseAgr[0].get('consec'));
             
             system.debug('AccountUtilities_cls 1'+maxConsec);
             Integer UltimoConsecutivo=Integer.ValueOf(maxConsec);
             system.debug('AccountUtilities_cls 2:'+UltimoConsecutivo);
             UltimoConsecutivo=UltimoConsecutivo+1;
             Integer largo=String.ValueOf(UltimoConsecutivo).length();
             
             String strCerosPrefijos='';
             if(UltimoConsecutivo <=999){
				for(Integer i=0;i<(3-largo);i++)
                     strCerosPrefijos=strCerosPrefijos+'0';
             }
             
             CodeAccount=Code+strCerosPrefijos+String.ValueOf(UltimoConsecutivo);
         }else
         {
             CodeAccount=Code+'001';
         }     
    
         return CodeAccount;
         
     }
     
     
     /*******************************************************************************************
      RETORNA EL CODIGO CONSECUTIVO DE LA CUENTA BASADO AL PAIS
      ********************************************************************************************/

     public static Integer getNextCodeAccount(String Code)
     {
         String CodeAccount='';
         
         
         AggregateResult[] maxConseAgr=[select max(Consecutive__c) consec from account where Country_Prefix_Code__c=:Code];
         
         if(maxConseAgr[0].get('consec') != null )
         {
          integer maxConsec = Integer.ValueOf(maxConseAgr[0].get('consec'));
          return maxConsec +1;
           
         }else
         {
             return 1;
         }     
     }
    
    // AI obtiene información de una locación
    public Static Location__c getLocationInf(id locationId){
        
        Location__c l=null;
        if (locationId !=null){
            l= new Location__c();
            l= [select id, name, code__c, Accoun_prefix_code__c, Type__c, Parent_location__c from location__c  where id=:locationId];
        }
        
        return l;
        
    }
    
	public class AccountWrapper {

		Public String   Id  {get; set;}
        Public String   AccountCode  {get; set;}
        Public String   LicTradNum {get; set;}
        Public String   AccountCurrency  {get; set;}
        public String AccountSFId {get; set;}
        
        Public String   OwnerSAPCode {get; set;}
        Public String   Name  {get; set;}
        Public String   Phone1  {get; set;}
        Public String   E_Mail  {get; set;}
        Public String   Website  {get; set;}
        Public String   Celular  {get; set;}
        Public String   Status  {get; set;}
        Public String   Payment_term  {get; set;}
        Public decimal   CreditLimit  {get; set;}
        Public Boolean   NoModifyOwner  {get; set;}
        Public String   InternalReference {get; set;}
        Public String   CompanyPresident {get; set;}
        
        Public String   Address_Line_1_Bill_1  {get; set;}
        Public String   Address_Line_1_Bill_2  {get; set;}
        Public String   Address_Line_1_Ship_1  {get; set;}
        Public String   Address_Line_1_Ship_2  {get; set;}
        Public String   Address_Line_2_Bill_1  {get; set;}
        Public String   Address_Line_2_Bill_2  {get; set;}
        Public String   Address_Line_2_Ship_1  {get; set;}
        Public String   Address_Line_2_Ship_2  {get; set;}
        Public String   City_Bill_1  {get; set;}
        Public String   City_Bill_2  {get; set;}
        Public String   City_Ship_1  {get; set;}
        Public String   City_Ship_2  {get; set;}
        Public String   Zip_code_Bill_1  {get; set;}
        Public String   Zip_code_Bill_2  {get; set;}
        Public String   Zip_code_Ship_1  {get; set;}
        Public String   Zip_code_Ship_2  {get; set;}
        
        Public String   AccountCountry  {get; set;}
        Public String   Country_Bill_1  {get; set;}
        Public String   Country_Bill_2  {get; set;}
        Public String   Country_Ship_1  {get; set;}
        Public String   Country_Ship_2  {get; set;}
        
		public AccountWrapper(){}
	}
}