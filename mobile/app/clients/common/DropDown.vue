<template>
  <GridLayout class="dropdown">
    <StackLayout>
      <Button
        class="dropdown-btn"
        height="100%"
        :text="text"
        :disabled="disabled"
        :textTransform="textTransform"
        @tap="open"
        :isEnabled="isEnabled"
      />
    </StackLayout>

    <CenteredLabel
      class="dropdown-btn-ellipses"
      horizontalAlignment="right"
      width="60"
      :text="ellipses"
      @tap="open"
    />
  </GridLayout>
</template>

<script>
import DropDownModal from './modals/DropDownModal.vue';
import CenteredLabel from './CenteredLabel.vue';
import { attributeFromList } from '../code/helper';

function toOption(option, label) {
  if (typeof option === 'string') {
    return { id: option, text: option };
  }
  return { id: option.id, text: option[label] };
}

export default {
  name: 'DropDown',
  components: {
    CenteredLabel,
  },
  props: {
    value: undefined,
    label: { type: String, default: 'text' },
    options: { type: Array, default: () => [] },
    disabled: { type: Boolean, default: false },
    filter: { type: String, default: undefined },
    allowInput: { type: Boolean, default: false },
    disableEmpty: { type: Boolean, default: false },
    keyboardType: { type: String, default: undefined },
    textTransform: { type: String, default: 'capitalize' },
  },
  data: () => {
    return {
      isOpen: false,
      ellipses: `\u2219\u2219\u2219`,
    };
  },
  computed: {
    isEnabled() {
      return !this.disableEmpty || this.options.length > 0;
    },
    formattedOptions() {
      return this.options.map(o => toOption(o, this.label));
    },
    selectedOption() {
      return attributeFromList(this.formattedOptions, 'id', this.value);
    },
    text() {
      return (this.selectedOption || {}).text;
    },
  },
  methods: {
    close() {
      this.isOpen = false;
      this.$emit('close');
    },
    open() {
      if (!this.isOpen) {
        this.isOpen = true;
        this.$emit('open');

        const opts = {
          selected: this.value,
          options: this.formattedOptions,
          filter: this.filter,
          allowInput: this.allowInput,
          keyboardType: this.keyboardType,
        };

        this.$modalBus
          .open(DropDownModal, opts)
          .onClose(option => {
            if (option) {
              if (this.allowInput) {
                this.$emit('input', option);
                this.$emit('select', option);
              } else {
                this.$emit('input', option.id);
                this.$emit('select', option.id);
              }
            }

            this.close();
          })
          .onTerminate(() => {
            this.close();
          });
      }
    },
  },
};
</script>

<style>
.dropdown {
  width: 100%;
  height: 100%;
}

.dropdown .dropdown-btn-ellipses {
  color: black;
}

.dropdown .dropdown-btn[isEnabled='false'] {
  background-color: lightgray;
  opacity: 0.3;
}
</style>