import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";

import USER_ID from "@salesforce/user/Id";
import ACCOUNT_FIELD from "@salesforce/schema/User.AccountId";
import NAME_FIELD from "@salesforce/schema/User.Name";
import EMAIL_FIELD from "@salesforce/schema/User.Email";
import PHONE_FIELD from "@salesforce/schema/User.Phone";

import getAccountName from "@salesforce/apex/RequestToElectController.getAccountName";
import sendEmail from "@salesforce/apex/SendEmailController.sendEmail";

import MESSAGE from "@salesforce/label/c.ContactUsMessagelabel";
import SEND from "@salesforce/label/c.ContactUsSendBtn";
import SUBJECT from "@salesforce/label/c.ContactUsSubjectlabel";
export default class SendEmail extends NavigationMixin(LightningElement) {
    LABELS = {
        MESSAGE,
        SEND,
        SUBJECT
    };

    userId = USER_ID;
    name;
    email;
    phone;
    account;
    accountId;

    isSent = false;

    subject;
    message;

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

    handleClick() {
        this.getData();
        if (this.subject && this.message) {
            this.send();
        }
    }

    getData() {
        this.subject = `Contact Us Form - ${
            this.template.querySelector(".email-subject").value
        }`;
        this.message = `
        ${this.template.querySelector(".email-message").value}
        
        From
        Account Name - ${this.account}, ID: ${this.accountId}
        Name: ${this.name}
        Email: ${this.email}
        Phone: ${this.phone}`;
    }

    send() {
        if (!this.isSent) {
            sendEmail({ subject: this.subject, message: this.message })
                .then((result) => {
                    if (result) {
                        this.goToThankYouPage();
                        this.clearData();
                    }
                })
                .catch((error) => {
                    this.showToastMessage("error", error.body.message);
                });
            this.isSent = true;
        }
    }

    clearData() {
        this.subject = null;
        this.message = null;
    }

    goToThankYouPage() {
        this[NavigationMixin.Navigate](
            {
                type: "standard__webPage",
                attributes: {
                    url: "/contact-us-thank-you"
                }
            },
            true
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