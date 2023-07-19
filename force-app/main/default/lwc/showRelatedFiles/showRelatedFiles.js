import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getRelatedFiles from "@salesforce/apex/ShowRelatedFilesController.getRelatedFiles";

export default class ShowRelatedFiles extends NavigationMixin(
    LightningElement
) {
    @api recordId;

    files;
    filesNumber = 0;

    @wire(getRelatedFiles, { contractId: "$recordId" })
    load({ error, data }) {
        if (data) {
            this.files = this.modifyFields(data);
            this.filesNumber = this.files.length;
        } else if (error) {
            this.showToast("error", error.body.message);
        }
    }

    modifyFields(data) {
        const files = data.map((file) => {
            const date = file.ContentModifiedDate;
            const size = file.ContentSize;
            const type = file.FileExtension;
            return {
                ...file,
                ContentModifiedDate: date ? this.parseDate(date) : "",
                ContentSize: size ? this.parseSize(size) : "",
                Icon: type ? this.selectIcon(type) : ""
            };
        });

        return files;
    }

    parseDate(date) {
        const dateVar = new Date(date);
        let dateArr = dateVar.toDateString().split(" ");
        return `${dateArr[1]} ${dateArr[2]}, ${dateArr[3]}`;
    }

    parseSize(size) {
        const sizeVar = parseInt(size);
        let result;
        if (sizeVar / 1000000 >= 1) {
            result = sizeVar / 1000000 + " MB";
        } else if (sizeVar / 1000 >= 1) {
            result = sizeVar / 1000 + " KB";
        } else {
            result = sizeVar + " Bytes";
        }
        return result;
    }

    selectIcon(type) {
        let icon = "doctype:unknown";
        if (type === "doc" || type === "docx") {
            icon = "doctype:word";
        } else if (type === "pdf") {
            icon = "doctype:pdf";
        } else if (type === "xls" || type === "xlsx") {
            icon = "doctype:excel";
        } else if (type === "png" || type === "jpg" || type === "jpeg") {
            icon = "doctype:image";
        }
        return icon;
    }

    handleFileClick(event) {
        const targetId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: targetId,
                actionName: "view"
            }
        });
    }

    showToast(variant, message) {
        const event = new ShowToastEvent({
            message: message,
            variant: variant
        });

        this.dispatchEvent(event);
    }
}