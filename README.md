# HX-layout

## Unit Tests

When writing tests for applications which use one of our internal ```hx-*``` components - include the following in the package.json within the jest section.

```
"transformIgnorePatterns": [
	"node_modules/(?!(vue2-timepicker|hx-))"
],
```

The default value for this option is ```/node_modules/```. Changing the above value means the transform will be ignored for all node modules, except for those that have the ```hx-``` prefix.
