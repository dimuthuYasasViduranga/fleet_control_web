<template>
  <div class="form">
    <component
      v-for="elem in elements"
      :key="elem.key"
      :is="elem.component"
      :wrapper="elem"
      :value="v[elem.key].$model"
      :v="v[elem.key]"
      v-bind="elem.props || {}"
      @input="onInputChange(elem.key, v[elem.key], $event)"
    />
  </div>
</template>

<script>
import ErrorLabel from './ErrorLabel.vue';
import ViewField from './ViewField.vue';
import InputField from './InputField.vue';
import DatetimeField from './DatetimeField.vue';
import CheckboxField from './CheckboxField.vue';
import RadioField from './RadioField.vue';
import DropDownField from './DropDownField.vue';
import AutocompleteField from './AutocompleteField.vue';

const COMPONENTS = {
  view: ViewField,
  input: InputField,
  datetime: DatetimeField,
  checkbox: CheckboxField,
  radio: RadioField,
  dropdown: DropDownField,
  autocomplete: AutocompleteField,
};

function getErrors(layout, rootV, v, parser) {
  const paramMap = Object.entries(v.$params)
    .map(([key, params]) => {
      return {
        key,
        type: params.type,
        params,
      };
    })
    .filter(e => e.type);

  const errors = paramMap.reduce((acc, p) => {
    const msgCallback = parser[p.type];

    if (msgCallback && !v[p.key]) {
      if (typeof msgCallback === 'string') {
        acc.push(msgCallback);
      } else {
        acc.push(msgCallback({ params: p.params, v, rootV, layout }));
      }
    }

    return acc;
  }, []);

  return parser.$showAll !== false ? errors : errors.slice(0, 1);
}

export default {
  name: 'Form',
  components: {
    ErrorLabel,
    ViewField,
    InputField,
    DatetimeField,
    CheckboxField,
    RadioField,
    DropDownField,
    AutocompleteField,
  },
  props: {
    v: { type: Object, required: true },
    layout: { type: Object, required: true },
    parser: { type: Object, default: () => ({}) },
    autoValidate: { type: Boolean, default: true },
  },
  computed: {
    elements() {
      return Object.entries(this.layout)
        .map(([key, config]) => {
          const component = config.component || COMPONENTS[config.type];
          const label = config.label;
          const parser = { ...this.parser, ...(config.parser || {}) };
          const errors = getErrors(this.layout, this.v, this.v[key], parser);
          return {
            show: !config.showIf || config.showIf(this.v.$model),
            key,
            label,
            info: config.info,
            component,
            props: config.props,
            errors,
          };
        })
        .filter(e => e.component);
    },
  },
  methods: {
    onInputChange(key, v, value) {
      if (v.$model === value) {
        return;
      }
      v.$model = value;
      if (!this.autoValidate) {
        v.$reset();
      }
      this.$emit('change', { key, v, value });
    },
  },
};
</script>
