<template>
  <div class="time-allocation-drop-down">
    <DropDown
      class="tc-drop-down"
      :class="group"
      :value="value"
      :options="materialTypeOptions"
      label="name"
      :placeholder="placeholder"
      :direction="direction"
      :disabled="disabled"
      :holdOpen="holdOpen"
      @change="onChange"
    >
      <template slot-scope="data">
        <div class="tc" :class="data.class">
          <div class="label">{{ data.name }}</div>
        </div>
      </template>
    </DropDown>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { attributeFromList } from '@/code/helpers';
import { DropDown } from 'hx-vue';

function getGroup(materialTypeCode) {
  const GROUPS = {
    1: 'topsoil',
    2: 'overburden',
    3: 'ab-coal',
    4: 'interburden',
    5: 'c-coal',
    6: 'd-coal',
    7: 'f-coal',
  };

  return GROUPS[materialTypeCode] || 'default';
}

export default {
  name: 'MaterialDropDown',
  components: {
    DropDown,
  },
  props: {
    value: Number,
    showAll: { type: Boolean, default: false },
    direction: { type: String, default: 'auto' },
    placeholder: { type: String, default: 'select Material Type' },
    disabled: { type: Boolean, deafult: false },
    holdOpen: { type: Boolean, default: false },
  },
  computed: {
    ...mapState('constants', {
      materialTypes: state => state.materialTypes,
    }),
    group() {
      const [materialTypeCode] = attributeFromList(this.materialTypes, 'id', this.value, [
        'materialTypeCode',
      ]);
      return getGroup(materialTypeCode);
    },
    materialTypeOptions() {
      const materialTypes = this.materialTypes.map(material => {
        const materialGroup = getGroup(material.materialTypeCode);
        material.class = materialGroup;
        return material;
      });
      return [{ id: null, name: 'None' }].concat(materialTypes);
    },
  },
  methods: {
    onChange(materialTypeId) {
      this.$emit('input', materialTypeId);
      this.$emit('change', materialTypeId);
    },
  },
};
</script>

<style>
.tc-drop-down.drop-down .dd-option {
  padding: 0;
}

.tc-drop-down,
.tc-drop-down .dd-option .tc {
  border-left: 10px solid #425866;
}

.tc-drop-down .dd-option .tc .label {
  padding: 0.2rem;
}

.tc-drop-down.topsoil,
.tc-drop-down .dd-option .tc.topsoil {
  border-left-color: #dedc57;
}

.tc-drop-down.overburden,
.tc-drop-down .dd-option .tc.overburden {
  border-left-color: #d4c311;
}

.tc-drop-down.ab-coal,
.tc-drop-down .dd-option .tc.ab-coal {
  border-left-color: #8a8786;
}

.tc-drop-down.interburden,
.tc-drop-down .dd-option .tc.interburden {
  border-left-color: #0e55cf;
}

.tc-drop-down.c-coal,
.tc-drop-down .dd-option .tc.c-coal {
  border-left-color: #de8e0d;
}

.tc-drop-down.d-coal,
.tc-drop-down .dd-option .tc.d-coal {
  border-left-color: #10b0eb;
}

.tc-drop-down.f-coal,
.tc-drop-down .dd-option .tc.f-coal {
  border-left-color: #3bf00a;
}

.tc-drop-down.default,
.tc-drop-down .dd-option .tc.default {
  border-left-color: grey;
}
</style>
