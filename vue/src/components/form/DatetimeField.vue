<template>
  <FieldWrapper class="datetime-field" :v="v" v-bind="wrapper">
    <div class="wrapper">
      <Dately
        :value="value"
        :timezone="timezone"
        :minDatetime="minDatetime"
        :maxDatetime="maxDatetime"
        @input="onChange"
      />
      <div v-if="clearable" class="clear-icon-wrapper" @click="onChange(null)">
        <Icon :icon="errorIcon" />
      </div>
    </div>
  </FieldWrapper>
</template>



<script>
import FieldWrapper from './FieldWrapper.vue';
import Dately from '@/components/dately/Dately.vue';
import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';

export default {
  name: 'DatetimeField',
  components: {
    FieldWrapper,
    Dately,
    Icon,
  },
  props: {
    wrapper: { type: Object, required: true },
    value: { type: Date },
    v: { type: Object, default: () => ({}) },
    timezone: String,
    minDatetime: [Object, Date, String],
    maxDatetime: [Object, Date, String],
    clearable: { type: Boolean, default: false },
  },
  data: () => {
    return {
      errorIcon: ErrorIcon,
    };
  },
  methods: {
    onChange(value) {
      this.$emit('input', value);
    },
  },
};
</script>

<style>
.datetime-field .wrapper {
  height: 2rem;
  display: flex;
}

.datetime-field .wrapper .clear-icon-wrapper:hover {
  cursor: pointer;
  opacity: 0.5;
}

.datetime-field .wrapper .clear-icon-wrapper .hx-icon svg {
  padding-left: 10px;
}

.datetime-field.error .date-button {
  border: 2px solid #bd1d1d;
  border-right: none;
}

.datetime-field.error .dately__time-component {
  border: 2px solid #bd1d1d;
  border-left: none;
}
</style>