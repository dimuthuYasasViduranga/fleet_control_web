<template>
  <div class="debug2-page">
    <hxCard title="Dropdowns">
      {{ value || '--' }}
      <DropDown class="dd-a" v-model="value" :options="options" label="name" />
      <DropDown class="dd-b" v-model="value" :options="options" label="name" />
      <DropDown class="dd-b dd-e" v-model="value" :options="options" label="name">
        <template slot-scope="option">
          <div :class="option.class">{{ option.name }}</div>
        </template>
      </DropDown>

      <DropDown
        class="dd-b dd-e"
        v-model="value"
        :options="options"
        label="name"
        :useTouch="true"
      />

      <DropDown class="dd-b dd-short" v-model="value" :options="options" label="name" />
      <DropDown class="dd-b dd-really-short" v-model="value" :options="options" label="name" />

      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <br />
    </hxCard>
  </div>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import { DropDown } from 'hx-vue';

export default {
  name: 'Debug2',
  components: {
    hxCard,
    DropDown,
  },
  data: () => {
    return {
      value: null,
      options: [
        {
          id: 1,
          name: 'A monkey and the biggest thing around the lorem ipsikasf ;aease ;lksdfa slkjasef ljs;lefa ;lkjsdfa asefkljsaef and the lorme ipsum',
          class: 'red',
        },
        { id: 2, name: 'B', class: 'blue' },
        { id: 3, name: 'C', class: 'blue' },
        { id: 4, name: 'D', class: 'red' },
        { id: 5, name: 'E', class: 'red' },
      ],
    };
  },
};
</script>

<style>
.dd-short {
  width: 20rem;
}

.dd-really-short {
  width: 5rem;
}

.dd-b .dd-option {
  padding: 0;
}

.dd-b .dd-option > * {
  border-left: 10px solid transparent;
  padding: 0.25rem;
}

.dd-b .dd-option .red {
  color: red;
}

.dd-b .dd-option .blue {
  color: blue;
  border-left-color: orange;
}
</style>