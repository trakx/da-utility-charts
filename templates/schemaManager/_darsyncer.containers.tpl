{{- define "darsyncer.containers"}}
- name: darsyncer
  image: "{{ .Values.imageRepository }}/utilities-darsyncer-{{ empty .Values.operator.features | ternary "client" "operator" }}:{{ .Chart.Version }}"
  args:
    # TODO: upgrade urfave CLI in darsyncer to use env vars for this
    - --endpoint={{ .Values.network.participant.host }}:{{ .Values.network.participant.ports.admin }}
  env:
    - name: DARS
      value: /dars
    {{- $oidc := .Values.network.oidc }}
    - name: AUDIENCE
      value: {{ $oidc.audience }}
    - name: CLIENT_ID
      value: {{ $oidc.clientId }}
    - name: CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          {{- toYaml $oidc.clientSecret | nindent 18 }}
    - name: OAUTH_DOMAIN
      value: {{ $oidc.issuerUri }}
  resources:
    limits:
      cpu: "1000m"
      memory: "256Mi"
    requests:
      cpu: "500m"
      memory: "128Mi"
  ports:
  - name: readyz
    containerPort: 8080
  startupProbe:
    httpGet:
      path: /readyz
      port: readyz
{{- end }}
