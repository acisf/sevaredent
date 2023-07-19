/**
 * Created by cshah on Oct 30, 2020.
 */

import {
    LightningElement,
    api,
    track
} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {refreshApex} from '@salesforce/apex';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';
import init from '@salesforce/apex/NewAmendmentRecordUtility.init';
import cancelAmendment from '@salesforce/apex/NewAmendmentRecordUtility.cancelAmendment';
import checkIfAmendmentWillApply from '@salesforce/apex/NewAmendmentRecordUtility.checkIfAmendmentWillApply';

export default class NewAmendmentRecord extends NavigationMixin(LightningElement) {

    @api recordId;
    @api contractId;
    @api actionName;
    amendmentFieldList = [];
    @track selectedAmendmentFields = {};
    @track lastSelectedAmendmentFieldAPI = '';
    @track amendment = {};
    @api isWarningFromLocal = false;
    @api warningString = '';

    isActivated = false;
    isCancelled = false;
    loading = true;
    contractFieldList;

    connectedCallback() {
        console.log('LWC: NewAmendmentRecord.connectedCallback recordId: ', this.recordId);
        console.log('LWC: NewAmendmentRecord.connectedCallback contractId: ', this.contractId);

        this.loading = false;
        if (this.contractId || this.recordId) {
            this._init();
        }
    }

    _init = () => {
        this.loading = true;
        init({
            recordId: this.recordId,
            contractId: this.contractId
        }).then((result) => {
            console.log('LWC: NewAmendmentRecord.init result: ', result);

            this.contractFieldList = result.contractFieldAPIAndLabelDetails;

            this.amendment = result.amendment;
            this.contractId = this.amendment.contractId;

            if (((this.amendment.amendmentStatus || '').toLowerCase() === 'activated')
                || this.amendment.isCancelled) {
                this.isActivated = true;
                this.isCancelled = true;
                this.actionName = 'view';
            }
            let fieldsDataType = {};
            this.contractFieldList.forEach((contractField) => {
                fieldsDataType[contractField.apiName] = contractField.dataType
            });

            let existingAmendmentContractFields = {};
            Object.keys(this.amendment.amendmentContractFields).forEach((amendmentContractField) => {
                existingAmendmentContractFields[amendmentContractField] = {
                    value: this.amendment.amendmentContractFields[amendmentContractField],
                    values: fieldsDataType[amendmentContractField] === 'MULTIPICKLIST' ? this.amendment.amendmentContractFields[amendmentContractField].split(';') : this.amendment.amendmentContractFields[amendmentContractField]
                };
            });
            console.log('existingAmendmentContractFields: ', JSON.stringify(existingAmendmentContractFields));
            this._populateFields(existingAmendmentContractFields);

            this.loading = false;
        }).catch(error => {
            console.error('LWC: NewAmendmentRecord.getContractFieldNames', error);
            this.loading = false;
        });
    }

    _populateFields = (existingAmendmentContractFields) => {
        this.selectedAmendmentFields = {};
        const selectedFields = Object.keys(existingAmendmentContractFields);

        this.contractFieldList.forEach((contractField) => {
            const fieldLabel = contractField['label'];
            const fieldAPIName = contractField['apiName'];

            if (selectedFields.indexOf(contractField.apiName) > -1) {
                this.selectedAmendmentFields[fieldAPIName] = {
                    ...contractField,
                    value: existingAmendmentContractFields[fieldAPIName].value,
                    values: existingAmendmentContractFields[fieldAPIName].values
                }
            }
        });
        console.log(JSON.stringify(this.selectedAmendmentFields), JSON.stringify(Object.values(this.selectedAmendmentFields)));

        this._resetAvailableFields();
    }

    _resetAvailableFields = () => {
        const selectedFields = Object.keys(this.selectedAmendmentFields);

        this.amendmentFieldList = [];
        this.contractFieldList.forEach((contractField) => {
            if (selectedFields.indexOf(contractField.apiName) === -1) {
                this.amendmentFieldList.push({
                    label: contractField['label'],
                    value: contractField['apiName']
                });
            }
        });
    }

