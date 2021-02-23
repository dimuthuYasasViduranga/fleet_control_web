<template>
  <StackLayout class="search-modal">
    <ScrollView height="100" class="search-list" orientation="horizontal">
      <StackLayout height="60" orientation="horizontal">
        <Button
          class="letter"
          :class="{ selected: letter === searchLetter }"
          v-for="(letter, index) in letters"
          :key="index"
          :text="letter"
          @tap="onLetterSelect(letter)"
        />
      </StackLayout>
    </ScrollView>
    <CenteredLabel
      v-if="value"
      class="option null-option"
      :text="nullName"
      textAlignment="left"
      @tap="close({ id: null, value: nullName })"
    />
    <ListView ref="scrollable" class="option-list" for="item in filteredOptions">
      <v-template>
        <CenteredLabel
          class="option"
          :class="{ selected: item.id === value }"
          :text="item.value"
          textAlignment="left"
          @tap="close(item)"
        />
      </v-template>
    </ListView>
  </StackLayout>
</template>

<script>
import CenteredLabel from '../CenteredLabel.vue';
import { uniq } from '../../code/helper';

const SPECIAL_CHARACTERS = ['(', '*', '?', '/', '['];
export default {
  name: 'SearchModal',
  components: {
    CenteredLabel,
  },
  props: {
    value: { type: undefined, default: null },
    nullName: { type: String, default: 'Clear' },
    options: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      searchLetter: 'All',
    };
  },
  computed: {
    filteredOptions() {
      switch (this.searchLetter) {
        case 'All':
          return this.options;
        case 'Other':
          return this.options.filter(o => {
            const letter = (o.value[0] || '').toLowerCase();
            return SPECIAL_CHARACTERS.includes(letter);
          });
      }
      return this.options.filter(o => (o.value[0] || '').toUpperCase() === this.searchLetter);
    },
    letters() {
      const letters = this.options.map(({ value }) => {
        const letter = (value[0] || '').toUpperCase();
        if (SPECIAL_CHARACTERS.includes(letter)) {
          return 'Other';
        }
        return letter;
      });

      const uniqLetters = uniq(letters);
      uniqLetters.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

      uniqLetters.unshift('All');
      return uniqLetters;
    },
  },
  mounted() {
    this.$modalBus.onTerminate(this.close);
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onLetterSelect(letter) {
      this.searchLetter = letter || 'All';
    },
  },
};
</script>

<style>
.search-modal {
  background-color: white;
  height: 80%;
  width: 600;
  padding: 20 60;
}

.search-modal .option {
  height: 60;
  font-size: 26;
  color: #0c1419;
}

.search-modal .null-option {
  font-style: italic;
}

.search-modal .search-list {
  border-bottom-width: 1;
  border-bottom-color: black;
}

.search-modal .option.selected {
  background-color: slategray;
}

.search-modal .search-list .letter {
  font-size: 30;
}

.search-modal .search-list .letter.selected {
  background-color: slategray;
  color: white;
}
</style>