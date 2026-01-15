{{- define "traefik.configmapData" -}}

{{- if has "operatorBackend" .Values.operator.features }}

{{- $hosts := list -}}
{{- if .Values.frontend.hostname -}}
  {{- $hosts = append $hosts (printf "Host(`%s`)" .Values.frontend.hostname) -}}
{{- end -}}
{{- if .Values.network.operatorApiUrl -}}
  {{- $operatorApiHost := (.Values.network.operatorApiUrl | urlParse).host }}
  {{- $hosts = append $hosts (printf "Host(`%s`)" $operatorApiHost) -}}
{{- end -}}
{{- if not (empty $hosts) }}
operator-backend.yaml: |
  http:
    routers:
      operator-backend:
        entryPoints:
          - web
        rule: "({{- join " || " $hosts -}}) && PathRegexp(`^/api/(utilities|token-standard)/v0(/|$)(.*)$`)"
        service: operator-backend
    services:
      operator-backend:
        loadBalancer:
          servers:
            - url: "http://{{ .Release.Name }}-operator-backend.{{ .Release.Namespace }}.svc.cluster.local:8080"
{{- end }}
{{ end }}


{{- if ne .Values.frontend.hostname "" }}
{{- if has "registry" .Values.operator.features }}
registry.yaml: |
  http:
    routers:
      registry-operator-automations:
        entryPoints:
          - web
        rule: "Host(`{{ .Values.frontend.hostname }}`) && PathPrefix(`/api/registry/`)"
        service: registry-operator-automations
    services:
      registry-operator-automations:
        loadBalancer:
          servers:
            - url: "http://{{ .Release.Name }}-registry-app-automations.{{ .Release.Namespace }}.svc.cluster.local:80"
{{ end }}

{{- if .Values.frontend.enabled }}
frontend.yaml: |
  http:
    routers:
      validator-api:
        entryPoints:
          - web
        rule: "Host(`{{ .Values.frontend.hostname }}`) && PathPrefix(`/api/validator/`)"
        service: validator-api
      participant-json-api:
        entryPoints:
          - web
        rule: "Host(`{{ .Values.frontend.hostname }}`) && PathRegexp(`^/api/json-api(/|$)(.*)$`)"
        service: participant-json-api
      frontend:
        entryPoints:
          - web
        rule: "Host(`{{ .Values.frontend.hostname }}`) && PathPrefix(`/`)"
        service: frontend
    services:
      validator-api:
        loadBalancer:
          servers:
            - url: "http://{{ .Values.network.validator.host }}:{{ .Values.network.validator.ports.http }}"
      participant-json-api:
        loadBalancer:
          servers:
            - url: "http://{{ .Values.network.participant.host }}:{{ .Values.network.participant.ports.jsonApi }}"
      frontend:
        loadBalancer:
          servers:
            - url: "http://{{ .Release.Name }}.{{ .Release.Namespace }}.svc.cluster.local:80"
{{ end }}
{{ end }}


{{- end }}
