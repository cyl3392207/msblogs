Login-AzureRmAccount

$group = New-AzureRmResourceGroup -Name "TestGroup" -Location westus


$tagPolicy = New-AzureRmPolicyDefinition -Name appendtagpolicyv2 -DisplayName "Append Tag and its Value"  -Policy '{
  "if": {
    "field": "[parameters(''tagName'')]",
    "exists": "false"
  },
  "then": {
    "effect": "append",
    "details": [
      {
        "field": "[parameters(''tagName'')]",
        "value": "[parameters(''tagValue'')]"
      }
    ]
  }
}' -Parameter '{
  "tagValue": {
    "type": "string",
    "metadata": {
      "description": "value of Tag"
    }
  },
  "tagName": {
    "type": "string",
    "metadata": {
      "description": "Name of Tag"
    }
  }
}'

New-AzureRmPolicyAssignment -Name "appendcostcenter" -PolicyDefinition $tagPolicy -Scope $group.Resourceid -tagName "tags.costCenter" -tagValue "00001"
New-AzureRmPolicyAssignment -Name "appendBONumber" -PolicyDefinition $tagPolicy -Scope $group.Resourceid -tagName "tags.BONumber" -tagValue "00002"
New-AzureRMStorageAccount -Name "fdsaffcdsv322dsdscdxf" -ResourceGroupName $group.ResourceGroupName -SkuName Standard_LRS -Location westus
