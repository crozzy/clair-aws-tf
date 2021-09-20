apiVersion: v1
kind: Namespace
metadata:
   name: ${namespace}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-service-ca
  namespace: ${namespace}
  annotations:
    service.beta.openshift.io/inject-cabundle: 'true'
---
apiVersion: v1
kind: Service
metadata:
  name: clair-app-indexer-service
  namespace: ${namespace}
  labels:
    clair-component: clair-app
spec:
  ports:
    - name: clair-http
      port: 80
      protocol: TCP
      targetPort: 8080
    - name: clair-introspection
      port: 8089
      protocol: TCP
      targetPort: 8089
  selector:
    clair-component: clair-app-indexer
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: clair-app-matcher-service
  namespace: ${namespace}
  labels:
    clair-component: clair-app
spec:
  ports:
    - name: clair-http
      port: 80
      protocol: TCP
      targetPort: 8080
    - name: clair-introspection
      port: 8089
      protocol: TCP
      targetPort: 8089
  selector:
    clair-component: clair-app-matcher
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: clair-app-notifier-service
  namespace: ${namespace}
  labels:
    clair-component: clair-app
spec:
  ports:
    - name: clair-http
      port: 80
      protocol: TCP
      targetPort: 8080
    - name: clair-introspection
      port: 8089
      protocol: TCP
      targetPort: 8089
  selector:
    clair-component: clair-app-notifier
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    clair-component: clair-app-indexer
  name: clair-app-indexer
  namespace: ${namespace}
spec:
  replicas: ${indexer_replicas}
  selector:
    matchLabels:
      clair-component: clair-app-indexer
  template:
    metadata:
      labels:
        clair-component: clair-app-indexer
    spec:
      serviceAccountName: clair-app
      containers:
        - image: ${clair_image}
          imagePullPolicy: Always
          name: clair-app-indexer
#          resources:
#            limits:
#              cpu: "6000m"
          env:
            - name: CLAIR_CONF
              value: /clair/config.yaml
            - name: CLAIR_MODE
              value: indexer
          ports:
            - containerPort: 8080
              name: clair-http
              protocol: TCP
            - containerPort: 8089
              name: clair-intro
              protocol: TCP
          volumeMounts:
            - mountPath: /clair/
              name: config
            - mountPath: /tmp
              name: indexer-layer-storage
          startupProbe:
            tcpSocket:
              port: clair-intro
            periodSeconds: 10
            failureThreshold: 300
          readinessProbe:
            tcpSocket:
              port: 8080
          livenessProbe:
            httpGet:
              port: clair-intro
              path: /healthz
      restartPolicy: Always
      volumes:
        - name: config
          secret:
            secretName: clair-config-secret
        #- name: indexer-layer-storage
        #  emptyDir: {}
        - name: indexer-layer-storage
          ephemeral:
            volumeClaimTemplate:
              metadata:
                labels:
                  type: indexer-volume
              spec:
                accessModes: [ "ReadWriteOnce" ]
                volumeMode: Filesystem
                storageClassName: "gp2"
                resources:
                  requests:
                    storage: 20Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    clair-component: clair-app-matcher
  name: clair-app-matcher
  namespace: ${namespace}
spec:
  replicas: ${matcher_replicas}
  selector:
    matchLabels:
      clair-component: clair-app-matcher
  template:
    metadata:
      labels:
        clair-component: clair-app-matcher
    spec:
      serviceAccountName: clair-app
      containers:
        - image: ${clair_image}
          imagePullPolicy: Always
          name: clair-app-matcher
          env:
            - name: CLAIR_CONF
              value: /clair/config.yaml
            - name: CLAIR_MODE
              value: matcher
          ports:
            - containerPort: 8080
              name: clair-http
              protocol: TCP
            - containerPort: 8089
              name: clair-intro
              protocol: TCP
          volumeMounts:
            - mountPath: /clair/
              name: config
