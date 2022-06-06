({
	scanUrlsInFileInHelper : function(cmp, event) {
        // call action from the APEX controller UrlScannerController
        var action = cmp.get("c.fetchUrlsAndTheirStatuses");
        var caseId = cmp.get("v.recordId");
        
        action.setParams({
            caseId : caseId
        });
        
        action.setCallback(this, function(response){
            // Init toast to display success message
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();
            
            if(state === "SUCCESS") {
                var data = response.getReturnValue();
                
                // Populate data from the response of UrlScannerController APEX, which is a map where the key is 'url' and the results are the urls of said method
                cmp.set("v.data", data.list);
                
                // showList by default is false, and is only set as true when the state of this action is success to show the datatable only after attaching a file to the case
                // If the file surpasses the limit of 1000000 characters, don't show any results, but keep the file attached
                if(!data.moreThanThresholdChars) {
                    cmp.set("v.showList", true);
                }
                cmp.set("v.isConnected", data.connectedToIPQ);
                cmp.set("v.moreThanThresholdChars", data.moreThanThresholdChars);
                cmp.set("v.loaded", false);
                
                // Set one column for the aura databable which is URL
                var columns = [{ label: 'URL', fieldName: 'url', type: 'text'}];
                if(data.connectedToIPQ) {
                    columns.push({ label: 'Status', fieldName : 'status', type: 'text'});
                }
                cmp.set('v.columns', columns);
                
                if(!data.status) {
                    toastEvent.setParams({
                        "type": "success",
                        "title" : "Success",
                        "message" : "File is attached to the case succesfully"
                    });
                }
                else {
                    toastEvent.setParams({
                        "type": "error",
                        "title" : "Malicious file",
                        "message" : "File attached contains malicious urls and will be deleted from this case"
                    });
                }
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
	}
});