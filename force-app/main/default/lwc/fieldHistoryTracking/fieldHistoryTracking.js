import { LightningElement, api, wire, track } from "lwc";
import getFieldHistoryTrackingData from "@salesforce/apex/FieldHistoryTrackingController.getFieldHistoryTrackingData";

export default class FieldHistoryTracking extends LightningElement {
    @api recordId; // The record ID passed from the parent component or record page
    @track fieldHistoryData = [];
    @track error;

    // Define columns for the lightning-datatable
    columns = [
        {
            label: "Change Date",
            fieldName: "changeDate",
            type: "date",
            typeAttributes: {
                year: "numeric",
                month: "2-digit",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
                hour12: true,
            },
        },
        { label: "Action", fieldName: "action" },
        { label: "Field Name", fieldName: "fieldName" },
        { label: "Original Value", fieldName: "originalValue" },
        { label: "New Value", fieldName: "newValue" },
        { label: "User Name", fieldName: "userName" },
    ];

    // Wire the Apex method to retrieve field history tracking data based on recordId
    @wire(getFieldHistoryTrackingData, { objectId: "$recordId" })
    wiredHistoryData({ error, data }) {
        if (data) {
            this.fieldHistoryData = this.parseChangeEvents(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.fieldHistoryData = [];
        }
    }

    // Parse Change_Event__c JSON data and flatten it
    parseChangeEvents(data) {
        const parsedData = [];
        data.forEach((record) => {
            if (record.ChangeEvent) {
                // Parse JSON from ChangeEvent
                const changes = JSON.parse(record.ChangeEvent);

                // Flatten each change into a row with fieldName, originalValue, and newValue
                changes.forEach((change) => {
                    parsedData.push({
                        fieldName: change.fieldName,
                        originalValue: change.originalValue,
                        newValue: change.newValue,
                        action: record.Action,
                        changeDate: record.ChangeDate,
                        userId: record.UserId,
                        userName: record.UserName,
                    });
                });
            }
        });
        return parsedData;
    }
}