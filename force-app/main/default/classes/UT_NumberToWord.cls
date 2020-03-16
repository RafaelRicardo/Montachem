/*************************************************************************************
 Desarrollado por: VASS 
 Autor:            Alejandro iquira
 Proyecto:         MONTACHEM
 Descripción:      Clase que transforma
 Clase de prueba:  Account_tst

 Cambios (Versiones) 
 ----------------------------------------------------------------------------------- 
 No.  Fecha       Autor                   Descripción 
 ---- ----------- ----------------------- ------------------------------------------
 1.0  05-05-2019 Alejandro iquira         Creación
****************************************************************************************/
public class UT_NumberToWord {  
      static String[] to_19 = new string[]{ 'zero', 'one',  'two', 'three', 'four',  'five',  'six',  
      'seven', 'eight', 'nine', 'ten',  'eleven', 'twelve', 'thirteen',  
      'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen' };  
    static String[] tens = new string[]{ 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'};  
    static String[] denom = new string[]{ '',  
      'thousand',   'million',     'billion',    'trillion',    'quadrillion',  
     'quintillion', 's!xtillion',   'septillion',  'octillion',   'nonillion',  
     'decillion',  'undecillion',   'duodecillion', 'tredecillion',  'quattuordecillion',  
      's!xdecillion', 'septendecillion', 'octodecillion', 'novemdecillion', 'vigintillion' };  
    // convert a value < 100 to English.    
   public static String convert_nn(integer val) {  
      if (val < 20)  
        return to_19[val];  
      if(val == 100)  
          return 'One Hundred';  
      for (integer v = 0; v < tens.size(); v++) {  
        String dcap = tens[v];  
        integer dval = 20 + 10 * v;  
        if (dval + 10 > val) {  
          if (Math.Mod(val,10) != 0)  
            return dcap + ' ' + to_19[Math.Mod(val,10)];  
          return dcap;  
        }      
      }  
      return 'Should never get here, less than 100 failure';  
    }  
    // convert a value < 1000 to english, special cased because it is the level that kicks   
    // off the < 100 special case. The rest are more general. This also allows you to  
    // get strings in the form of "forty-five hundred" if called directly.  
    public static String convert_nnn(integer val) {  
      String word = '';  
      integer rem = val / 100;  
      integer mod = Math.mod(val,100);  
      if (rem > 0) {  
        word = to_19[rem] + ' hundred';  
        if (mod > 0) {  
          word += ' ';  
        }  
      }  
      if (mod > 0) {  
        word += convert_nn(mod);  
      }  
      return word;  
    }  
     
     public static String english_number(decimal val) {  
         
         
         String wordValue;
         String valueString = String.valueOf(val);
         system.debug('NumberToWord Value in String '+valueString);
         list<String> valueSplit = valueString.split('\\.');
         system.debug('NumberToWord dividido '+valueSplit);
         
         // Parte entera del valor
         long integerPart = long.valueOf(valueSplit[0]);
         system.debug('NumberToWord parte entera: '+integerPart);
         // Parte entera en letras
         String integerPartSWord= convert_english_number(integerPart)+ ' dollars';   
         system.debug('NumberToWord parte entera en letras:'+integerPartSWord);
         
         // Parte decimal del valor
         long decimalPart = (valueSplit.size()>1)?  long.valueOf(valueSplit[1]):0;
         system.debug('NumberToWord parte decimal:'+decimalPart);
         
         // si tiene parte decimal
         if(decimalPart>0){
             String decimalPartWord= convert_english_number(decimalPart);
             integerPartSWord = integerPartSWord+ ' with '+  decimalPartWord + ' cents';
         }
         
         system.debug('wordValue antes:'+integerPartSWord);
         integerPartSWord = integerPartSWord.substring(0,1).toUpperCase()+integerPartSWord.substring(1,integerPartSWord.length()); 
         system.debug('wordValue despues:'+integerPartSWord);
         return integerPartSWord;
         
     }           
    public static String convert_english_number(long val) {  
        
        if (val < 100) {  
        return convert_nn(val.intValue()) ;  
      }  
      if (val < 1000) {  
        return convert_nnn(val.intValue());  
      }  
     for (integer v = 0; v < denom.size(); v++) {  
        integer didx = v - 1;  
        integer dval = (integer)Math.pow(1000, v);  
        if (dval > val) {  
          integer mod = (integer)Math.pow(1000, didx);  
          integer l = (integer) val / mod;  
          integer r = (integer) val - (l * mod);  
          String ret = convert_nnn(l) + ' ' + denom[didx];  
          if (r > 0) {  
            ret += ', ' + convert_english_number(r);  
          }  
          return ret ;  
        }  
      }

      return 'Should never get here, bottomed out in english_number';  
    }  
  }