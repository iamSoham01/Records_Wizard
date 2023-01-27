import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjects from '@salesforce/apex/RecordWizard.getObjects';
import getObjectFields from '@salesforce/apex/RecordWizard.getObjectFields';
import getRecords from '@salesforce/apex/RecordWizard.getRecords';
import { NavigationMixin } from 'lightning/navigation';  

export default class BaseComponent extends NavigationMixin(LightningElement) {

    loaded = false;
    isDataFetched = false;
    objOptions = [];
    isObjectSelected = true;
    objName;
    fieldValue;
    allFieldValues = [];
    fieldOptions = [];
    fieldOptionsMaster = [];
    allFetchedRecords;
    defaultLimit = 10;
    tableColumns = [];
    tableRecords;
    isShowModal = false;

    connectedCallback(){
        getObjects()
        .then(result => {
            for (let key in result.objectMap) {
                this.objOptions = [...this.objOptions, { label: key, value: result.objectMap[key] }];
            }
            this.loaded = !this.loaded;
        })
        .catch(err => console.error(err));
    }

    handleObjComboBox(event) {
        this.handleReset();
        this.objName = event.detail.value;
        getObjectFields({objectName: this.objName})
        .then(result => {

            for (let key in result.mapObjfields) {
                this.fieldOptions = [...this.fieldOptions, { label: key, value: result.mapObjfields[key] }];
                this.fieldOptionsMaster = [...this.fieldOptionsMaster, { label: key, value: result.mapObjfields[key] }];
            }
            this.isObjectSelected = false;
        })
        .catch(e => console.error(err))
    }

    handleFieldComboBox(event){
        this.fieldValue = event.detail.value;
        if(!this.allFieldValues.includes(this.fieldValue)){
            this.allFieldValues.push(this.fieldValue);
        }
        this.modifyOptions();
    }

    handlePillRemove(event) {
        this.fieldValue = ``;
        const valueRemoved = event.target.name;
        this.allFieldValues.splice(this.allFieldValues.indexOf(valueRemoved), 1);
        this.modifyOptions();
    }

    modifyOptions(){
        this.fieldOptions = this.fieldOptionsMaster.filter(elem=>{
            if(!this.allFieldValues.includes(elem.value)) return elem;
        })
    }

    handleTotalRecords(event){
        this.defaultLimit = event.target.value;
        if(this.defaultLimit <= 0){
            this.showNotification(`info`, `Please enter a value greater than 0. Default Value 10`, `Info`);
        }
    }

    @api
    async handleFetchRecords(){

        if(!this.objName){
            this.showNotification(`error`, `Please select an object`, `Alert`);
            throw new Error('No Object Selected');
        }
        
        this.tableColumns = [];
        this.tableRecords = [];
        
        await getRecords({
            objectName: this.objName, 
            fields: this.allFieldValues,
            totalRecords: this.defaultLimit
        })
        .then(result => {

            if(result.errorMsg) {
                this.showNotification(`error`, result.errorMsg, `Error`);
                throw new Error(result.errorMsg);
            }
            if(!result.allRecords.length) {
                this.showNotification(`warning`, `Sorry no records found`, `Alert`);
                throw new Error('No records found');
            }

            const tableBtnRow = { 
                type: "button-icon", 
                typeAttributes: {  
                    iconName: 'utility:edit',
                    alternativeText: 'Edit',
                    size: 'xx-small',
                }       
            } 

            for (let key in result.dataTableColumns) {
                const col = result.dataTableColumns[key];
                this.tableColumns = [...this.tableColumns, { label: col.label, fieldName: col.fieldName, type: col.type.toLowerCase()}];
            }
            if(result.isUpdatatble){
                this.tableColumns = [...this.tableColumns, tableBtnRow];
            }
            
            this.tableRecords = result.allRecords;
            this.isDataFetched = true;
        })
        .catch(err => console.error(err))
    }

    handleReset(){
        this.objName = ``;
        this.fieldOptions = [];
        this.fieldOptionsMaster = [];
        this.isObjectSelected = true;
        this.allFieldValues = [];
        this.defaultLimit = 10;
        this.isDataFetched = false;
        this.tableColumns = [];
        this.tableRecords = [];
    }

    callRowAction(event){
        const recId = event.detail.row.Id;
        this[NavigationMixin.Navigate]({  
                type: 'standard__recordPage',  
                attributes: {  
                    recordId: recId,  
                    objectApiName: this.objName,  
                    actionName: 'edit'  
                }  
        })
    }

    showNotification(varType, msg, title) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: varType,
        });
        this.dispatchEvent(evt);
    }
}