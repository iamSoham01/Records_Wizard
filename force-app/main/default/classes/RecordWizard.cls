/*
* @Name         RecordWizard 
* @Author       Soham Datta
* @Date         26/01/2023
* @Description  This class contains all the methods referenced in baseComponent lwc
*/
public with sharing class RecordWizard {

    //Global describe
    public static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    public static WrapperData wrapper = new WrapperData();

    /*
    * @Description  This method retrieves all the sObjecs user has read access
    * @Param		
    * @Return       WrapperData 
    * @Author       Soham Datta
    */
    @AuraEnabled(cacheable=true)
    public static WrapperData getObjects(){
        
        wrapper.mapAllObjects = new Map<String,String>();
        for(Schema.SObjectType objTyp : gd.values()){
            String name = objTyp.getDescribe().getName();
            String label = objTyp.getDescribe().getLabel();
            
            //Filling objs name
            if(RecordWizardHelper.getOrgObjects(name, objTyp)){      
                wrapper.mapAllObjects.put(name, label);
            }
        }
        return wrapper;
    }

    /*
    * @Description  This method retrieves all the object fields user has read access
    * @Param		String
    * @Return       WrapperData 
    * @Author       Soham Datta
    */
    @AuraEnabled(cacheable=true)
    public static WrapperData getObjectFields(String objectName){
        
        wrapper.mapSelectedObjFields = new Map<String,String>();
        
        //Throw exception if obj name is blank
        if(String.isBlank(objectName)){
            throw new MyException(ConstantClass.OBJ_NAME_MISSING);
        }
        
        Schema.SObjectType objToken = gd.get(objectName); 
        Map<String,Schema.SObjectField> fieldsMap = objToken.getDescribe().fields.getMap();
        
        for(String field : fieldsMap.keySet()){
            Schema.DescribeFieldResult describeResult = fieldsMap.get(field).getDescribe();
            if (describeResult.isAccessible()) {
                //Filling obj fields name
                wrapper.mapSelectedObjFields.put(String.valueOf(describeResult.getLabel()), String.valueOf(field));
            }
        }
        return wrapper;
    }

    /*
    * @Description  This method retrieves all the records of the object user has read access
    * @Param		String, List<String>
    * @Return       WrapperData 
    * @Author       Soham Datta
    */
    @AuraEnabled(cacheable=false)
    public static WrapperData getRecords(String objectName, List<String> fields, String totalRecords){
        
        wrapper.lstAllRecords = new List<sObject>();
        wrapper.lstDataTableColumns = new List<DataTableColumns>();
        String orderByQuery = '';
        
        //Throw exception if obj name is blank
        if(String.isBlank(objectName)){
            throw new MyException(ConstantClass.OBJ_NAME_MISSING);
        }
        
        //Setting default num of records 10
        if(String.isBlank(totalRecords) || Integer.valueOf(totalRecords) <= 0){
            totalRecords = ConstantClass.DEFAULT_LIMIT;
        }
        
        //Setting default fields: Name, CreatedByDate, CreatedById
        if(fields.isEmpty()){
            fields = new List<String>{ConstantClass.NAME_FIELD, ConstantClass.CREATEDBYID_FIELD, ConstantClass.CREATEDDATE_FIELD};
                }
        
        try{
            
            Schema.SObjectType objToken = gd.get(objectName); 
            Map<String,Schema.SObjectField> fieldsMap = objToken.getDescribe().fields.getMap();
            
            //Dynamic query
            String query = ConstantClass.SELECT_QUERY;
            for(String field: fields){
                if(fieldsMap.containsKey(field)){
                    query += field + ', ';
                    
                    //Filling data columns apiName, label and Type 
                    Schema.DescribeFieldResult describeResult = fieldsMap.get(field).getDescribe();
                    String fieldLabel = String.valueOf(describeResult.getLabel());
                    String fieldName = String.valueOf(describeResult.getName());
                    String fieldType = String.valueOf(describeResult.getType());
                    DataTableColumns dataColumn = new DataTableColumns(fieldLabel, fieldName, fieldType);
                    wrapper.lstDataTableColumns.add(dataColumn);
                    
                    if(field.containsIgnoreCase(ConstantClass.CREATEDDATE_FIELD)){
                        orderByQuery = ConstantClass.ORDERBY_QUERY;
                    }
                }
            }
            query = query.removeEnd(', ') + ConstantClass.FROM_QUERY + objectName
                + ConstantClass.ORDERBY_QUERY + ConstantClass.LIMIT_QUERY + totalRecords;
            
            System.debug('query: '+query);
            
            //Query all records user has read access
            SObjectAccessDecision securityDecision = Security.stripInaccessible(
                AccessType.READABLE, Database.query(String.escapeSingleQuotes(query))
            );
            wrapper.lstAllRecords = securityDecision.getRecords();
            //Checking user has object update permission 
            wrapper.isObjUpdatatble = objToken.getDescribe().isUpdateable();
            
        }catch(Exception e){
            wrapper.errorMsg = String.valueOf(e.getMessage());
            CustomErrorLog.logException(e);
        }
        return wrapper;
    }

    /*
    * @Name         DataTableColumns 
    * @Author       Soham Datta
    * @Date         26/01/2023
    * @Description  This class contains data table column properties
    */
    public class DataTableColumns {
        
        //Column Label
        @AuraEnabled public String label {get;set;}
        //Column API Name
        @AuraEnabled public String fieldName {get;set;}
        //Column Data Type
        @AuraEnabled public String type {get;set;}
        
        public DataTableColumns(String label, String fieldName, String type)
        {
            this.label     = label;
            this.fieldName = fieldName;
            this.type      = type;          
        }
    }

    /*
    * @Name         WrapperData 
    * @Author       Soham Datta
    * @Date         26/01/2023
    * @Description  This wrapper is the main container to communicate with ui
    */
    public class WrapperData {
        
        //Objects Name and Label
        @AuraEnabled public Map<String,String> mapAllObjects;
        //Object Fields Name and Label
        @AuraEnabled public Map<String,String> mapSelectedObjFields;
        //All Selected Records
        @AuraEnabled public List<sObject> lstAllRecords {get; set;}
        //Exception Message
        @AuraEnabled public String errorMsg;
        //Data Table Columns
        @AuraEnabled public List<DataTableColumns> lstDataTableColumns {get;set;}
        //Checking User Update Permission on Object
        @AuraEnabled public Boolean isObjUpdatatble;
        
    }


}