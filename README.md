# Salesforce Url Scanner
Check all orgs
> sfdx force:org:list


Login to dev hub
> sfdx auth:web:login -d -a DevHub


Create scratch org
> sfdx force:org:create -s -f config/project-scratch-def.json -a "urlScannerScratchOrg" 


Push to scratch org
> sfdx force:source:push -u urlScannerScratchOrg


Open specific scratch org
> sfdx force:org:open -u urlScannerScratchOrg


Delete scratch org
> sfdx force:org:delete -u urlScannerScratchOrg
