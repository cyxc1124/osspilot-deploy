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

{{- define "osspilot.image" -}}
{{- $tag := .Values.image.tag | default .Values.global.imageTag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
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

{{- define "osspilot.ingressTlsSecret" -}}
{{- $svc := index . "svc" -}}
{{- $ing := index . "ing" -}}
{{- if $ing.tlsSecretName -}}
{{- $ing.tlsSecretName -}}
{{- else -}}
{{- printf "%s-tls" $svc -}}
{{- end -}}
{{- end }}

{{- define "osspilot.ingress" -}}
{{- $svc := index . "svc" -}}
{{- $port := index . "port" -}}
{{- $ing := index . "ing" -}}
{{- $root := index . "root" -}}
{{- $issuer := "" -}}
{{- if and $ing.certManager $ing.certManager.clusterIssuer -}}
{{- $issuer = $ing.certManager.clusterIssuer -}}
{{- end -}}
{{- if $ing.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $svc }}
  labels:
    {{- include "osspilot.labels" $root | nindent 4 }}
  annotations:
    {{- if $issuer }}
    cert-manager.io/cluster-issuer: {{ $issuer | quote }}
    {{- end }}
    {{- with $ing.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if $ing.className }}
  ingressClassName: {{ $ing.className | quote }}
  {{- end }}
  {{- if or $ing.tlsSecretName $issuer }}
  tls:
    - hosts:
        - {{ $ing.host | quote }}
      secretName: {{ include "osspilot.ingressTlsSecret" (dict "svc" $svc "ing" $ing) | quote }}
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
{{- if and $ing.host $ing.ingressRoute $ing.ingressRoute.http }}
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ $svc }}-http
  labels:
    {{- include "osspilot.labels" $root | nindent 4 }}
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`{{ $ing.host }}`)
      kind: Rule
      priority: 1
      services:
        - name: {{ $svc }}
          port: {{ $port }}
{{- end }}
{{- end }}
