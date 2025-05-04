// screenTimeTracker.js
import { LightningElement, api, wire } from "lwc";
import USER_ID from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/User.Name";
import STATUS_FIELD from "@salesforce/schema/Case.Status";

import { NavigationMixin } from "lightning/navigation";

export default class ScreenTimeTracker extends NavigationMixin(
    LightningElement
) {
    @api recordId;
    userName;
    caseStatus;
    screenTimeData = [];
    sortBy = "";
    sortDirection = "asc";
    columns = [
        {
            label: "Agent",
            fieldName: "csrUserUrl",
            type: "url",
            sortable: true,
            typeAttributes: {
                label: { fieldName: "csrUserName" },
                target: "_blank",
                tooltip: { fieldName: "csrUserName" },
            },
        },
        {
            label: "Date",
            fieldName: "startTimeFormatted",
            type: "text",
            sortable: true,
        },
        {
            label: "Duration",
            fieldName: "durationFormatted",
            type: "text",
            sortable: true,
        },
    ];
    totalDuration = 0;
    liveTimer = "00:00:00";
    get totalDurationFormatted() {
        return this.formatDuration(this.totalDuration);
    }
    currentSessionTimer = "00:00:00";
    sessionStart;
    interval;

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else {
            this.userName = "Unknown";
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STATUS_FIELD] })
    wiredCase({ error, data }) {
        if (data) {
            this.caseStatus = data.fields.Status.value;
        }
    }

    connectedCallback() {
        this._unloadHandler = () => this.captureSessionEnd(true);
        this._navHandler = () => this.captureSessionEnd(true);
        window.addEventListener("beforeunload", this._unloadHandler);
        window.addEventListener("popstate", this._navHandler);
        window.addEventListener("unload", this.captureSessionEnd);
        this.sessionStart = Date.now();
        // fetchScreenTime will start timer conditionally
        this.fetchScreenTime();
        window.addEventListener("beforeunload", this.captureSessionEnd);
        document.addEventListener("visibilitychange", this.captureSessionEnd);
    }

    disconnectedCallback() {
        window.removeEventListener("beforeunload", this._unloadHandler);
        window.removeEventListener("popstate", this._navHandler);
        clearInterval(this.interval);
    }

    startLiveTimer() {
        this.interval = setInterval(() => {
            const elapsed = Math.floor((Date.now() - this.sessionStart) / 1000);
            this.liveTimer = this.formatDuration(this.totalDuration + elapsed);
            this.currentSessionTimer = this.formatDuration(elapsed);
        }, 1000);
    }

    formatDuration(seconds) {
        const hrs = String(Math.floor(seconds / 3600)).padStart(2, "0");
        const mins = String(Math.floor((seconds % 3600) / 60)).padStart(2, "0");
        const secs = String(seconds % 60).padStart(2, "0");
        return `${hrs}:${mins}:${secs}`;
    }

    async fetchScreenTime() {
        fetch(
            `https://aun73fj9z8.execute-api.us-east-1.amazonaws.com/prod/?ObjectID=${this.recordId}`
        )
            .then((response) => response.json())
            .then((res) => {
                this.totalDuration = 0;
                const rows = res.map((r, idx) => {
                    this.totalDuration += r.Duration;
                    return {
                        id: idx,
                        csrUserName: r.CSRUserName,
                        csrUserUrl: `/lightning/r/User/${r.CSRUserID}/view`,
                        startTimeFormatted: new Date(
                            r.StartTime * 1000
                        ).toLocaleString(),
                        durationFormatted: this.formatDuration(r.Duration),
                    };
                });
                this.screenTimeData = this.sortData(
                    rows,
                    this.sortBy,
                    this.sortDirection
                );

                if (
                    this.getObjectTypeFromId(this.recordId) === "Case" &&
                    this.caseStatus === "Closed"
                ) {
                    if (this.interval) {
                        clearInterval(this.interval);
                        this.interval = null;
                    }
                    this.currentSessionTimer = "";
                } else if (!this.interval) {
                    this.startLiveTimer();
                }
            });
    }

    captureSessionEnd = async (isFinal = false) => {
        if (!this.recordId || !this.userName) return;

        const end = Math.floor(Date.now() / 1000);
        const start = Math.floor(this.sessionStart / 1000);
        const duration = end - start;
        if (duration < 1 || !this.userName) return;

        const payload = {
            ObjectID: this.recordId,
            ObjectType: this.getObjectTypeFromId(this.recordId),
            CSRUserID: USER_ID,
            CSRUserName: this.userName,
            StartTime: start,
            EndTime: end,
            IsManual: false,
        };
        if (isFinal) {
            try {
                // Fallback to synchronous fetch because sendBeacon is not available
                await fetch(
                    "https://aun73fj9z8.execute-api.us-east-1.amazonaws.com/prod/",
                    {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                        },
                        body: JSON.stringify(payload),
                        keepalive: true,
                    }
                );
            } catch (e) {
                console.warn("Final fetch failed", e);
            }
        } else {
            await fetch(
                "https://aun73fj9z8.execute-api.us-east-1.amazonaws.com/prod/",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify(payload),
                }
            );
            await this.fetchScreenTime();
        }

        this.sessionStart = Date.now();

        await this.fetchScreenTime();
        this.sessionStart = Date.now();
    };

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
        this.screenTimeData = this.sortData(
            [...this.screenTimeData],
            sortedBy,
            sortDirection
        );
    }

    sortData(data, field, direction) {
        if (!field) return data;
        const isAsc = direction === "asc";
        return data.sort((a, b) => {
            let valA = a[field];
            let valB = b[field];
            if (typeof valA === "string") valA = valA.toLowerCase();
            if (typeof valB === "string") valB = valB.toLowerCase();
            return (valA > valB ? 1 : valA < valB ? -1 : 0) * (isAsc ? 1 : -1);
        });
    }

    getObjectTypeFromId(id) {
        const keyPrefix = id.substring(0, 3);
        const map = {
            "001": "Account",
            "003": "Contact",
            500: "Case",
            "006": "Opportunity",
            800: "CustomObject",
        };
        return map[keyPrefix] || "Unknown";
    }
}

// Apex controller: ScreenTimeController.cls
// No longer used. Replaced by API Gateway calls.