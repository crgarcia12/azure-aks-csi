function New-CsiAksRegistration
{
    az feature register --namespace "Microsoft.ContainerService" --name "EnableAzureDiskFileCSIDriver"
    az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableAzureDiskFileCSIDriver')].{Name:name,State:properties.state}"
    az provider register --namespace Microsoft.ContainerService

    # Install the aks-preview extension
    az extension add --name aks-preview
    az extension update --name aks-preview
}

function Set-CsiAksEnvironmentVariables
{
    New-Variable -Name $Environment     -Value "crgar-aks-csi" -Scope Global
    New-Variable -Name $ResourceGroup   -Value "$Environment-rg" -Scope Global
    New-Variable -Name $Location        -Value  "westeurope" -Scope Global
    New-Variable -Name $ClusterName     -Value "$Environment-cluster" -Scope Global
}

function New-CsiAksCluster
{
    az group create --name $ResourceGroup --location $Location
    az aks create -g $ResourceGroup -n $ClusterName --network-plugin azure -k 1.17.9 --aks-custom-headers EnableAzureDiskFileCSIDriver=true
    
}

function New-CsiAksApplicationDeployment
{
    az aks get-credentials -g $ResourceGroup -n $ClusterName 
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/pvc-azurefile-csi.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/nginx-pod-azurefile.yaml
    
    kubectl exec nginx-azurefile -- ls -l /mnt/azurefile
}