#            - mountPath: /var/run/certs
#              name: certs
          startupProbe:
            tcpSocket:
              port: clair-intro
            periodSeconds: 10
            failureThreshold: 300
          readinessProbe:
            tcpSocket:
              port: 8080
          livenessProbe:
            httpGet:
              port: clair-intro
              path: /healthz
      restartPolicy: Always
      volumes:
        - name: config
          secret:
            secretName: clair-config-secret
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    clair-component: clair-app-notifier
  name: clair-app-notifier
  namespace: ${namespace}
spec:
  replicas: ${notifier_replicas}
  selector:
    matchLabels:
      clair-component: clair-app-notifier
  template:
    metadata:
      labels:
        clair-component: clair-app-notifier
    spec:
      serviceAccountName: clair-app
      containers:
        - image: ${clair_image}
          imagePullPolicy: Always
          name: clair-app-notifier
          env:
            - name: CLAIR_CONF
              value: /clair/config.yaml
            - name: CLAIR_MODE
              value: notifier
          ports:
            - containerPort: 8080
              name: clair-http
              protocol: TCP
            - containerPort: 8089
              name: clair-intro
              protocol: TCP
          volumeMounts:
            - mountPath: /clair/
              name: config
#            - mountPath: /var/run/certs
#              name: certs
          startupProbe:
            tcpSocket:
              port: clair-intro
            periodSeconds: 10
            failureThreshold: 300
          readinessProbe:
            tcpSocket:
              port: 8080
          livenessProbe:
            httpGet:
              port: clair-intro
              path: /healthz
      restartPolicy: Always
      volumes:
        - name: config
          secret:
            secretName: clair-config-secret
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: clair-app
  namespace: ${namespace}
---
apiVersion: v1
kind: Secret
metadata:
  name: clair-config-secret
  namespace: ${namespace}
stringData:
  config.yaml: |
    http_listen_addr: :8080
    introspection_addr: ""
    log_level: debug
    indexer:
        connstring: host=${clair_db_host} port=${clair_db_port} dbname=clair user=${clair_db_user} password=${clair_db_password} sslmode=disable
        scanlock_retry: 10
        layer_scan_concurrency: 10
        migrations: true
        scanner:
            package: {}
            dist: {}
            repo: {}
        airgap: false
        index_report_request_concurrency: 10
    matcher:
        connstring: host=${clair_db_host} port=${clair_db_port} dbname=clair user=${clair_db_user} password=${clair_db_password} sslmode=disable
        max_conn_pool: 100
        indexer_addr: "http://clair-app-indexer-service"
        migrations: true
        period: null
        disable_updaters: false  
    notifier:
        connstring: host=${clair_db_host} port=${clair_db_port} dbname=clair user=${clair_db_user} password=${clair_db_password} sslmode=disable
        migrations: true
        indexer_addr: "http://clair-app-indexer-service"
        matcher_addr: "http://clair-app-matcher-service"
        poll_interval: 5m
        delivery_interval: 1m
        amqp: null
        stomp: null
    auth:
        psk:
            key: ${clair_auth_psk}
            iss:
                - quay
                - clairctl
    metrics:
        name: prometheus
        prometheus:
            endpoint: null
        dogstatsd:
            url: ""
---
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: clair-indexer
  namespace: ${namespace}
  labels:
    clair-component: clair-app-indexer
  annotations:
    openshift.io/host.generated: 'true'
    haproxy.router.openshift.io/timeout: '2h'
spec:
  host: ${clair_route_host}
  path: /indexer
  to:
    kind: Service
    name: clair-app-indexer-service
    weight: 100
  port:
    targetPort: clair-http
  wildcardPolicy: None
---
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: clair-matcher
  namespace: ${namespace}
  labels:
    clair-component: clair-app-matcher
  annotations:
    openshift.io/host.generated: 'true'
spec:
  host: ${clair_route_host}
  path: /matcher
  to:
    kind: Service
    name: clair-app-matcher-service
    weight: 100
  port:
    targetPort: clair-http
  wildcardPolicy: None
