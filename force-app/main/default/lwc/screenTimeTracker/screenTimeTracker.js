// screenTimeTracker.js
import { LightningElement, api, wire } from "lwc";
import USER_ID from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/User.Name";
import STATUS_FIELD from "@salesforce/schema/Case.Status";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ScreenTimeTracker extends NavigationMixin(
    LightningElement
) {
    @api recordId;
    userName;
    caseStatus;
    screenTimeData = [];
    sortBy = "";
    sortDirection = "asc";
    totalDuration = 0;
    currentUserDuration = 0;
    currentUserLive = 0;
    liveTimer = "00:00:00";
    currentSessionTimer = "00:00:00";
    sessionStart;
    interval;

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
            const newStatus = data.fields.Status.value;
            if (newStatus !== this.caseStatus) {
                this.caseStatus = newStatus;
                const shouldStop = [
                    "Closed",
                    "On Hold",
                    "Awaiting Requirements",
                ].includes(newStatus);
                if (shouldStop) {
                    if (this.interval) {
                        clearInterval(this.interval);
                        this.interval = null;
                    }
                    this.currentSessionTimer = "";
                    this.liveTimer = this.totalDurationFormatted;
                    this.fetchScreenTime();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Session Ended",
                            message:
                                "Timer stopped and data refreshed due to Case status change.",
                            variant: "info",
                        })
                    );
                    this.fetchScreenTime();
                } else {
                    if (!this.interval) {
                        this.sessionStart = Date.now();
                        this.startLiveTimer();
                    }
                }
            }
        }
    }

    connectedCallback() {
        this._unloadHandler = () => this.captureSessionEnd(true);
        this._navHandler = () => this.captureSessionEnd(true);
        window.addEventListener("beforeunload", this._unloadHandler);
        window.addEventListener("popstate", this._navHandler);
        window.addEventListener("unload", this.captureSessionEnd);
        // Removed visibilitychange listener to allow timer to continue when tab is not in focus
        this.sessionStart = Date.now();
        this.fetchScreenTime();
        this.startLiveTimer();
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

    get totalDurationFormatted() {
        const current = this.currentSessionTimer
            ? Math.floor((Date.now() - this.sessionStart) / 1000)
            : 0;
        return this.formatDuration(this.totalDuration + current);
    }

    get currentUserDurationFormatted() {
        return this.currentUserDuration > 0
            ? this.formatDuration(this.currentUserDuration)
            : null;
    }

    get currentUserLiveFormatted() {
        const current = this.currentSessionTimer
            ? Math.floor((Date.now() - this.sessionStart) / 1000)
            : 0;
        return this.formatDuration(this.currentUserDuration + current);
    }

    async fetchScreenTime() {
        fetch(
            `https://aun73fj9z8.execute-api.us-east-1.amazonaws.com/prod/?ObjectID=${this.recordId}`
        )
            .then((response) => response.json())
            .then((res) => {
                this.totalDuration = 0;
                this.currentUserDuration = 0;
                const rows = res.map((r, idx) => {
                    this.totalDuration += r.Duration;
                    if (r.CSRUserID === USER_ID) {
                        this.currentUserDuration += r.Duration;
                    }
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
            });
    }

    captureSessionEnd = async (isFinal = false) => {
        if (!this.recordId || !this.userName) return;
        const end = Math.floor(Date.now() / 1000);
        const start = Math.floor(this.sessionStart / 1000);
        const duration = end - start;
        if (duration < 1) return;

        const payload = {
            ObjectID: this.recordId,
            ObjectType: this.getObjectTypeFromId(this.recordId),
            CSRUserID: USER_ID,
            CSRUserName: this.userName,
            StartTime: start,
            EndTime: end,
            IsManual: false,
        };

        try {
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
            console.warn("Session end POST failed", e);
        }

        this.sessionStart = Date.now();
        await this.fetchScreenTime();
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
