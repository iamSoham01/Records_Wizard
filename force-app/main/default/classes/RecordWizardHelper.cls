/*
* @Name         RecordWizardHelper 
* @Author       Soham Datta
* @Date         28/01/2023
* @Description  This class is the helper class of RecordWizard
*/
public with sharing class RecordWizardHelper {
    
    /*
    * @Description  This method removes custom settings along with few objects and check object is accessible
    * @Param		
    * @Return       Boolean 
    * @Author       Soham Datta
    */
    public static Boolean getOrgObjects(String name, Schema.SObjectType objTyp){
        
        //Removing some objects and custom settings and checking objects are accessible, queryable, 
        return !name.containsignorecase(ConstantClass.HISTORY) && !name.containsignorecase(ConstantClass.TAG) &&
            !name.containsignorecase(ConstantClass.SHARE) && !name.containsignorecase(ConstantClass.FEED) && 
            !name.containsignorecase(ConstantClass.GROUPOBJ) && !name.containsignorecase(ConstantClass.PUBLICOBJ) &&
            !objTyp.getDescribe().isCustomSetting() && objTyp.getDescribe().isAccessible() &&
            objTyp.getDescribe().isQueryable() && objTyp.getDescribe().isSearchable();
        
    }
    
}