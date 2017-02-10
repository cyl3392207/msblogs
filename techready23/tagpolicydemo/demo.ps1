Login-AzureRmAccount

$group = Get-AzureRmResourceGroup -Name "Group" 

$resources = Find-AzureRmResource -ResourceGroupName $group.ResourceGroupName 


$tagPolicy = @()
$tagPolicy+=New-AzureRmPolicyDefinition -Name appendcostCenternotag -DisplayName "Append Cost Center Tag (no tag)" -Policy '{
  "if": {
    "field": "tags",
    "exists": "false"
  },
  "then": {
    "effect": "append",
    "details": [
      {
        "field": "tags",
        "value": {
          "costCenter": "myDepartment"
        }
      }
    ]
  }
}'

$tagPolicy+= New-AzureRmPolicyDefinition -Name appendcostCenterothertag -DisplayName "Append Cost Center Tag (other tag)" -Policy '{
  "if": {
    "allOf": [
      {
        "field": "tags",
        "exists": "true"
      },
      {
        "field": "tags.costCenter",
        "exists": "false"
      }
    ]
  },
  "then": {
    "effect": "append",
    "details": [
      {
        "field": "tags.costCenter",
        "value": "myDepartment"
      }
    ]
  }
}'

$tagPolicy+= New-AzureRmPolicyDefinition -Name denyifnocostCenter -DisplayName "Block updates for cost center tag" -Policy '
{
  "if": {
    "not": {
      "field": "tags.costCenter",
      "equals": "myDepartment"
    }
  },
  "then": {
    "effect": "deny"
  }
}'


New-AzureRmPolicyAssignment -Name "appendcostcenternotags" -PolicyDefinition $tagPolicy[0] -Scope $group.Resourceid
New-AzureRmPolicyAssignment -Name "appendcostcenternoothertag" -PolicyDefinition $tagPolicy[1] -Scope $group.Resourceid
New-AzureRmPolicyAssignment -Name "denycostcentertagupdate" -PolicyDefinition $tagPolicy[2] -Scope $group.Resourceid


# relogin to refresh the token, so that policy cache are refreshed. There is a up to 30 minutes delay since policy cache will be refrehsed every 30 minutes. Relogin can refrehh the cache
Login-AzureRmAccount

# Verify cost center tags are appended, even the request doesn't contains cost center tag
New-AzureRmStorageAccount -ResourceGroupName $group.ResourceGroupName -Name ("tsaccc" + (Get-Random -Minimum 1 -Maximum 1000)) -SkuName Standard_LRS -Location westus -Kind Storage


# applying a patch for existing resources  
foreach($r in $resources)
{
     try{
         $r | Set-AzureRmResource -Tags ($a=if($_.Tags -eq $NULL) { @{}} else {$_.Tags}) -Force -UsePatchSemantics
     }
     catch{
         Write-Host  $r.ResourceId + "can't be updated"
     }
}

# clean up after the demo

Get-AzureRMPolicyAssignment -Scope $Group.ResourceId | Remove-AzureRmPolicyAssignment -Scope $group.ResourceId

# relogin to refresh the token, so that policy cache are refreshed.
Login-AzureRmAccount


foreach($r in $resources)
{
     try{
         $r | Set-AzureRmResource -Tag @{} -Force 
     }
     catch{
         Write-Host  $r.ResourceId + "can't be updated"
     }
}
