<template>
  <Stacklayout class="dropdown-modal" :height="height" verticalAlignment="top">
    <ScrollView
      v-if="filter === 'simple' && localOptions.length > 0"
      class="simple-list"
      orientation="horizontal"
    >
      <StackLayout height="100%" orientation="horizontal">
        <Button
          class="letter"
          v-for="(letter, index) in letters"
          :key="index"
          :class="{ selected: letter === search }"
          :text="letter || 'All'"
          @tap="onLetterSelect(letter)"
        />
      </StackLayout>
    </ScrollView>

    <GridLayout
      v-else-if="filter === 'text' && localOptions.length > 0"
      columns="8* *"
      class="search-bar-wrapper"
    >
      <TextField col="0" class="search-bar" v-model="search" hint="Search" />
      <CenteredLabel class="x" col="1" text="X" @tap="search = ''" />
    </GridLayout>

    <GridLayout v-if="allowInput" class="custom-entry" columns="6* *">
      <TextField class="text-field" :keyboardType="keyboardType" v-model="customInput" />
      <Button class="add-new" col="1" text="Add New" @tap="onAddNew" :isEnabled="!!customInput" />
    </GridLayout>

    <StackLayout class="option-list-wrapper">
      <ListView ref="scrollable" class="option-list" for="option in filteredOptions">
        <v-template>
          <Button
            class="option"
            :class="{ selected: option.id === selected }"
            :text="option.text"
            @tap="onSelect(option)"
          />
        </v-template>
      </ListView>
    </StackLayout>
  </Stacklayout>
</template>

<script>
import { isInText, uniq } from '../../code/helper';
import CenteredLabel from '../../common/CenteredLabel.vue';
export default {
  name: 'DropDownModal',
  components: {
    CenteredLabel,
  },
  props: {
    selected: { type: undefined, default: null },
    options: { type: Array, default: () => [] },
    filter: { type: String, default: '' },
    keyboardType: { type: String, default: undefined },
    allowInput: { type: Boolean, default: false },
  },
  data: () => {
    return {
      search: '',
      customInput: '',
      localOptions: [],
    };
  },
  computed: {
    height() {
      if (this.filter) {
        return '80%';
      }
      return 'auto';
    },
    filteredOptions() {
      const options = this.localOptions;
      if (!this.search) {
        return options;
      }

      if (this.filter === 'simple') {
        return options.filter(o => o.text.startsWith(this.search));
      }

      return options.filter(o => isInText(o.text, this.search));
    },
    letters() {
      const letters = this.localOptions.map(o => (o.text[0] || '').toUpperCase());
      const uniqLetters = uniq(letters);
      uniqLetters.sort((a, b) => (a || '').toLowerCase().localeCompare((b || '').toLowerCase()));
      uniqLetters.unshift('');
      return uniqLetters;
    },
  },
  mounted() {
    this.localOptions = this.options.slice();

    if (this.filter === 'simple' && this.selected) {
      const option = this.localOptions.find(o => o.id === this.selected);
      if (option) {
        this.search = option.text[0] || '';
      }
    }
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onSelect(option) {
      this.close(option);
    },
    onLetterSelect(letter) {
      this.search = letter || '';
    },
    onAddNew() {
      const text = this.customInput;
      const existing = this.localOptions.find(o => o.text === text);
      if (existing || !text) {
        return;
      }

      this.localOptions.push({ id: text, text, new: true });
      this.localOptions = this.localOptions.slice();
      this.customInput = '';
    },
  },
};
</script>

<style>
.dropdown-modal {
  background-color: white;
  width: 70%;
}

.dropdown-modal .simple-list {
  margin: 10;
  height: 60;
}

.dropdown-modal .custom-entry {
  margin: 10;
  height: 60;
}

.dropdown-modal .custom-entry .text-field {
  height: 100%;
}

.dropdown-modal .custom-entry .add-new[isEnabled='false'] {
  background-color: lightgray;
  opacity: 0.3;
}

.dropdown-modal .search-bar-wrapper {
  height: 50;
  margin: 10 50;
}

.dropdown-modal .search-bar-wrapper .x {
  color: black;
}

.dropdown-modal .simple-list .letter.selected {
  background-color: slategray;
  color: white;
}

.dropdown-modal .option-list-wrapper {
  height: auto;
  width: 100%;
  padding: 10 50;
}

.dropdown-modal .option {
  font-size: 25;
  height: 60;
}

.dropdown-modal .option.selected {
  background-color: lightslategray;
  color: white;
}
</style>