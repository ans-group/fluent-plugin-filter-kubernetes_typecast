# fluent-plugin-filter-kubernetes_typecast

#### Readme WIP

This plugin allows for records to be typecasted based on pod metadata, and is to be used in conjunction with the [kubernetes metadata](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter) filter.

It is assumed that pods will be logging in JSON format, and parsed by the fluentd `json` parser. 

# Installing

### TODO

# Configuring

Fluentd should be configured with the kubenetes metadata filter mentioned above, with `annotation_match` specified (to add the required annotation `fluentd.ukfast.io/field-types` to the record):

```xml
    <filter kubernetes.**>
      @id filter_kubernetes_metadata
      @type kubernetes_metadata
      annotation_match [ "fluentd.+"]
    </filter>
```

Next, pods which require record typecasting should have the following annotation defined. This annotation has a JSON value mapping record keys to required cast type:

```yaml
fluentd.ukfast.io/field-types: '{"record_key_here":"string"}'
```

The following types are currently available for typecasting:

* `string`
* `integer`
* `float`