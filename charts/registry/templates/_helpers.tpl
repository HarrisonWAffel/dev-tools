{{/*
Release name, truncated to 63 characters (Kubernetes label limit).
*/}}
{{- define "registry.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard Kubernetes labels applied to all resources.
*/}}
{{- define "registry.labels" -}}
app.kubernetes.io/name: registry
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/*
Selector labels — used by Service and Deployment selectors.
*/}}
{{- define "registry.selectorLabels" -}}
app.kubernetes.io/name: registry
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
