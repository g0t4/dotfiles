"""Kubernetes abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr
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


def register_kubernetes_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'k3s', 'sudo k3s')  # Fish line 220
    abbr(registry, 'k3dls', 'k3d cluster list')  # Fish line 265
    abbr(registry, 'k3dcreate', 'k3d cluster create')  # Fish line 266
    abbr(registry, 'k3ddelete', 'k3d cluster delete')  # Fish line 267
    abbr(registry, 'k3dedit', 'k3d cluster edit --port-add')  # Fish line 268
    abbr(registry, 'k3dstart', 'k3d cluster start')  # Fish line 269
    abbr(registry, 'k3dstop', 'k3d cluster stop')  # Fish line 270
    abbr(registry, 'k3di', 'k3d image import')  # Fish line 272
    abbr(registry, 'k3dn', 'k3d node list')  # Fish line 274
    abbr(registry, 'k3dr', 'k3d registry list')  # Fish line 276
    abbr(registry, 'oy', '-o yaml', position="anywhere", commands=('kubectl',))  # Fish line 283
    abbr(registry, 'ow', '-o wide', position="anywhere", commands=('kubectl',))  # Fish line 284
    abbr(registry, 'kg', 'kubectl get')  # Fish line 288
    abbr(registry, 'kgf', 'kubectl get -f')  # Fish line 289
    abbr(registry, 'kgns', 'kubectl get namespaces')  # Fish line 291
    abbr(registry, 'kga', 'kubectl get all')  # Fish line 351
    abbr(registry, 'kgaa', 'kubectl get all -A')  # Fish line 352
    abbr(registry, 'kgas', 'kubectl get all --show-labels')  # Fish line 353
    abbr(registry, 'kgb', 'kubectl get -A backups,snapshots')  # Fish line 354
    abbr(registry, 'kgp', 'kubectl get pods')  # Fish line 356
    abbr(registry, 'kgpa', 'kubectl get pods -A')  # Fish line 357
    abbr(registry, 'kgpaw', 'kubectl get pods -A --watch')  # Fish line 358
    abbr(registry, 'kgcm', 'kubectl get configmaps')  # Fish line 361
    abbr(registry, 'kgcr', 'kubectl get clusterroles')  # Fish line 362
    abbr(registry, 'kgcrb', 'kubectl get clusterrolebindings -o wide')  # Fish line 363
    abbr(registry, 'kgcrd', 'kubectl get customresourcedefinitions')  # Fish line 364
    abbr(registry, 'kgds', 'kubectl get daemonsets')  # Fish line 365
    abbr(registry, 'kgep', 'kubectl get endpoints')  # Fish line 366
    abbr(registry, 'kgepA', 'kubectl get endpoints -A')  # Fish line 367
    abbr(registry, 'kgend', 'kubectl get svc,endpoints,endpointslices')  # Fish line 368
    abbr(registry, 'kgev', 'kubectl get events')  # Fish line 369
    abbr(registry, 'kging', 'kubectl get ingresses')  # Fish line 370
    abbr(registry, 'kgj', 'kubectl get -A jobs,cronjobs')  # Fish line 371
    abbr(registry, 'kgno', 'kubectl get nodes')  # Fish line 372
    abbr(registry, 'kgpv', 'kubectl get persistentvolumes')  # Fish line 373
    abbr(registry, 'kgpvc', 'kubectl get persistentvolumeclaims')  # Fish line 374
    abbr(registry, 'kgr', 'kubectl get --raw /% | yq -P', cursor_marker="%")  # Fish line 376
    abbr(registry, 'kgr/a', 'kubectl get --raw /apis')  # Fish line 378
    abbr(registry, 'kgr/h', 'kubectl get --raw /healthz')  # Fish line 379
    abbr(registry, 'kgr/l', 'kubectl get --raw /livez')  # Fish line 380
    abbr(registry, 'kgr/m', 'kubectl get --raw /metrics')  # Fish line 381
    abbr(registry, 'kgr/o', 'kubectl get --raw /openapi')  # Fish line 382
    abbr(registry, 'kgr/r', 'kubectl get --raw /readyz')  # Fish line 384
    abbr(registry, 'kgr/v', 'kubectl get --raw /version')  # Fish line 385
    abbr(registry, 'kgrb', 'kubectl get rolebindings -o wide')  # Fish line 387
    abbr(registry, 'kgro', 'kubectl get roles')  # Fish line 388
    abbr(registry, 'kgrs', 'kubectl get replicasets')  # Fish line 389
    abbr(registry, 'kgs', 'kubectl get svc')  # Fish line 390
    abbr(registry, 'kgsa', 'kubectl get serviceaccounts')  # Fish line 391
    abbr(registry, 'kgsc', 'kubectl get storageclasses')  # Fish line 392
    abbr(registry, 'kgsecrets', 'kubectl get secrets')  # Fish line 393
    abbr(registry, 'kgsts', 'kubectl get statefulsets')  # Fish line 394
    abbr(registry, 'kgrev', 'kubectl get pods,sts,controllerrevisions')  # Fish line 395
    abbr(registry, 'kgsvc', 'kubectl get services')  # Fish line 396
    abbr(registry, 'kgv', fish_abbreviation('_abbr_kgv'))  # Fish line 398
    abbr(registry, 'kaf', 'kubectl apply -f')  # Fish line 412
    abbr(registry, 'kad', 'kubectl apply --dry-run=client -f')  # Fish line 413
    abbr(registry, 'kak', 'kubectl apply -k .')  # Fish line 414
    abbr(registry, 'kk', 'kubectl kustomize')  # Fish line 415
    abbr(registry, 'kar', 'kubectl api-resources')  # Fish line 417
    abbr(registry, 'kara', 'kubectl api-resources --api-group')  # Fish line 418
    abbr(registry, 'karn', 'kubectl api-resources --namespaced=true')  # Fish line 419
    abbr(registry, 'karg', 'kubectl api-resources --namespaced=false')  # Fish line 420
    abbr(registry, 'kav', 'kubectl api-versions')  # Fish line 421
    abbr(registry, 'kattach', 'kubectl attach -it')  # Fish line 423
    abbr(registry, 'kc', 'kubectl create')  # Fish line 425
    abbr(registry, 'kcf', 'kubectl create -f')  # Fish line 426
    abbr(registry, 'kcp', 'kubectl cp')  # Fish line 428
    abbr(registry, 'kdel', 'kubectl delete')  # Fish line 430
    abbr(registry, 'kdeli', 'kubectl delete --interactive')  # Fish line 431
    abbr(registry, 'kdeld', 'kubectl delete --dry-run')  # Fish line 432
    abbr(registry, 'kdelf', 'kubectl delete -f')  # Fish line 433
    abbr(registry, 'kdelp', 'kubectl delete pod')  # Fish line 434
    abbr(registry, 'kdi', 'kubectl diff')  # Fish line 436
    abbr(registry, 'kdif', 'kubectl diff -f')  # Fish line 437
    abbr(registry, 'kd', 'kubectl describe')  # Fish line 440
    abbr(registry, 'kdf', 'kubectl describe -f')  # Fish line 441
    abbr(registry, 'kedit', 'kubectl edit')  # Fish line 443
    abbr(registry, 'ke', 'kubectl exec -it')  # Fish line 445
    abbr(registry, 'kev', 'kubectl events')  # Fish line 462
    abbr(registry, 'kevA', 'kubectl events -A')  # Fish line 463
    abbr(registry, 'kevw', 'kubectl events --watch')  # Fish line 464
    abbr(registry, 'kevwA', 'kubectl events -A --watch')  # Fish line 465
    abbr(registry, 'kexplain', 'kubectl explain')  # Fish line 467
    abbr(registry, 'kexplainr', 'kubectl explain --recursive')  # Fish line 468
    abbr(registry, 'kl', 'kubectl logs')  # Fish line 470
    abbr(registry, 'klc', 'kubectl logs --container=')  # Fish line 471
    abbr(registry, 'klf', 'kubectl logs --follow')  # Fish line 472
    abbr(registry, 'kla', 'kubectl logs --all-containers=true --prefix')  # Fish line 473
    abbr(registry, 'kpls', 'kubectl plugin list')  # Fish line 476
    abbr(registry, 'kpatch', 'kubectl patch')  # Fish line 478
    abbr(registry, 'kpf', 'kubectl port-forward')  # Fish line 480
    abbr(registry, 'kr', 'kubectl replace --force')  # Fish line 482
    abbr(registry, 'krf', 'kubectl replace --force -f')  # Fish line 483
    abbr(registry, 'krew', 'kubectl krew')  # Fish line 485
    abbr(registry, 'kro', 'kubectl rollout')  # Fish line 487
    abbr(registry, 'kror', 'kubectl rollout restart')  # Fish line 488
    abbr(registry, 'krorf', 'kubectl rollout restart -f')  # Fish line 489
    abbr(registry, 'krost', 'kubectl rollout status')  # Fish line 490
    abbr(registry, 'kroh', 'kubectl rollout history')  # Fish line 491
    abbr(registry, 'krohf', 'kubectl rollout history -f')  # Fish line 492
    abbr(registry, 'kropause', 'kubectl rollout pause')  # Fish line 493
    abbr(registry, 'kroresume', 'kubectl rollout resume')  # Fish line 494
    abbr(registry, 'kroundo', 'kubectl rollout undo')  # Fish line 495
    abbr(registry, 'krun', 'kubectl run --rm -i -t --image weshigbee/tools-net tmp -- bash')  # Fish line 497
    abbr(registry, 'kscale', 'kubectl scale')  # Fish line 499
    abbr(registry, 'kset', 'kubectl set')  # Fish line 501
    abbr(registry, 'ktop', 'kubectl top pod --all-namespaces')  # Fish line 503
    abbr(registry, 'ktopw', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl top pod --all-namespaces')  # Fish line 505
    abbr(registry, 'ktopn', 'kubectl top node')  # Fish line 506
    abbr(registry, 'kver', 'kubectl version')  # Fish line 508
    abbr(registry, 'kw', 'kubectl wait')  # Fish line 510
    abbr(registry, 'kdebug', 'kubectl debug')  # Fish line 518
    abbr(registry, 'kdebuge', 'kubectl debug -it --image=weshigbee/tools-net pod/')  # Fish line 519
    abbr(registry, 'kdebugc', 'kubectl debug -it --image=weshigbee/tools-net --copy-to=tmp pod/')  # Fish line 520
    abbr(registry, 'kdebugn', 'kubectl debug -it --image=weshigbee/tools-net node/')  # Fish line 521
    abbr(registry, 'kx', 'kubectl config')  # Fish line 527
    abbr(registry, 'kxu', 'kubectl config use-context')  # Fish line 537
    abbr(registry, 'kxls', 'kubectl config get-contexts')  # Fish line 538
    abbr(registry, 'kxv', 'kubectl config view')  # Fish line 539
    abbr(registry, 'kgu', 'kubectl get users.management.cattle.io -o custom-columns=NAME:metadata.name,DISPLAYNAME:displayName,USERNAME:username,DESC:description')  # Fish line 543
    abbr(registry, 'ksh', 'kubectl-shell')  # Fish line 583
    abbr(registry, 'kshn', 'kubectl-shell --namespace')  # Fish line 584
    abbr(registry, 'kshc', 'kubectl-shell --container')  # Fish line 588
    abbr(registry, 'd64', 'base64 -d')  # Fish line 595
    abbr(registry, 'e64', 'base64 -e')  # Fish line 596
    abbr(registry, 'd32', 'base32 -d')  # Fish line 599
    abbr(registry, 'e32', 'base32 -e')  # Fish line 600
    abbr(registry, 'mk', 'minikube')  # Fish line 606
    abbr(registry, 'mkst', 'minikube status')  # Fish line 607
    abbr(registry, 'mkstop', 'minikube stop')  # Fish line 608
    abbr(registry, 'mkstart', 'minikube start')  # Fish line 609
    abbr(registry, 'mkpause', 'minikube pause')  # Fish line 610
    abbr(registry, 'mkunpause', 'minikube unpause')  # Fish line 611
    abbr(registry, 'mkd', 'minikube delete')  # Fish line 612
    abbr(registry, 'mkda', 'minikube delete --all')  # Fish line 613
    abbr(registry, 'mks', 'minikube ssh')  # Fish line 615
    abbr(registry, 'mkn', 'minikube node list')  # Fish line 617
    abbr(registry, 'mkdash', 'minikube dashboard --port 9090')  # Fish line 619
    abbr(registry, 'mksls', 'minikube service list')  # Fish line 621
    abbr(registry, 'mkt', 'minikube tunnel --cleanup')  # Fish line 624
    abbr(registry, 'mka', 'minikube addons list')  # Fish line 627
    abbr(registry, 'mkao', 'minikube addons open')  # Fish line 628
    abbr(registry, 'mkae', 'minikube addons enable')  # Fish line 629
    abbr(registry, 'mkad', 'minikube addons disable')  # Fish line 630
    abbr(registry, 'mkai', 'minikube addons images')  # Fish line 631
    abbr(registry, 'mkac', 'minikube addons configure')  # Fish line 632
    abbr(registry, 'mkde', 'eval $(minikube docker-env)')  # Fish line 634
    abbr(registry, 'mkp', 'minikube profile list')  # Fish line 637
    abbr(registry, 'mkcp', 'minikube cp')  # Fish line 639
    abbr(registry, 'mkip', 'minikube ip')  # Fish line 640
    abbr(registry, 'mkl', 'minikube logs')  # Fish line 643
    abbr(registry, 'mklf', 'minikube logs --follow')  # Fish line 644
    abbr(registry, 'mkla', 'minikube logs --audit')  # Fish line 645
    abbr(registry, 'mkv', 'minikube version')  # Fish line 649
    abbr(registry, 'hga', 'helm get all')  # Fish line 673
    abbr(registry, 'hgh', 'helm get hooks')  # Fish line 675
    abbr(registry, 'hgm', 'helm get manifest')  # Fish line 677
    abbr(registry, 'hgk', 'helm get manifest % | kubectl get -f -', cursor_marker="%")  # Fish line 678
    abbr(registry, 'hgmetadata', 'helm get metadata')  # Fish line 681
    abbr(registry, 'hgn', 'helm get notes')  # Fish line 683
    abbr(registry, 'hgv', 'helm get values')  # Fish line 685
    abbr(registry, 'hh', 'helm history')  # Fish line 689
    abbr(registry, 'hin', 'helm install')  # Fish line 691
    abbr(registry, 'hls', 'helm list -A')  # Fish line 694
    abbr(registry, 'hplls', 'helm plugin ls')  # Fish line 699
    abbr(registry, 'hp', 'helm pull')  # Fish line 704
    abbr(registry, 'hpu', 'helm pull --untar --untardir ./untar')  # Fish line 705
    abbr(registry, 'hra', 'helm repo add')  # Fish line 711
    abbr(registry, 'hrls', 'helm repo ls')  # Fish line 714
    abbr(registry, 'hrrm', 'helm repo remove')  # Fish line 716
    abbr(registry, 'hrup', 'helm repo update')  # Fish line 718
    abbr(registry, 'hsh', 'helm search hub')  # Fish line 724
    abbr(registry, 'hsr', 'helm search repo')  # Fish line 725
    abbr(registry, 'hsv', 'helm search repo --versions ')  # Fish line 726
    abbr(registry, 'hi', 'helm inspect')  # Fish line 729
    abbr(registry, 'hic', 'helm show chart % | yq', cursor_marker="%")  # Fish line 732
    abbr(registry, 'hir', 'helm show readme % | bat -l md', cursor_marker="%")  # Fish line 735
    abbr(registry, 'hiv', 'helm show values % | yq', cursor_marker="%")  # Fish line 737
    abbr(registry, 'hst', 'helm status')  # Fish line 740
    abbr(registry, 'ht', 'helm template')  # Fish line 744
    abbr(registry, 'hun', 'helm uninstall')  # Fish line 762
    abbr(registry, 'hup', 'helm upgrade')  # Fish line 764
    abbr(registry, 'hver', 'helm version')  # Fish line 767
