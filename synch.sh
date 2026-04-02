#!/bin/bash

SUB="677e2d5a-d22d-4537-8077-3a8357035660"

RG_SE="rg-sweden-central"
RG_CH="rg-switzerland-north"

# NICs
terraform import module.sweden.azurerm_network_interface.nic[0] \
"/subscriptions/$SUB/resourceGroups/$RG_SE/providers/Microsoft.Network/networkInterfaces/nic-se-0"

terraform import module.sweden.azurerm_network_interface.nic[1] \
"/subscriptions/$SUB/resourceGroups/$RG_SE/providers/Microsoft.Network/networkInterfaces/nic-se-1"

terraform import module.switzerland.azurerm_network_interface.nic[0] \
"/subscriptions/$SUB/resourceGroups/$RG_CH/providers/Microsoft.Network/networkInterfaces/nic-ch-0"

terraform import module.switzerland.azurerm_network_interface.nic[1] \
"/subscriptions/$SUB/resourceGroups/$RG_CH/providers/Microsoft.Network/networkInterfaces/nic-ch-1"
