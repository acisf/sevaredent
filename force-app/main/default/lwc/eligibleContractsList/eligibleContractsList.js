import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getContracts from "@salesforce/apex/EligibleContractsListController.getContracts";
import searchContracts from "@salesforce/apex/EligibleContractsListController.searchContracts";

import ACCOUNT from "@salesforce/label/c.Elected_Contract_lst_Account";
import CATEGORY from "@salesforce/label/c.Elected_Contract_lst_Category";
import CONTRACT_AGREEMENT from "@salesforce/label/c.Elected_Contract_lst_Contract_Agreement";
import EFFECTIVE_DATE from "@salesforce/label/c.Elected_Contract_lst_Effective_Date";
import EXPIRATION_DATE from "@salesforce/label/c.Elected_Contract_lst_Expiration_Date";
import LIST_NAME from "@salesforce/label/c.Eligible_Contract_lst_name";
import LIST_OBJECT from "@salesforce/label/c.Elected_Contracts_lts_object";
import NO_RECORDS from "@salesforce/label/c.Elected_Contract_no_records_msg";
import SEVAREDENT_NUMBER from "@salesforce/label/c.Elected_Contract_lst_Sevaredent_Number";
import SUB_CATEGORY from "@salesforce/label/c.Elected_Contract_lst_Sub_Category";

export default class ElectedContractsList extends LightningElement {
    LABELS = {
        ACCOUNT,
        CATEGORY,
        CONTRACT_AGREEMENT,
        EFFECTIVE_DATE,
        EXPIRATION_DATE,
        LIST_NAME,
        LIST_OBJECT,
        NO_RECORDS,
        SEVAREDENT_NUMBER,
        SUB_CATEGORY
    };

    contracts;
    allContracts;

    searchTerm = "";
    columnOrderASC = [true, true, true, true, true, true, true];

    isMobile;

    @wire(getContracts)
    load({ data, error }) {
        if (data) {
            this.contracts = this.composeList(data);
            console.log(this.contracts);
            this.allContracts = this.contracts;
        } else if (error) {
            this.showToastMessage("error", error.body.message);
        }
    }

    connectedCallback() {
        this.isMobile = window.navigator.userAgent.toLowerCase().includes("mobile");
    }

    composeList(data) {
        let count = 1;
        const contracts = data.map((item) => {
            return {
                ...item,
                Account: item.APXT_Redlining__Account__r ? item.APXT_Redlining__Account__r.Name : '',
                Number: count++,
                URL: "contract-agreement/" + item.Id,
                FormattedEffectiveDate: item.APXT_Redlining__Effective_Date__c == null
                    ? ""
                    : this.composeDate(item.APXT_Redlining__Effective_Date__c),
                FormattedExpirationDate: item.APXT_Redlining__Expiration_Date__c == null
                    ? ""
                    : this.composeDate(item.APXT_Redlining__Expiration_Date__c)
            };
        });

        return contracts;
    }

    composeDate(date) {
        let parts = date.split("-");
        return parts.length < 3
            ? date
            : parts[1] + "/" + parts[2] + "/" + parts[0];
    }

    showToastMessage(variant, message) {
        const event = new ShowToastEvent({
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleSearch(event) {
        if (event.keyCode === 13) {
this.searchByTerm();
        }
    }

    searchByTerm() {
            const searchTerm =
                this.template.querySelector(".search-input").value;
            if (searchTerm === "") {
                this.contracts = this.allContracts;
            } else {
                this.search(searchTerm, null);
            }
    }

    search(searchTerm, sortBy) {
        searchContracts({ searchTerm: searchTerm, sortBy : sortBy })
                    .then((result) => {
                        this.contracts = this.composeList(result);
                    })
                    .catch((error) => {
                        this.showToastMessage("error", error.body.message);
                    });
    }

    changeOrder(event) {
        const column = event.target.dataset.id;
        this.reorderColumns(column);

        const fieldName = event.target.dataset.name;
        const order = this.columnOrderASC[column] ? "ASC" : "DESC";
        const searchTerm =
                this.template.querySelector(".search-input").value;
        let sortBy = `${fieldName} ${order}`;

        this.search(searchTerm, sortBy);
    }

    reorderColumns(column) {
        let count = 0;
        let temp = [];
        this.columnOrderASC.forEach(columnASC => {
            if (count == column) {
                temp[count] = !columnASC;
            } else {
            temp[count] = true;
            }
            count++;
        });
        this.columnOrderASC = temp;
    }
}