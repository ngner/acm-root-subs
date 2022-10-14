#!/bin/bash

#This script will deploy the root subscriptions into the namespaces using the service account for that namespace


# list of environemnt names 
ENVIRONMENTS="production preprod dev"

if [ "$(oc auth can-i '*' '*')" != "yes" ]; then
  echo "You need to be a cluster admin to run this script"
  exit 1
fi

CLUSTER=$(oc project | sed -r "s/.*(api[\.a-z0-9]+:[0-9]+).*/\1/")

echo "Current user is : $(oc whoami)"
echo "Target cluster is : ${CLUSTER}"
echo "current user should be you"
read -p "Continue (y/n)?" CONT
if [ "$CONT" = "y" ]; then
  echo "continuing";
else
  exit 1;
fi


for envname in $ENVIRONMENTS
do
    echo "=============== $envname ==============="
    # grab the service accounts token
    TKN=$(oc serviceaccounts -n "${envname}-acm-sub" get-token "$envname"-subscription-owner)
    # set the KUBECONFIG to a temp path relating to the environment
    KC=~/.kube/tmp-"$envname"-kubeconfig
    # delete any temp kubeconfig used in the past
    #TODO - not causing issue without it at present
    
    # login using the token and service account name (which caches the token to KUBECONFIG path above)
    oc --kubeconfig="${KC}" login "https://${CLUSTER}" --token="${TKN}"
    echo "current user is :  " $(oc --kubeconfig="${KC}" whoami)""
    
    # switch to environment namespace
    oc --kubeconfig="${KC}" project "$envname"-acm-sub
    # apply the resources via the kustomize for that environment
    oc --kubeconfig="${KC}" apply -k ./"${envname}"
    #eval oc apply -f managedclustersetbindings.yaml
    rm -v "${KC}"
    echo
done
