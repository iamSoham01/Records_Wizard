import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjects from '@salesforce/apex/RecordWizard.getObjects';
import getObjectFields from '@salesforce/apex/RecordWizard.getObjectFields';
import getRecords from '@salesforce/apex/RecordWizard.getRecords';
import { NavigationMixin } from 'lightning/navigation';  

export default class BaseComponent extends NavigationMixin(LightningElement) {

    isSpinnerLoaded = false;
    isDataFetched = false;
    objOptions = [];
    isObjectSelected = true;
    objName;
    fieldValue;
    allSelectedFields = [`createddate`, `name`, `createdbyid`];
    fieldOptions = [];
    fieldOptionsMaster = [];
    allFetchedRecords;
    defaultLimit = 10;
    tableColumns = [];
    tableRecords;
    isShowModal = false;
    items = [];
    totalRecountCount = 0;
    pageSize = 10;
    endingRecord = 0;
    totalPage = 0;
    page = 1;
    isPageChanged = false;
    startingRecord = 1;
    endingRecord = 0;
    isPagination = false;

    //Load all sObjects initially
    connectedCallback(){
        getObjects()
        .then(result => {
            for (let key in result.mapAllObjects) {
                this.objOptions = [...this.objOptions, { label: result.mapAllObjects[key], value: key}];
            }
            this.sortAlphabaticOrder(this.objOptions);
            this.isSpinnerLoaded = !this.isSpinnerLoaded;
        })
        .catch(err => console.error(err));
    }

    //Load all Obj Fields
    handleObjComboBox(event) {
        this.handleReset();
        this.objName = event.detail.value;
        getObjectFields({objectName: this.objName})
        .then(result => {
            for (let key in result.mapSelectedObjFields) {
                this.fieldOptions = [...this.fieldOptions, { label: key, value: result.mapSelectedObjFields[key] }];
                this.fieldOptionsMaster = [...this.fieldOptionsMaster, { label: key, value: result.mapSelectedObjFields[key] }];
            }
            this.sortAlphabaticOrder(this.fieldOptions);
            this.isObjectSelected = false;
        })
        .catch(err => console.error(err))
    }

    //Selecting Fields
    handleFieldComboBox(event){
        this.fieldValue = event.detail.value;
        if(!this.allSelectedFields.includes(this.fieldValue)){
            this.allSelectedFields.push(this.fieldValue);
        }
        this.modifyOptions();
    }

    //Selecting fields displaying fields
    handlePillRemove(event) {
        this.fieldValue = [];
        const valueRemoved = event.target.name;
        this.allSelectedFields.splice(this.allSelectedFields.indexOf(valueRemoved), 1);
        this.modifyOptions();
    }

    //Sync selected fields and pill
    modifyOptions(){
        this.fieldOptions = this.fieldOptionsMaster.filter(elem=>{
            if(!this.allSelectedFields.includes(elem.value)) return elem;
        })
        this.sortAlphabaticOrder(this.fieldOptions);
    }

    //Choose total records
    handleTotalRecords(event){
        this.defaultLimit = event.target.value;
        if(this.defaultLimit <= 0){
            this.showNotification(`info`, `Please enter a value greater than 0. Default Value 10`, `Info`);
        }
    }

    //Display all records
    @api async handleFetchRecords(){

        //If Obj not selected show alert
        if(!this.objName){
            this.showNotification(`error`, `Please select an object`, `Alert`);
            throw new Error('No Object Selected');
        }
        
        this.tableColumns = [];
        this.tableRecords = [];
        
        await getRecords({
            objectName: this.objName, 
            fields: this.allSelectedFields,
            totalRecords: this.defaultLimit
        })
        .then(result => {
            
            if(result.errorMsg) {
                this.showNotification(`error`, result.errorMsg, `Error`);
                throw new Error(result.errorMsg);
            }
            if(!result.lstAllRecords.length) {
                this.showNotification(`warning`, `Sorry no records found`, `Warning`);
                throw new Error('No records found');
            } 
            this.processRecords(result);
            this.page = 1;
            this.isDataFetched = true;
        })
        .catch(err => console.error(err))
    }

    //Reset
    handleReset(){
        this.objName = ``;
        this.fieldOptions = [];
        this.fieldOptionsMaster = [];
        this.isObjectSelected = true;
        this.allSelectedFields = [`createddate`, `name`, `createdbyid`];
        this.defaultLimit = 10;
        this.isDataFetched = false;
        this.tableColumns = [];
        this.tableRecords = [];
    }

    //Display record detail page clicking edit button
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

    //Load records and columns in data table
    processRecords(data){
        this.items = data.lstAllRecords;
        this.totalRecountCount = data.lstAllRecords.length; 
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
            
        this.tableRecords = this.items.slice(0, this.pageSize); 
        this.endingRecord = this.pageSize;
        for (let key in data.lstDataTableColumns) {
                const col = data.lstDataTableColumns[key];
                let tableCol = {};
                if(col.type == `REFERENCE`) {
                    tableCol = { label: col.label, fieldName: col.fieldName, type: col.type};
                }else{
                    tableCol = { label: col.label, fieldName: col.fieldName, type: col.type.toLowerCase()};
                }
                this.tableColumns = [...this.tableColumns, tableCol];
        }
        if(data.isObjUpdatatble){
                const tableBtnRow = { 
                    type: "button-icon", 
                    typeAttributes: {  
                        iconName: 'utility:edit',
                        alternativeText: 'Edit',
                        size: 'xx-small',
                }       
            }
            this.tableColumns = [...this.tableColumns, tableBtnRow];
        }
        this.isPagination = this.totalRecountCount > this.pageSize;
        this.isNxtBtn = this.isPagination;
    }

    //Previous button
    previousHandler(){
        this.isPageChanged = true;
        if (this.page > 1) {
            this.page = this.page - 1; 
            this.displayRecordPerPage(this.page);
        }
    }

    //Next button
    nextHandler(){
        this.isPageChanged = true;
        if((this.page < this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; 
            this.displayRecordPerPage(this.page);
        }
    }

    //Display records in a page
    displayRecordPerPage(page){

        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 

        this.tableRecords = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;

    }

    //Next Btn Visibility
    @api 
    get isNxtBtn(){
        return this.page < this.totalPage;
    }

    //Prev Btn Visibility
    @api 
    get isPrevBtn(){
        return this.page > 1;
    }

    //Sort drop down values alphabatically
    sortAlphabaticOrder(arrToSort){
        arrToSort.sort(function (a, b) {
                if (a.label < b.label) {
                    return -1;
                }
                if (a.label > b.label) {
                    return 1;
                }
                    return 0;
            });
    }

    //Toast msg
    showNotification(varType, msg, title) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: varType,
        });
        this.dispatchEvent(evt);
    }
}