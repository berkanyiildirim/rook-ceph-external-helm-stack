#!/bin/bash
# Script k8s kümesinde ceph-external kurulumu yaparak harici Rook-Ceph kümesine bağlar.

echo "########################   Uygun dizine geçiliyor...   ########################"
cd deploy/ceph-external/

echo
echo "########################    Ortak yapılandırma oluşturuluyor...   ########################"
kubectl apply -f common.yaml

echo
echo "########################    CRD'ler oluşturuluyor...   ########################"
kubectl apply -f crds.yaml

echo
echo "########################   Operator oluşturuluyor...   ########################"
kubectl apply -f ceph-operator-external.yaml

echo
echo "########################    Ortak external yapılandırması oluşturuluyor...   ########################"
kubectl apply -f common-external.yaml

echo
echo "########################   Cluster oluşturuluyor...   ########################"
kubectl apply -f ceph-cluster-external.yaml

echo
echo "########################   csi-addons CRD yükleniyor...   ########################"
cd ../../kubernetes-csi-addons-v0.8.0/deploy/controller
kubectl apply -f crds.yaml

echo
echo "########################   csi-addons rbac yükleniyor...   ########################"
kubectl apply -f rbac-external.yaml

echo
echo "########################   csi-addons yükleniyor...   ########################"
kubectl apply -f setup-controller-external.yaml

echo
echo "########################   csi-addons konfigurasyonları yapılıyor...   ########################"
kubectl apply -f csi-addons-config-external.yaml

echo
echo
echo "####################################################################################"
echo "########################    rook-ceph-external kurulumu tamamlandı   ########################"
