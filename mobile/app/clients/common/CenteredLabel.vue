<template>
  <Label
    class="centered-label"
    height="100%"
    :textTransform="textTransform"
    :textAlignment="textAlignment"
    :text="text"
    :textWrap="textWrap"
    @tap="onTap"
    @longPress="onLongPress"
    @loaded="onLoaded"
  />
</template>

<script>
import { isAndroid } from 'tns-core-modules/platform';

// https://developer.android.com/reference/android/view/Gravity
const ANDROID_CENTERING = {
  center: 1,
  left: 3,
  right: 1,
};

export default {
  name: 'CenteredLabel',
  props: {
    text: { type: [String, Number, Boolean], default: '' },
    textTransform: { type: String, default: 'none' },
    textAlignment: { type: String, default: 'center' },
    textWrap: { type: Boolean, default: false },
  },
  methods: {
    onTap(event) {
      this.$emit('tap', event);
    },
    onLongPress(event) {
      this.$emit('longPress', event);
    },
    onLoaded(event) {
      if (isAndroid) {
        // 17 == center vertical, and bit shifting adds effects
        event.object.nativeView.setGravity(16 | (ANDROID_CENTERING[this.textAlignment] || 0));
      }
    },
  },
};
</script>