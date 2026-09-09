# Remote state so CI (GitHub Actions) and your local machine share the same
# state file instead of drifting apart. Create this storage account manually
# once (it can't create itself — chicken-and-egg problem with remote state),
# then fill in the values below.
#
# az group create -n tfstate-rg -l westeurope
# az storage account create -n <uniquename> -g tfstate-rg -l westeurope --sku Standard_LRS
# az storage container create -n tfstate --account-name <uniquename>

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "" # TODO: fill in after creating the storage account above
    container_name        = "tfstate"
    key                   = "cs1.terraform.tfstate"
  }
}