    _redirectToContract = (event) => {
        console.log('LWC: NewAmendmentRecord._redirectToContract this.contractId:', this.contractId);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contractId,
                objectApiName: 'Contract',
                actionName: 'view'
            }
        });
    }

    get canEdit() {

    }

    get isEditMode() {
        return (this.actionName.toLowerCase() !== 'view');
    }

    get amendmentFields() {
        return Object.values(this.selectedAmendmentFields);
    }

    get subtitle() {
        return (this.recordId ? 'Update' : 'New');
    }

    handleAmendmentFieldChange(event) {
        this.lastSelectedAmendmentFieldAPI = event.detail.value;
        console.log(this.lastSelectedAmendmentFieldAPI);
    }

    handleAddSelectedFieldForAmendment() {
        this._populateFields({
            ...this.selectedAmendmentFields,
            [this.lastSelectedAmendmentFieldAPI]: {
                value: ''
            }
        });

        /*console.log('LWC: NewAmendmentRecord.handleAmendmentFieldChange selectedAmendmentFields');
        console.log(this.selectedAmendmentFields);
        getRecordNotifyChange(this.selectedAmendmentFields);*/
    }

    removeField = (event) => {
        const dataset = event.target.dataset;

        delete this.selectedAmendmentFields[dataset.name];

        this._populateFields({
            ...this.selectedAmendmentFields
        });
    }

    handleOnLoad = (event) => {
        this.loading = false;
    }

    handleCancel = (event) => {
        this.loading = true;
        this._redirectToContract(event);
    }

    handleSuccess(event) {
        console.log('handleSuccess');
        console.log(event);
        this._redirectToContract(event);
    }

    handleOnError = (event) => {
        console.log('handleOnError');
        console.log(event);
        console.log(JSON.stringify(event.detail));
        this.loading = false;
    }

    handleSubmit(event) {
        console.log('LWC: NewAmendmentRecord.handleSubmit');
        event.preventDefault();

        this.loading = true;

        let amendmentContractFields = {};
        let contractFields = Object.keys(this.selectedAmendmentFields);
        contractFields.forEach((contractField) => {
            if(this.selectedAmendmentFields[contractField].dataType === 'MULTIPICKLIST') {
                amendmentContractFields[contractField] = [].concat(this.selectedAmendmentFields[contractField].value).join(';');
            } else {
                amendmentContractFields[contractField] = this.selectedAmendmentFields[contractField].value;
            }
        });


        const fields = event.detail.fields;
        fields.Contract__c = this.contractId;
        fields.Amendment_Contract_Fields__c = JSON.stringify(amendmentContractFields);
        console.log('handleSubmit.checkIfAmendmentWillApply recordId');
        console.log(this.recordId);
        this.isWarningFromLocal = false;
        this.warningString = '';

        checkIfAmendmentWillApply({
            recordId: this.recordId,
            amendmentMap: fields
        }).then((result) => {
            console.log('LWC: NewAmendmentRecord.handleSubmit result: ', result);
            let status = fields.Amendment_Status__c;
            console.log(status);
            this.loading = false;
            if((result !== '' && status !== 'Approved') || result === '') {
                console.log('save record block');
                this.template.querySelector('lightning-record-edit-form').submit(fields);
            } else if (this.recordId) {
                console.log('found record id block');
                this.handleOnError(event);
                eval("$A.get('e.force:refreshView').fire();");
            } else {
                console.log('last if else');
                this.showWarning(result);
            }

        }).catch(error => {
            this.showErrorsOnSave(error);
        });
    }
    showErrorsOnSave(error) {
        console.error('LWC: NewAmendmentRecord.showErrorsOnSave error: ', error);
        this.loading = false;
        let errorString = '';
        // if errors are added on top of page
        let errorList = error.body.pageErrors;
        console.log('errorList: ', errorList);
        if(errorList) {
            errorList.forEach((singleElement) => {
                errorString += singleElement['message'] + '\n';
            });
            console.log('errorString: ', errorString);
        }

        //if errors are added on field
        let fieldErrorsKeySet = Object.keys(error.body.fieldErrors);
        console.log('fieldErrorsKeySet: ', fieldErrorsKeySet);
        if(fieldErrorsKeySet) {
            fieldErrorsKeySet.forEach((fieldApiName) => {
                let errorList = error.body.fieldErrors[fieldApiName];
                console.log('fieldErrorsKeySet.errorList: ', errorList);
                errorList.forEach((singleElement) => {
                    errorString += (singleElement['message'] + '</br>');
                });
            });
            console.log('errorString: ', errorString);
        }

        this.showWarning(errorString);
    }

    showWarning(errorString) {
        this.isWarningFromLocal = true;
        this.warningString = '<div style="color:red;font-size:16px;">' + errorString + '</div>';
        this.loading = false;
    }

    handleCancelAmendment(event) {
        console.log('LWC: NewAmendmentRecord.handleCancelAmendment');
        this.isCancelled = true;
        this.loading = true;
        cancelAmendment({
            recordId: this.recordId
        }).then((result) => {
            console.log('LWC: NewAmendmentRecord.handleCancelAmendment result: ', result);
            this.loading = false;
            if(result) {
                this._redirectToContract(event);
            }
        }).catch(error => {
            console.error('LWC: NewAmendmentRecord.getContractFieldNames', error);
            this.loading = false;
        });
    }

    handleChange = (event) => {
        const name = event.target.name;
        let value = event.target.value;
        if (event.target.type === 'checkbox' || event.target.type === 'checkbox-button' || event.target.type === 'toggle') {
            value = event.target.checked;
        }

        this.selectedAmendmentFields = {
            ...this.selectedAmendmentFields,
            [name]: {
                ...this.selectedAmendmentFields[name],
                value
            }
        };
    }

    handleEdit = (event) => {
        this.actionName = 'edit';
    }
}