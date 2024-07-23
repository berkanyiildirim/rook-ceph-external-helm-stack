#!/bin/bash
# Bu script k8s kümesinde rook-ceph-external kurulumunu kaldırmak için kullanılır.

echo
echo "########################   csi-addons siliniyor...   ########################"
cd deploy/kubernetes-csi-addons-v0.8.0/deploy/controller
kubectl delete -f rbac-external.yaml -f crds.yaml -f csi-addons-config-external.yaml -f setup-controller-external.yaml  --ignore-not-found=true

echo
echo "########################   csi-addons finalizer'ları kaldırılıyor...   ########################"
csiaddonsnodes=$(kubectl get Csiaddonsnodes -n rook-ceph-external -o=name)
for csiaddonsnode in $csiaddonsnodes; do
    echo "Finalizer'ı temizleniyor: $csiaddonsnode"
    kubectl patch $csiaddonsnode --type merge -p '{"metadata":{"finalizers":[]}}' -n rook-ceph-external
done
echo "Tüm Csiaddonsnodes nesnelerinin finalizer'ları temizlendi."

echo "########################  rook-ceph-external CRD'leri siliniyor...   ########################"
cd ../../../ceph-external/
kubectl delete -f ceph-cluster-external.yaml -f common-external.yaml -f  ceph-operator-external.yaml -f common.yaml  -f crds.yaml --ignore-not-found=true

echo "########################   CephCluster siliniyor. Veriler kalıcı olarak silinecek...   ########################"
kubectl -n rook-ceph-external patch cephcluster rook-ceph-external --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
kubectl -n rook-ceph-external delete cephcluster rook-ceph-external &

echo "########################   role=storage-node labelları siliniyor   ########################"
kubectl get nodes --selector='role=storage-node' --no-headers=true | awk '{print $1}' | xargs -I {} kubectl label node {} role-

echo "########################  Storage Class'lar siliniyor   ########################"
kubectl delete sc ceph-rbd
kubectl delete sc cephfs

echo "########################   rook-ceph-external CRD'lerin finalizer'ları kaldırılıyor...   ########################"
for CRD in $(kubectl get crd -n rook-ceph-external | awk '/ceph.rook.io/ {print $1}'); do
    kubectl get -n rook-ceph-external "$CRD" -o name | \
    xargs -I {} kubectl patch -n rook-ceph-external {} --type merge -p '{"metadata":{"finalizers": []}}'
done
kubectl -n rook-ceph-external patch configmap rook-ceph-mon-endpoints --type merge -p '{"metadata":{"finalizers": []}}'
kubectl -n rook-ceph-external patch secrets rook-ceph-mon --type merge -p '{"metadata":{"finalizers": []}}'

echo "############################################################################################################"

echo "Aşağıdaki komut manuel çalıştırılarak operatorün tüm kaynaklarının silindiği doğrulanır."
echo "kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n rook-ceph-external"
echo "Namespace Terminating statede kaldıysa yukarıdaki komut çıktısındaki kaynakların finalizer'ları silinir"
echo "Örnek:"
echo "kubectl -n rook-ceph-external patch configmap rook-ceph-mon-endpoints --type merge -p '{\"metadata\":{\"finalizers\": []}}'"
echo "kubectl -n rook-ceph-external patch secrets rook-ceph-mon --type merge -p '{\"metadata\":{\"finalizers\": []}}'"
echo "##########################################   İşlem tamamlandı.    ##########################################"
