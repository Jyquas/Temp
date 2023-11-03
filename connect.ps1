function Connect-ToSites {
    param (
        [string]$sourceSiteUrl,
        [string]$targetSiteUrl
    )

    $cred = Get-Credential
    
    $sourceCtx = Connect-PnPOnline -Url $sourceSiteUrl -Credentials $cred -ReturnConnection
    $targetCtx = Connect-PnPOnline -Url $targetSiteUrl -Credentials $cred -ReturnConnection
    
    return $sourceCtx, $targetCtx
}
