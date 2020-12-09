# fluent-plugin-filter-kubernetes_typecast

This plugin allows for records to be typecasted based on pod metadata, and is to be used in conjunction with the [kubernetes metadata](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter) filter.

It is assumed that pods will be logging in JSON format, and parsed by the fluentd `json` parser. 

# Installing

This plugin can be installed via `gem`:

```
gem install fluent-plugin-filter-kubernetes_typecast
```

# Configuring

Fluentd should be configured with the kubernetes metadata filter mentioned above, with `annotation_match` specified (to add the required annotation `fluentd.ukfast.io/field-types` to the record):

```xml
<filter kubernetes.**>
    @id filter_kubernetes_metadata
    @type kubernetes_metadata
    annotation_match [ "fluentd.+"]
</filter>
```

Next, the typecast filter should be added:

```xml  
<filter kubernetes.**>
  @type kubernetes_typecast
</filter>
```

Finally, pods which require record typecasting should have the following annotation defined. This annotation has a JSON value, mapping record keys to required cast type:

```yaml
fluentd.ukfast.io/field-types: '{"record_key_here":"string"}'
```

The following types are currently available for typecasting:

* `string`
* `integer`
* `float`

## Namespace annotations

Namespace annotations are also supported. If the `fluentd.ukfast.io/field-types` annotation is specified on the namespace but not on a pod, 
this annotation will be used. If this annotation is also specified on a pod, the pod annotation will take precedence.

The following annotation can be added to a pod to instruct the plugin to merge the field-types annotations:

```yaml
fluentd.ukfast.io/merge-namespace-field-types: "true"
```