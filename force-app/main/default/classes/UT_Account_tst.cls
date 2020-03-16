@isTest
public class UT_Account_tst 
{
     
    // Test credit approval.
    @isTest static void myTest() { 
       
        // Crear configuraciones personalizadas de los WS
        // crear cuentas 
        Account ctaNew=DataGenerator_cls.createAccount(true, null);
        ctaNew.Account_code__c = UT_Account.getCodeAccount(ctaNew.country__r.code__c);       
        ctaNew.Consecutive__c  = UT_Account.getNextCodeAccount(ctaNew.country__r.code__c);    
        Location__c          l = UT_Account.getLocationInf(ctaNew.Country__c); 
        UT_Account.AccountWrapper accWpr = new UT_Account.AccountWrapper();

        accWpr.AccountCode='23';
        accWpr.LicTradNum='23';
        accWpr.AccountCurrency='23';
                
        accWpr.OwnerSAPCode='COL123';
        accWpr.Name='23';
        accWpr.Phone1='23';
        accWpr.E_Mail='23';
        accWpr.Website='23';
        accWpr.Celular='23';
        accWpr.Status='23';
        accWpr.Payment_term='23';
        accWpr.CreditLimit=1.1;
        accWpr.NoModifyOwner=true;
        accWpr.InternalReference='23';
        accWpr.CompanyPresident='23';
                
        accWpr.Address_Line_1_Bill_1='23';
        accWpr.Address_Line_1_Bill_2='23';
        accWpr.Address_Line_1_Ship_1='23';
        accWpr.Address_Line_1_Ship_2='23';
        accWpr.Address_Line_2_Bill_1='23';
        accWpr.Address_Line_2_Bill_2='23';
        accWpr.Address_Line_2_Ship_1='23';
        accWpr.Address_Line_2_Ship_2='23';
        accWpr.City_Bill_1='23';
        accWpr.City_Bill_2='23';
        accWpr.City_Ship_1='23';
        accWpr.City_Ship_2='23';
        accWpr.Zip_code_Bill_1='23';
        accWpr.Zip_code_Bill_2='23';
        accWpr.Zip_code_Ship_1='23';
        accWpr.Zip_code_Ship_2='23';
                
        accWpr.AccountCountry='23';
        accWpr.Country_Bill_1='23';
        accWpr.Country_Bill_2='23';
        accWpr.Country_Ship_1='23';
        accWpr.Country_Ship_2='23';
                    
    }
    
    
}