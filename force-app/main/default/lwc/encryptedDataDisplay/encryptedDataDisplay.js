import { LightningElement, api, wire } from "lwc";
import getDecryptedFields from "@salesforce/apex/EncryptedDataDisplayController.getDecryptedFields";

export default class EncryptedDataDisplay extends LightningElement {
    @api recordId;
    @api objectApiName;
    decryptedFields = [];
    showDecrypted = false; // Track whether decrypted data is visible

    @wire(getDecryptedFields, {
        recordId: "$recordId",
        objectName: "$objectApiName",
    })
    wiredDecryptedFields({ error, data }) {
        if (data) {
            this.decryptedFields = data.map((field) => ({
                label: field.label,
                value: field.value,
            }));
        } else if (error) {
            console.error("Error retrieving decrypted fields:", error);
        }
    }

    get toggleButtonLabel() {
        return this.showDecrypted
            ? "Hide Decrypted Data"
            : "Show Decrypted Data";
    }

    handleToggle() {
        this.showDecrypted = !this.showDecrypted;
    }

    handleMouseOver(event) {
        const targetLabel = event.currentTarget.dataset.label;
        const tooltip = this.template.querySelector(
            `.slds-popover[data-label="${targetLabel}"]`
        );
        if (tooltip) {
            tooltip.classList.remove("slds-hide");
        }
    }

    handleMouseOut(event) {
        const targetLabel = event.currentTarget.dataset.label;
        const tooltip = this.template.querySelector(
            `.slds-popover[data-label="${targetLabel}"]`
        );
        if (tooltip) {
            tooltip.classList.add("slds-hide");
        }
    }
}