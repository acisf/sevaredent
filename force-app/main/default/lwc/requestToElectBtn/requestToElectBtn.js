import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";

import CONTRACT_NUMBER from "@salesforce/schema/APXT_Redlining__Contract_Agreement__c.Sevaredent_Contract_Number__c";
import CONTRACT_NAME from "@salesforce/schema/APXT_Redlining__Contract_Agreement__c.Name";
import CONTRACT_PRICE_LIST from "@salesforce/schema/APXT_Redlining__Contract_Agreement__c.Does_Contract_Have_a_Price_List__c";
import CONTRACTING_PARTY from "@salesforce/schema/APXT_Redlining__Contract_Agreement__c.Contracting_Party__c";
import CATEGORY from "@salesforce/schema/APXT_Redlining__Contract_Agreement__c.Category__c";
import SUBCATEGORY from "@salesforce/schema/APXT_Redlining__Contract_Agreement__c.Sub_Category__c";


import USER_ID from "@salesforce/user/Id";
import ACCOUNT_FIELD from "@salesforce/schema/User.AccountId";
import NAME_FIELD from "@salesforce/schema/User.Name";
import EMAIL_FIELD from "@salesforce/schema/User.Email";
import PHONE_FIELD from "@salesforce/schema/User.Phone";

import getAccountName from "@salesforce/apex/RequestToElectController.getAccountName";
import getReportID from "@salesforce/apex/RequestToElectController.getReportID";
import sendEmail from "@salesforce/apex/SendEmailController.sendEmail";
import getImplementations from "@salesforce/apex/ContractImplementedMarkCtrl.getImplementations";

import GET_PRICING_ITEMS_BTN from "@salesforce/label/c.Get_Pricing_Items_btn";
import REQUEST_ELECT_BTN from "@salesforce/label/c.Request_to_Elect_btn";
import REQUEST_INFO_BTN from "@salesforce/label/c.Request_Info_btn";
import REQUEST_SUCCESS_MSG from "@salesforce/label/c.Request_Success_msg";
import REQUEST_DUPLICATE_MSG from "@salesforce/label/c.Request_duplicate_msg";

export default class RequestToElectBtn extends NavigationMixin(
    LightningElement
) {
    LABELS = {
        GET_PRICING_ITEMS_BTN,
        REQUEST_ELECT_BTN,
        REQUEST_INFO_BTN,
        REQUEST_SUCCESS_MSG,
        REQUEST_DUPLICATE_MSG
    };

    @api recordId;
    contractNumber;
    contractName;
    contractParty;
    contractCategory;
    contractSubcategory;
    contractHavePriceList;

    reportId;

    userId = USER_ID;
    name;
    email;
    phone;
    account;
    accountId;

    subject;
    message;

    electIsSent = false;
    infoIsSent = false;
    isImplemented = false;

    @wire(getImplementations, { contractId: "$recordId" })
    load({ data, error }) {
        if (data && data[0]) {
            this.isImplemented = true;
        } else if (error) {
            this.showToast("error", error.body.message);
        }
    }

    @wire(getReportID)
    loadReportId({ data, error }) {
        if (data) {
            this.reportId = data;
        } else if (error) {
            this.showToast("error", error.body.message);
        }
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [CONTRACT_NUMBER, CONTRACT_NAME, CONTRACT_PRICE_LIST, CONTRACTING_PARTY, CATEGORY,SUBCATEGORY]
    })
    loadContract({ data, error }) {
        console.log('DATA');
        console.log(data);
        if (data) {
            this.contractNumber = getFieldValue(data, CONTRACT_NUMBER);
            this.contractName = getFieldValue(data, CONTRACT_NAME);
            this.contractHavePriceList = getFieldValue(data, CONTRACT_PRICE_LIST);
            this.contractParty = getFieldValue(data,CONTRACTING_PARTY);
            this.contractCategory = getFieldValue(data,CATEGORY);
            this.contractSubcategory = getFieldValue(data,SUBCATEGORY);
        } else if (error) {
            this.showToastMessage("error", error.body.message);
        }
    }

    get showPriceReport() {
        return (this.isImplemented && this.contractHavePriceList === 'Yes');
    }

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [ACCOUNT_FIELD, NAME_FIELD, EMAIL_FIELD, PHONE_FIELD]
    })
    loadUser({ data, error }) {
        if (data) {
            this.name = data.fields.Name.value;
            this.email = data.fields.Email.value;
            this.phone = data.fields.Phone.value;
            this.accountId = data.fields.AccountId.value;
            this.getAccName(this.accountId);
        } else if (error) {
            this.showToastMessage("error", error.body.message);
        }
    }

    getAccName(accId) {
        if (accId) {
            getAccountName({ id: accId })
                .then((result) => {
                    this.account = result;
                })
                .catch((error) => {
                    this.showToastMessage("error", error.body.message);
                });
        }
    }

    composeEmail(type) {
        if (this.account && this.name) {
            this.subject = `${type} Request – ${this.account}, ${this.contractNumber} - ${this.contractParty}`;
            this.message = `
            Account Name - ${this.account}, ID: ${this.accountId}
            Sevaredent Contract Number - ${this.contractNumber}, ID: ${this.recordId}
            Contracting Party - ${this.contractParty}
            Category - ${this.contractCategory}
            Subcategory - ${this.contractSubcategory}

            From
            Name: ${this.name}
            Email: ${this.email}
            Phone: ${this.phone}`;
        }
    }

    sendRequest(event) {
        const type = event.target.dataset.id;

        if (
            (type === "Election" && !this.electIsSent) ||
            (type === "More Information" && !this.infoIsSent)
        ) {
            this.composeEmail(type);

            if (this.subject && this.message) {
                this.send(type);
            }
        } else {
            this.showToastMessage("info", this.LABELS.REQUEST_DUPLICATE_MSG);
        }
    }

    send(type) {
        sendEmail({ subject: this.subject, message: this.message })
            .then((result) => {
                if (result) {
                    if (type === "Election") {
                        this.electIsSent = true;
                    } else if (type === "More Information") {
                        this.infoIsSent = true;
                    }

                    this.showToastMessage(
                        "success",
                        this.LABELS.REQUEST_SUCCESS_MSG
                    );
                }
            })
            .catch((error) => {
                this.showToastMessage("error", error.body.message);
            });
    }

    goToItemPricingReport() {
        window.open(
            `/s/report/${this.reportId}/item-pricing-custom-report?reportFilters=%5B%7B"operator"%3A"equals"%2C"value"%3A"
            ${this.contractName}"%2C"column"%3A"Item_Pricing__c.Contract_Agreement__c.Name"%7D%5D`
        );
    }

    showToastMessage(variant, message) {
        const event = new ShowToastEvent({
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}