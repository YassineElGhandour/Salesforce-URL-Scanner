({
    init: function (cmp, event, helper) {
    	// Init with empty
    },
    
    handleUploadFinished: function (cmp, event, helper) {
        cmp.set('v.loaded', true);
       	helper.scanUrlsInFileInHelper(cmp, event);
    }
})