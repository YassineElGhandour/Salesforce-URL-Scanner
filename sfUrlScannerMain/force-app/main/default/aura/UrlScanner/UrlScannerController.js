({
    init: function (cmp, event, helper) {
    	// Init with empty
    },
    
    handleClick: function (cmp, event) {
        cmp.set('v.loaded', true);
    },
    
    handleUploadFinished: function (cmp, event, helper) {
       	helper.scanUrlsInFileInHelper(cmp, event);
    }
})