import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getImplementations from "@salesforce/apex/ContractImplementedMarkCtrl.getImplementations";

import IMPLEMENTED from "@salesforce/label/c.ContractAgreementImplementationMarkLabel";

export default class ContractImplementedMark extends LightningElement {
    LABELS = {
        IMPLEMENTED
    };

    @api recordId;

    date = "";
    isImplemented = false;

    @wire(getImplementations, { contractId: "$recordId" })
    load({ data, error }) {
        if (data && data[0]) {
            this.date =
                data[0].Effective_Date__c == null
                    ? ""
                    : this.composeDate(data[0].Effective_Date__c);
            this.isImplemented = true;
        } else if (error) {
            this.showToast("error", error.body.message);
        }
    }

    showToast(variant, message) {
        const event = new ShowToastEvent({
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    composeDate(date) {
        let parts = date.split("-");
        return parts.length < 3
            ? date
            : parts[1] + "/" + parts[2] + "/" + parts[0];
    }
}