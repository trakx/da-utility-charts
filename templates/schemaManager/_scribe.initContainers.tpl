{{- define "scribe.initContainers" }}
- name: discover-token-url
  image: "{{ .Values.imageRepository }}/validator-tools/get-token-endpoint:2.3.0"
  env:
    - name: ISSUER_URI
      value: {{ .Values.network.oidc.issuerUri }}
    - name: OUTPUT_FILE
      value: /shared/tokenUrl
  volumeMounts:
    - name: shared-data
      mountPath: /shared
{{- if .Values.operator.postgres.googleCloudSql.instanceID }}
- name: proxy
  args:
    - --auto-iam-authn
    - --private-ip
    - --structured-logs
    - {{ .Values.operator.postgres.googleCloudSql.instanceID }}
  image: "{{ .Values.operator.postgres.googleCloudSql.proxyImage }}"
  restartPolicy: Always
{{- end }}
{{- end }}
