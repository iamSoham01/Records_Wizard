/*
* @Name         RecordWizard 
* @Author       Soham Datta
* @Date         26/01/2023
* @Description  This class contains all the methods referenced in baseComponent lwc
*/
public with sharing class RecordWizard {

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
            
            wrapper.objectMap = new Map<String,String>();
            for(Schema.SObjectType objTyp : gd.values()){
            String value = objTyp.getDescribe().getName();
            String label = objTyp.getDescribe().getLabel();
                
            if(!value.containsignorecase(ConstantClass.HISTORY) && !value.containsignorecase(ConstantClass.TAG) &&
                    !value.containsignorecase(ConstantClass.SHARE) && !value.containsignorecase(ConstantClass.FEED) && 
                    !value.containsignorecase(ConstantClass.GROUPOBJ) && !value.containsignorecase(ConstantClass.PUBLICOBJ) &&
                    !objTyp.getDescribe().isCustomSetting() && objTyp.getDescribe().isAccessible() &&
                    objTyp.getDescribe().isQueryable() && objTyp.getDescribe().isSearchable()){      
                        
                        wrapper.objectMap.put(label, value);
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

            wrapper.mapObjFields = new Map<String,String>();
            
            if(String.isBlank(objectName)){
                throw new MyException(ConstantClass.OBJ_NAME_MISSING);
            }

            Schema.SObjectType objToken = gd.get(objectName); 
            Map<String,Schema.SObjectField> fieldsMap = objToken.getDescribe().fields.getMap();

            for(String field : fieldsMap.keySet()){
                Schema.DescribeFieldResult describeResult = fieldsMap.get(field).getDescribe();
                if (describeResult.isAccessible()) {
                    wrapper.mapObjFields.put(String.valueOf(describeResult.getLabel()), String.valueOf(field));
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
    @AuraEnabled(cacheable=true)
        public static WrapperData getRecords(String objectName, List<String> fields, String totalRecords){

            wrapper.allRecords = new List<sObject>();
            wrapper.dataTableColumns = new List<DataTableColumns>();

            if(String.isBlank(objectName)){
                throw new MyException(ConstantClass.OBJ_NAME_MISSING);
            }

            if(String.isBlank(totalRecords) || Integer.valueOf(totalRecords) <= 0){
                totalRecords = ConstantClass.DEFAULT_LIMIT;
            }

            if(fields.isEmpty()){
                fields = new List<String>{ConstantClass.NAME_FIELD, ConstantClass.CREATEDBYID_FIELD, ConstantClass.CREATEDDATE_FIELD};
            }

            try{

                Schema.SObjectType objToken = gd.get(objectName); 
                Map<String,Schema.SObjectField> fieldsMap = objToken.getDescribe().fields.getMap();
                
                String query = ConstantClass.SELECT_QUERY;
                for(String field: fields){
                    if(fieldsMap.containsKey(field)){
                        query += field + ', ';
                        Schema.DescribeFieldResult describeResult = fieldsMap.get(field).getDescribe();
                        String fieldLabel = String.valueOf(describeResult.getLabel());
                        String fieldName = String.valueOf(describeResult.getName());
                        String fieldType = String.valueOf(describeResult.getType());
                        DataTableColumns dataColumn = new DataTableColumns(fieldLabel, fieldName, fieldType);
                        wrapper.dataTableColumns.add(dataColumn);
                    }
                }
                query = query.removeEnd(', ') + ConstantClass.FROM_QUERY + objectName + ConstantClass.ORDERBY_QUERY + totalRecords;

                SObjectAccessDecision securityDecision = Security.stripInaccessible(
                    AccessType.READABLE, Database.query(String.escapeSingleQuotes(query))
                    );
                wrapper.allRecords = securityDecision.getRecords();
                wrapper.isUpdatatble = objToken.getDescribe().isUpdateable();

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
            
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String fieldName {get;set;}
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
        @AuraEnabled public Map<String,String> objectMap;
        @AuraEnabled public Map<String,String> mapObjfields;
        @AuraEnabled public List<sObject> allRecords {get; set;}
        @AuraEnabled public String errorMsg;
        @AuraEnabled public List<DataTableColumns> dataTableColumns {get;set;}
        @AuraEnabled public Boolean isUpdatatble;

        public WrapperData(){
            objectMap = new Map<String,String>();
            mapObjFields = new Map<String,String>();
            allRecords = new List<sObject>();
            errorMsg = '';
            dataTableColumns = new List<DataTableColumns>();
            isUpdatatble = false;
        }
        
    }


}