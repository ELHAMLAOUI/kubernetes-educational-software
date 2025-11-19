#!/usr/bin/env python3
"""Construit les états simulés à partir des VRAIS fichiers du dépôt (setup.sh et solutions)."""
import base64, copy, json, re, sys, yaml

REPO = sys.argv[1]; OUT = sys.argv[2]  # usage : build_states.py <racine du dépôt> <dossier de sortie> [dossier des solutions]
SOL = sys.argv[3] if len(sys.argv) > 3 else f"{REPO}/solutions"

def setup_yaml(lab):
    txt = open(f"{REPO}/labs/{lab}/setup.sh").read()
    m = re.search(r"<<'YAML'[^\n]*\n(.*?)\nYAML", txt, re.S)
    return [d for d in yaml.safe_load_all(m.group(1)) if d] if m else []

def sol_yaml(lab):
    return [d for d in yaml.safe_load_all(open(f"{SOL}/{lab}.yaml")) if d]

def normalize(o):
    """Valeurs par défaut posées par l'API server."""
    k = o["kind"]
    if k == "Service":
        o["spec"].setdefault("type", "ClusterIP")
        for p in o["spec"]["ports"]: p.setdefault("targetPort", p["port"])
    if k == "Deployment":
        o["spec"].setdefault("strategy", {"type": "RollingUpdate", "rollingUpdate": {"maxSurge": "25%", "maxUnavailable": "25%"}})
        o["metadata"].setdefault("annotations", {})["deployment.kubernetes.io/revision"] = "1"
    if k == "Secret":
        o.setdefault("type", "Opaque")
        for kk, v in o.pop("stringData", {}).items():
            o.setdefault("data", {})[kk] = base64.b64encode(v.encode()).decode()
    return o

def qos(c):
    r = c.get("resources", {})
    if not r: return "BestEffort"
    return "Guaranteed" if r.get("requests") == r.get("limits") else "Burstable"

class State:
    def __init__(s): s.st = {"objects": {}, "ready": {}, "http": {}, "exec": {}}
    def add(s, o):
        o = normalize(copy.deepcopy(o))
        ns = o["metadata"]["namespace"]; kind = o["kind"].lower()
        s.st["objects"].setdefault(ns, {}).setdefault(kind, {})[o["metadata"]["name"]] = o
        return o
    def get(s, ns, kind, name): return s.st["objects"][ns][kind][name]
    def ready(s, ns, t): s.st["ready"].setdefault(ns, []).append(t)
    def deploy_running(s, ns, name, image_ok=True):
        d = s.get(ns, "deployment", name); n = d["spec"]["replicas"]
        if image_ok:
            d["status"] = {"replicas": n, "readyReplicas": n, "updatedReplicas": n}
            s.ready(ns, f"deploy/{name}")
        else:
            d["status"] = {"replicas": n, "unavailableReplicas": n, "updatedReplicas": n}
        tpl = d["spec"]["template"]; ips = []
        for i in range(n):
            ip = f"10.244.0.{len(ips)+10}"
            s.add({"kind": "Pod", "metadata": {"name": f"{name}-abc{i}", "namespace": ns, "labels": tpl["metadata"]["labels"]},
                   "spec": tpl["spec"], "status": {"phase": "Running" if image_ok else "Pending", "podIP": ip,
                   "qosClass": qos(tpl["spec"]["containers"][0])}})
            if image_ok: ips.append(ip)
        return ips
    def service_ok(s, ns, svc, ips):
        o = s.get(ns, "service", svc)
        s.add({"kind": "Endpoints", "metadata": {"name": svc, "namespace": ns},
               **({"subsets": [{"addresses": [{"ip": ip} for ip in ips]}]} if ips else {})})
        s.st["http"].setdefault(ns, {})[svc] = bool(ips)
    def dump(s, name): json.dump(s.st, open(f"{OUT}/{name}.json", "w"), indent=1)

def endpoints_for(s, ns, svc):
    o = s.get(ns, "service", svc); sel = o["spec"]["selector"]
    pods = [p for p in s.st["objects"][ns].get("pod", {}).values()
            if all(p["metadata"]["labels"].get(k) == v for k, v in sel.items()) and p["status"]["phase"] == "Running"]
    port_ok = all(p["spec"]["containers"][0]["ports"][0]["containerPort"] == o["spec"]["ports"][0]["targetPort"] for p in pods)
    return [p["status"]["podIP"] for p in pods], port_ok

# ---------------- état « résolu » : solutions de référence ----------------
S = State()
for o in sol_yaml("lab01"):
    o = S.add(o); o["status"] = {"phase": "Running"}; S.ready("lab01", "pod/web")
