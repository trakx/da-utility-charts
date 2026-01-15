{{- define "scribe.containers"}}
- name: scribe
  command:
    - sh
    - -c
    - exec java -jar scribe.jar "$@" "--pipeline-oauth-endpoint=$(cat /shared/tokenUrl)"
  args:
    - --
    - pipeline
    - ledger
    - postgres-document
    - --source-ledger-host={{ .Values.network.participant.host }}
    - --source-ledger-port={{ .Values.network.participant.ports.ledger }}
    - --source-ledger-auth=OAuth
    - --pipeline-oauth-parameters-audience={{ .Values.network.oidc.audience }}
    - --pipeline-oauth-scope={{ .Values.network.oidc.scope }}
    - --target-postgres-host={{ .Values.operator.postgres.host }}
    - --target-postgres-port={{ .Values.operator.postgres.port }}
    - --target-postgres-username={{ .Values.operator.postgres.user }}
    - --target-postgres-database={{ .Values.operator.postgres.database }}
    - --target-postgres-schema=pqs
    - --target-postgres-tls-mode=Disable
    - --pipeline-filter-metadata=*
    - --health-port=8091
  env:
    - name: JDK_JAVA_OPTIONS
      value: ' -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=9999 -Dcom.sun.management.jmxremote.rmi.port=9999 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.ssl.need.client.auth=false'
    - name: OTEL_EXPORTER_PROMETHEUS_PORT
      value: "9090"
    - name: OTEL_LOGS_EXPORTER
      value: none
    - name: OTEL_METRICS_EXPORTER
      value: prometheus
    - name: OTEL_SERVICE_NAME
      value: scribe
    - name: OTEL_TRACES_EXPORTER
      value: none
    - name: SCRIBE_PIPELINE_OAUTH_CLIENTID
      value: {{ .Values.network.oidc.clientId }}
    - name: SCRIBE_PIPELINE_OAUTH_CLIENTSECRET
      valueFrom:
        secretKeyRef:
          name: {{ .Values.network.oidc.clientSecret.name }}
          key: {{ .Values.network.oidc.clientSecret.key }}
    {{- if .Values.operator.postgres.passwordSecretRef.name }}
    - name: SCRIBE_TARGET_POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ .Values.operator.postgres.passwordSecretRef.name }}
          key: {{ .Values.operator.postgres.passwordSecretRef.key }}
    {{- end }}
  image: "{{ .Values.imageRepository }}/scribe:0.6.12-debug"
  resources:
    limits:
      cpu: 1000m
      memory: 3Gi
    requests:
      cpu: 500m
      memory: 256Mi
  securityContext:
    readOnlyRootFilesystem: false
    runAsGroup: 65532
    runAsNonRoot: true
    runAsUser: 65532
  workingDir: /daml3.4
  volumeMounts:
    - name: shared-data
      mountPath: /shared
{{- if .Values.operator.scribe.autoPruneEnabled }}
- name: auto-prune
  command:
    - prune-pqs
  env:
    - name: PRUNING_INTERVAL_SECONDS
      value: '3600'
    - name: PQS_MAX_AGE_DAYS
      value: '2'
    - name: PGHOST
      value: {{ .Values.operator.postgres.host }}
    - name: PGSCHEMA
      value: pqs
    - name: PGDATABASE
      value: {{ .Values.operator.postgres.database }}
    - name: PGUSER
      value: {{ .Values.operator.postgres.user }}
    {{- if .Values.operator.postgres.passwordSecretRef.name }}
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ .Values.operator.postgres.passwordSecretRef.name }}
          key: {{ .Values.operator.postgres.passwordSecretRef.key }}
    {{- end }}
  image: "{{ .Values.imageRepository }}/validator-tools/backup-service:2.3.0"
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi
  securityContext:
    readOnlyRootFilesystem: false
    runAsGroup: 65532
    runAsNonRoot: true
    runAsUser: 65532
{{- end }}
{{- end }}
