({
    init: function (cmp, event, helper) {
        // Set one column for the aura databable which is URL
        cmp.set('v.columns', [
            { label: 'URL', fieldName: 'url', type: 'text'}
        ]);
    },
    
    handleUploadFinished: function (cmp, event, helper) {
       	helper.scanUrlsInFileInHelper(cmp, event);
    }
})