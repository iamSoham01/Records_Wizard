/*
* @Name         CutomErrorLog 
* @Author       Soham Datta
* @Date         26/01/2023
* @Description  This class is used to log errors
*/
public with sharing class CustomErrorLog {
    
    /*
    * @Description  This method insert exceptions
    * @Param		Exception
    * @Return        
    * @Author       Soham Datta
    */
    public static void logException(Exception e){
        
        try{
		    
            String stackTrace = e.getStackTraceString().substringBefore('\n');
		    String className = stackTrace.substringAfter('.').substringBefore('.');	
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
                
            //Governer Limit of executingQuery 
            String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String dmLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String dmlStat = '3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String cPUT = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
              
            //Log information in object
            CustomException__c exc = new CustomException__c();
            exc.Govt_Limit_in_Executing_Code__c = String.format('{0}\n{1}\n{2}\n{3}',new List<string>{queryLimit, dmLimit, dmlStat, cPUT});
            exc.Exception_Message__c = e.getMessage();
            exc.Exception_Type__c = e.getTypeName();
            exc.Line_Number__c = e.getLineNumber();
            exc.StackTrace__c = e.getStackTraceString();
            exc.MethodName__c = methodName;
            exc.ClassName__c = className;
            if(Schema.sObjectType.CustomException__c.isCreateable()){
                Database.insert(exc); 
            }

        }catch(Exception ex){
            System.debug('Exception on: ' + ex.getLineNumber() + ' Msg: ' + ex.getMessage());
        }           
    }
}