{{- define "osspilot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "osspilot.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "osspilot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "osspilot.labels" -}}
helm.sh/chart: {{ include "osspilot.chart" . }}
{{ include "osspilot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: osspilot
{{- end }}

{{- define "osspilot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "osspilot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "osspilot.imageTag" -}}
{{- .Values.global.imageTag | default .Chart.AppVersion }}
{{- end }}

{{- define "osspilot.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "osspilot.fullname" .) }}
{{- end }}
{{- end }}

{{- define "osspilot.tenantApiUrl" -}}
{{- if .Values.ops.api.tenantApiUrl }}
{{- .Values.ops.api.tenantApiUrl }}
{{- else }}
{{- printf "http://%s-tenant-api:%v" (include "osspilot.fullname" .) .Values.tenant.api.service.port }}
{{- end }}
{{- end }}

{{- define "osspilot.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "osspilot.placement" -}}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "osspilot.ingress" -}}
{{- $svc := index . "svc" -}}
{{- $port := index . "port" -}}
{{- $ing := index . "ing" -}}
{{- $root := index . "root" -}}
{{- if $ing.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $svc }}
  labels:
    {{- include "osspilot.labels" $root | nindent 4 }}
  {{- with $ing.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $ing.className }}
  ingressClassName: {{ $ing.className | quote }}
  {{- end }}
  {{- if $ing.tlsSecretName }}
  tls:
    - hosts:
        - {{ $ing.host | quote }}
      secretName: {{ $ing.tlsSecretName | quote }}
  {{- end }}
  rules:
    - host: {{ $ing.host | quote }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ $svc }}
                port:
                  number: {{ $port }}
{{- end }}
{{- end }}
