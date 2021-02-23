<template>
  <Button
    class="button nested-dropdown"
    :text="defaultText"
    :width="width"
    :height="height"
    :textWrap="textWrap"
    @tap="onOpenModal"
  />
</template>

<script>
import NestedDropdownModal from './modals/NestedDropdownModal.vue';
import CenteredLabel from './CenteredLabel.vue';

export default {
  name: 'NestedDropdown',
  components: {
    CenteredLabel,
  },
  props: {
    value: { type: Object, default: null },
    options: { type: Array, default: () => [] },
    width: { type: [String, Number], default: '' },
    height: { type: [String, Number], default: '' },
    textWrap: { type: Boolean, default: false },
    itemHeight: { type: Number, default: undefined },
    fallbackText: { type: String, default: '' },
  },
  computed: {
    defaultText() {
      if (this.value && this.value.value) {
        return this.value.value;
      }
      return this.fallbackText;
    },
  },
  methods: {
    onOpenModal() {
      const opts = {
        options: this.options,
        selected: this.value,
        itemHeight: this.itemHeight,
      };

      this.$modalBus.open(NestedDropdownModal, opts).onClose(payload => {
        if (!payload || !payload.selected.timeCodeId) {
          return;
        }

        const selected = { ...payload.selected, ...{ children: undefined } };
        this.$emit('input', selected);
      });
    },
  },
};
</script>

<style>
</style>