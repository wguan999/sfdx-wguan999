import { LightningElement, api, wire, track } from "lwc";
import getDecryptedFields from "@salesforce/apex/EncryptedDataDisplayController.getDecryptedFields";
import { refreshApex } from "@salesforce/apex";

export default class EncryptedDataDisplay extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track decryptedFields = [];
    @track showDecrypted = false;
    wiredDecryptedFields; // Stores the wired response for refreshing

    @wire(getDecryptedFields, {
        recordId: "$recordId",
        objectName: "$objectApiName",
    })
    wiredData(result) {
        this.wiredDecryptedFields = result; // Store response for refresh
        if (result.data) {
            this.decryptedFields = result.data.map((field) => ({
                label: field.label,
                value: field.value,
            }));
        } else if (result.error) {
            console.error("Error retrieving decrypted fields:", result.error);
        }
    }

    get toggleButtonLabel() {
        return this.showDecrypted
            ? "Hide Decrypted Data"
            : "Show Decrypted Data";
    }

    handleToggle() {
        this.showDecrypted = !this.showDecrypted;

        // Force refresh when toggling ON
        if (this.showDecrypted) {
            refreshApex(this.wiredDecryptedFields);
        }
    }
}