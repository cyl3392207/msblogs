Login-AzureRmAccount


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

$group = Get-AzureRmResourceGroup -Name "Group" 

New-AzureRmPolicyAssignment -Name "appendcostcenternotags" -PolicyDefinition $tagPolicy[0] -Scope $group.Resourceid
New-AzureRmPolicyAssignment -Name "appendcostcenternoothertag" -PolicyDefinition $tagPolicy[1] -Scope $group.Resourceid
New-AzureRmPolicyAssignment -Name "denycostcentertagupdate" -PolicyDefinition $tagPolicy[2] -Scope $group.Resourceid


$resources = Find-AzureRmResource -ResourceGroupName $group.ResourceGroupName 

foreach($r in $resources)
{
     try{
         $r | Set-AzureRmResource -Tags ($a=if($_.Tags -eq $NULL) { @{}} else {$_.Tags}) -Force -UsePatchSemantics
     }
     catch{
         Write-Host  $r.ResourceId + "can't be updated"
     }
}


Find-AzureRmResource -ResourceGroupName $group.ResourceGroupName  | Where-Object {$_.ResourceType -ne "microsoft.insights/alertrules"}| Set-AzureRmResource -Tags ($a=if($_.Tags -eq $NULL) { @{}} else {$_.Tags}) -Force -UsePatchSemantics
