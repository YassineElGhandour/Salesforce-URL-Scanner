# Salesforce Url Scanner
// check all orgs
> sfdx force:org:list

// Login to dev hub
> sfdx auth:web:login -d -a DevHub

// create scratch org
> sfdx force:org:create -s -f config/project-scratch-def.json -a "urlScannerScratchOrg" 

// push to scratch org
> sfdx force:source:push -u urlScannerScratchOrg

// open specific scratch org
> sfdx force:org:open -u urlScannerScratchOrg

// delete scratch org
> sfdx force:org:delete -u urlScannerScratchOrg
