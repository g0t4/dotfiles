"""Kubernetes abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr
from wes_misc_abbreviation_bridge import (
    fish_abbreviation,
)


FISH_FUNCTIONS = (
    '_k3s_autocomplete',  # Fish line 229
    'kgdump',  # Fish line 294
    '_abbr_kgv',  # Fish line 399
    'kdd',  # Fish line 446
    'kns',  # Fish line 531
    'dig',  # Fish line 576
    'helm_template_diff',  # Fish line 745
)


def register_kubernetes_abbreviations():
    abbr('k3s', 'sudo k3s')  # Fish line 220
    abbr('k3dls', 'k3d cluster list')  # Fish line 265
    abbr('k3dcreate', 'k3d cluster create')  # Fish line 266
    abbr('k3ddelete', 'k3d cluster delete')  # Fish line 267
    abbr('k3dedit', 'k3d cluster edit --port-add')  # Fish line 268
    abbr('k3dstart', 'k3d cluster start')  # Fish line 269
    abbr('k3dstop', 'k3d cluster stop')  # Fish line 270
    abbr('k3di', 'k3d image import')  # Fish line 272
    abbr('k3dn', 'k3d node list')  # Fish line 274
    abbr('k3dr', 'k3d registry list')  # Fish line 276
    abbr('oy', '-o yaml', position="anywhere", commands=('kubectl',))  # Fish line 283
    abbr('ow', '-o wide', position="anywhere", commands=('kubectl',))  # Fish line 284
    abbr('kg', 'kubectl get')  # Fish line 288
    abbr('kgf', 'kubectl get -f')  # Fish line 289
    abbr('kgns', 'kubectl get namespaces')  # Fish line 291
    abbr('kga', 'kubectl get all')  # Fish line 351
    abbr('kgaa', 'kubectl get all -A')  # Fish line 352
    abbr('kgas', 'kubectl get all --show-labels')  # Fish line 353
    abbr('kgb', 'kubectl get -A backups,snapshots')  # Fish line 354
    abbr('kgp', 'kubectl get pods')  # Fish line 356
    abbr('kgpa', 'kubectl get pods -A')  # Fish line 357
    abbr('kgpaw', 'kubectl get pods -A --watch')  # Fish line 358
    abbr('kgcm', 'kubectl get configmaps')  # Fish line 361
    abbr('kgcr', 'kubectl get clusterroles')  # Fish line 362
    abbr('kgcrb', 'kubectl get clusterrolebindings -o wide')  # Fish line 363
    abbr('kgcrd', 'kubectl get customresourcedefinitions')  # Fish line 364
    abbr('kgds', 'kubectl get daemonsets')  # Fish line 365
    abbr('kgep', 'kubectl get endpoints')  # Fish line 366
    abbr('kgepA', 'kubectl get endpoints -A')  # Fish line 367
    abbr('kgend', 'kubectl get svc,endpoints,endpointslices')  # Fish line 368
    abbr('kgev', 'kubectl get events')  # Fish line 369
    abbr('kging', 'kubectl get ingresses')  # Fish line 370
    abbr('kgj', 'kubectl get -A jobs,cronjobs')  # Fish line 371
    abbr('kgno', 'kubectl get nodes')  # Fish line 372
    abbr('kgpv', 'kubectl get persistentvolumes')  # Fish line 373
    abbr('kgpvc', 'kubectl get persistentvolumeclaims')  # Fish line 374
    abbr('kgr', 'kubectl get --raw /% | yq -P', cursor_marker="%")  # Fish line 376
    abbr('kgr/a', 'kubectl get --raw /apis')  # Fish line 378
    abbr('kgr/h', 'kubectl get --raw /healthz')  # Fish line 379
    abbr('kgr/l', 'kubectl get --raw /livez')  # Fish line 380
    abbr('kgr/m', 'kubectl get --raw /metrics')  # Fish line 381
    abbr('kgr/o', 'kubectl get --raw /openapi')  # Fish line 382
    abbr('kgr/r', 'kubectl get --raw /readyz')  # Fish line 384
    abbr('kgr/v', 'kubectl get --raw /version')  # Fish line 385
    abbr('kgrb', 'kubectl get rolebindings -o wide')  # Fish line 387
    abbr('kgro', 'kubectl get roles')  # Fish line 388
    abbr('kgrs', 'kubectl get replicasets')  # Fish line 389
    abbr('kgs', 'kubectl get svc')  # Fish line 390
    abbr('kgsa', 'kubectl get serviceaccounts')  # Fish line 391
    abbr('kgsc', 'kubectl get storageclasses')  # Fish line 392
    abbr('kgsecrets', 'kubectl get secrets')  # Fish line 393
    abbr('kgsts', 'kubectl get statefulsets')  # Fish line 394
    abbr('kgrev', 'kubectl get pods,sts,controllerrevisions')  # Fish line 395
    abbr('kgsvc', 'kubectl get services')  # Fish line 396
    abbr('kgv', fish_abbreviation('_abbr_kgv'))  # Fish line 398
    abbr('kaf', 'kubectl apply -f')  # Fish line 412
    abbr('kad', 'kubectl apply --dry-run=client -f')  # Fish line 413
    abbr('kak', 'kubectl apply -k .')  # Fish line 414
    abbr('kk', 'kubectl kustomize')  # Fish line 415
    abbr('kar', 'kubectl api-resources')  # Fish line 417
    abbr('kara', 'kubectl api-resources --api-group')  # Fish line 418
    abbr('karn', 'kubectl api-resources --namespaced=true')  # Fish line 419
    abbr('karg', 'kubectl api-resources --namespaced=false')  # Fish line 420
    abbr('kav', 'kubectl api-versions')  # Fish line 421
    abbr('kattach', 'kubectl attach -it')  # Fish line 423
    abbr('kc', 'kubectl create')  # Fish line 425
    abbr('kcf', 'kubectl create -f')  # Fish line 426
    abbr('kcp', 'kubectl cp')  # Fish line 428
    abbr('kdel', 'kubectl delete')  # Fish line 430
    abbr('kdeli', 'kubectl delete --interactive')  # Fish line 431
    abbr('kdeld', 'kubectl delete --dry-run')  # Fish line 432
    abbr('kdelf', 'kubectl delete -f')  # Fish line 433
    abbr('kdelp', 'kubectl delete pod')  # Fish line 434
    abbr('kdi', 'kubectl diff')  # Fish line 436
    abbr('kdif', 'kubectl diff -f')  # Fish line 437
    abbr('kd', 'kubectl describe')  # Fish line 440
    abbr('kdf', 'kubectl describe -f')  # Fish line 441
    abbr('kedit', 'kubectl edit')  # Fish line 443
    abbr('ke', 'kubectl exec -it')  # Fish line 445
    abbr('kev', 'kubectl events')  # Fish line 462
    abbr('kevA', 'kubectl events -A')  # Fish line 463
    abbr('kevw', 'kubectl events --watch')  # Fish line 464
    abbr('kevwA', 'kubectl events -A --watch')  # Fish line 465
    abbr('kexplain', 'kubectl explain')  # Fish line 467
    abbr('kexplainr', 'kubectl explain --recursive')  # Fish line 468
    abbr('kl', 'kubectl logs')  # Fish line 470
    abbr('klc', 'kubectl logs --container=')  # Fish line 471
    abbr('klf', 'kubectl logs --follow')  # Fish line 472
    abbr('kla', 'kubectl logs --all-containers=true --prefix')  # Fish line 473
    abbr('kpls', 'kubectl plugin list')  # Fish line 476
    abbr('kpatch', 'kubectl patch')  # Fish line 478
    abbr('kpf', 'kubectl port-forward')  # Fish line 480
    abbr('kr', 'kubectl replace --force')  # Fish line 482
    abbr('krf', 'kubectl replace --force -f')  # Fish line 483
    abbr('krew', 'kubectl krew')  # Fish line 485
    abbr('kro', 'kubectl rollout')  # Fish line 487
    abbr('kror', 'kubectl rollout restart')  # Fish line 488
    abbr('krorf', 'kubectl rollout restart -f')  # Fish line 489
    abbr('krost', 'kubectl rollout status')  # Fish line 490
    abbr('kroh', 'kubectl rollout history')  # Fish line 491
    abbr('krohf', 'kubectl rollout history -f')  # Fish line 492
    abbr('kropause', 'kubectl rollout pause')  # Fish line 493
    abbr('kroresume', 'kubectl rollout resume')  # Fish line 494
    abbr('kroundo', 'kubectl rollout undo')  # Fish line 495
    abbr('krun', 'kubectl run --rm -i -t --image weshigbee/tools-net tmp -- bash')  # Fish line 497
    abbr('kscale', 'kubectl scale')  # Fish line 499
    abbr('kset', 'kubectl set')  # Fish line 501
    abbr('ktop', 'kubectl top pod --all-namespaces')  # Fish line 503
    abbr('ktopw', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl top pod --all-namespaces')  # Fish line 505
    abbr('ktopn', 'kubectl top node')  # Fish line 506
    abbr('kver', 'kubectl version')  # Fish line 508
    abbr('kw', 'kubectl wait')  # Fish line 510
    abbr('kdebug', 'kubectl debug')  # Fish line 518
    abbr('kdebuge', 'kubectl debug -it --image=weshigbee/tools-net pod/')  # Fish line 519
    abbr('kdebugc', 'kubectl debug -it --image=weshigbee/tools-net --copy-to=tmp pod/')  # Fish line 520
    abbr('kdebugn', 'kubectl debug -it --image=weshigbee/tools-net node/')  # Fish line 521
    abbr('kx', 'kubectl config')  # Fish line 527
    abbr('kxu', 'kubectl config use-context')  # Fish line 537
    abbr('kxls', 'kubectl config get-contexts')  # Fish line 538
    abbr('kxv', 'kubectl config view')  # Fish line 539
    abbr('kgu', 'kubectl get users.management.cattle.io -o custom-columns=NAME:metadata.name,DISPLAYNAME:displayName,USERNAME:username,DESC:description')  # Fish line 543
    abbr('ksh', 'kubectl-shell')  # Fish line 583
    abbr('kshn', 'kubectl-shell --namespace')  # Fish line 584
    abbr('kshc', 'kubectl-shell --container')  # Fish line 588
    abbr('d64', 'base64 -d')  # Fish line 595
    abbr('e64', 'base64 -e')  # Fish line 596
    abbr('d32', 'base32 -d')  # Fish line 599
    abbr('e32', 'base32 -e')  # Fish line 600
    abbr('mk', 'minikube')  # Fish line 606
    abbr('mkst', 'minikube status')  # Fish line 607
    abbr('mkstop', 'minikube stop')  # Fish line 608
    abbr('mkstart', 'minikube start')  # Fish line 609
    abbr('mkpause', 'minikube pause')  # Fish line 610
    abbr('mkunpause', 'minikube unpause')  # Fish line 611
    abbr('mkd', 'minikube delete')  # Fish line 612
    abbr('mkda', 'minikube delete --all')  # Fish line 613
    abbr('mks', 'minikube ssh')  # Fish line 615
    abbr('mkn', 'minikube node list')  # Fish line 617
    abbr('mkdash', 'minikube dashboard --port 9090')  # Fish line 619
    abbr('mksls', 'minikube service list')  # Fish line 621
    abbr('mkt', 'minikube tunnel --cleanup')  # Fish line 624
    abbr('mka', 'minikube addons list')  # Fish line 627
    abbr('mkao', 'minikube addons open')  # Fish line 628
    abbr('mkae', 'minikube addons enable')  # Fish line 629
    abbr('mkad', 'minikube addons disable')  # Fish line 630
    abbr('mkai', 'minikube addons images')  # Fish line 631
    abbr('mkac', 'minikube addons configure')  # Fish line 632
    abbr('mkde', 'eval $(minikube docker-env)')  # Fish line 634
    abbr('mkp', 'minikube profile list')  # Fish line 637
    abbr('mkcp', 'minikube cp')  # Fish line 639
    abbr('mkip', 'minikube ip')  # Fish line 640
    abbr('mkl', 'minikube logs')  # Fish line 643
    abbr('mklf', 'minikube logs --follow')  # Fish line 644
    abbr('mkla', 'minikube logs --audit')  # Fish line 645
    abbr('mkv', 'minikube version')  # Fish line 649
    abbr('hga', 'helm get all')  # Fish line 673
    abbr('hgh', 'helm get hooks')  # Fish line 675
    abbr('hgm', 'helm get manifest')  # Fish line 677
    abbr('hgk', 'helm get manifest % | kubectl get -f -', cursor_marker="%")  # Fish line 678
    abbr('hgmetadata', 'helm get metadata')  # Fish line 681
    abbr('hgn', 'helm get notes')  # Fish line 683
    abbr('hgv', 'helm get values')  # Fish line 685
    abbr('hh', 'helm history')  # Fish line 689
    abbr('hin', 'helm install')  # Fish line 691
    abbr('hls', 'helm list -A')  # Fish line 694
    abbr('hplls', 'helm plugin ls')  # Fish line 699
    abbr('hp', 'helm pull')  # Fish line 704
    abbr('hpu', 'helm pull --untar --untardir ./untar')  # Fish line 705
    abbr('hra', 'helm repo add')  # Fish line 711
    abbr('hrls', 'helm repo ls')  # Fish line 714
    abbr('hrrm', 'helm repo remove')  # Fish line 716
    abbr('hrup', 'helm repo update')  # Fish line 718
    abbr('hsh', 'helm search hub')  # Fish line 724
    abbr('hsr', 'helm search repo')  # Fish line 725
    abbr('hsv', 'helm search repo --versions ')  # Fish line 726
    abbr('hi', 'helm inspect')  # Fish line 729
    abbr('hic', 'helm show chart % | yq', cursor_marker="%")  # Fish line 732
    abbr('hir', 'helm show readme % | bat -l md', cursor_marker="%")  # Fish line 735
    abbr('hiv', 'helm show values % | yq', cursor_marker="%")  # Fish line 737
    abbr('hst', 'helm status')  # Fish line 740
    abbr('ht', 'helm template')  # Fish line 744
    abbr('hun', 'helm uninstall')  # Fish line 762
    abbr('hup', 'helm upgrade')  # Fish line 764
    abbr('hver', 'helm version')  # Fish line 767