for o in sol_yaml("lab02"): S.add(o)
S.deploy_running("lab02", "api")
# lab03 : setup puis lab03.sh (patch stratégie, set image, annotate)
for o in setup_yaml("lab03"): S.add(o)
d = S.get("lab03", "deployment", "front")
d["spec"]["strategy"] = {"type": "RollingUpdate", "rollingUpdate": {"maxSurge": 1, "maxUnavailable": 0}}
d["spec"]["template"]["spec"]["containers"][0]["image"] = "nginx:1.27"
d["metadata"]["annotations"]["kubernetes.io/change-cause"] = "passage en 1.27"
d["metadata"]["annotations"]["deployment.kubernetes.io/revision"] = "2"
S.deploy_running("lab03", "front")
for o in setup_yaml("lab04") + sol_yaml("lab04"): S.add(o)
ips = S.deploy_running("lab04", "api"); S.service_ok("lab04", "api-svc", endpoints_for(S, "lab04", "api-svc")[0])
for o in sol_yaml("lab05"):
    o = S.add(o)
    if o["kind"] == "Pod":
        o["status"] = {"phase": "Running"}; S.ready("lab05", "pod/app")
cm = S.get("lab05", "configmap", "app-config")["data"]
sec = {k: base64.b64decode(v).decode() for k, v in S.get("lab05", "secret", "app-secret")["data"].items()}
S.st["exec"]["lab05"] = {"app": {"env": ["PATH=/bin"] + [f"{k}={v}" for k, v in {**cm, **sec}.items()],
                                  "files": {f"/etc/app/{k}": v for k, v in cm.items()}}}
for o in sol_yaml("lab06"): S.add(o)
S.deploy_running("lab06", "robust")
# lab07 : setup cassé puis lab07.sh (set image, patch sélecteur + targetPort)
for o in setup_yaml("lab07"): S.add(o)
S.get("lab07", "deployment", "shop")["spec"]["template"]["spec"]["containers"][0]["image"] = "nginx:1.25"
svc = S.get("lab07", "service", "shop-svc"); svc["spec"]["selector"]["app"] = "shop"; svc["spec"]["ports"][0]["targetPort"] = 80
S.deploy_running("lab07", "shop")
ips, ok = endpoints_for(S, "lab07", "shop-svc"); S.service_ok("lab07", "shop-svc", ips if ok else [])
S.dump("solved")

# ---------------- état « initial » : setups seuls, rien fait par l'étudiant ----------------
I = State()
for lab in ["lab03", "lab04", "lab07"]:
    for o in setup_yaml(lab): I.add(o)
I.deploy_running("lab03", "front"); I.deploy_running("lab04", "api")
I.deploy_running("lab07", "shop", image_ok=False)   # nginx:1.255 n'existe pas
ips, ok = endpoints_for(I, "lab07", "shop-svc"); I.service_ok("lab07", "shop-svc", ips if ok else [])
I.dump("initial")

# ---------------- état « erreurs d'étudiant typiques » ----------------
W = State()
o = W.add({**sol_yaml("lab01")[0]}); o["spec"]["containers"][0]["image"] = "nginx:latest"; o["status"] = {"phase": "Running"}; W.ready("lab01", "pod/web")
o = W.add(sol_yaml("lab02")[0]); o["spec"]["replicas"] = 2; W.deploy_running("lab02", "api")
for o in setup_yaml("lab04"): W.add(o)
s4 = copy.deepcopy(sol_yaml("lab04")[0]); s4["spec"]["selector"] = {"app": "API"}; W.add(s4)
W.deploy_running("lab04", "api"); W.service_ok("lab04", "api-svc", endpoints_for(W, "lab04", "api-svc")[0])
for o in sol_yaml("lab05"):
    if o["kind"] == "ConfigMap": o = copy.deepcopy(o); o["data"]["DB_PASSWORD"] = "S3cret-2026"
    if o["kind"] != "Secret": W.add(o)
W.get("lab05", "pod", "app")["status"] = {"phase": "Running"}; W.ready("lab05", "pod/app")
W.st["exec"]["lab05"] = {"app": {"env": ["APP_MODE=production", "APP_COLOR=blue", "DB_PASSWORD=S3cret-2026"], "files": {}}}
s6 = copy.deepcopy(sol_yaml("lab06")[0]); c = s6["spec"]["template"]["spec"]["containers"][0]
c["resources"]["limits"] = dict(c["resources"]["requests"]); del c["livenessProbe"]; W.add(s6); W.deploy_running("lab06", "robust")
W.dump("wrong")
print("états écrits")
