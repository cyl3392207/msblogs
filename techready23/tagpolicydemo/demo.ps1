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

$yourowntag = @{ Environment="Test" } 

New-AzureRMStorageAccount -Name "fdsacdsa322fdasfdsa3cdxf" -ResourceGroupName $group.ResourceGroupName -SkuName Standard_LRS -Location westus -Tag $yourowntag

