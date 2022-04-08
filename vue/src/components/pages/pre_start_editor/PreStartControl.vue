<template>
  <!-- eslint-disable vue/no-mutating-props -->
  <div class="pre-start-control">
    <Icon class="drag-handle" :icon="hamburgerIcon" />
    <input
      ref="control-input"
      class="label typeable"
      placeholder="Criteria"
      :disabled="readonly"
      v-model="data.label"
      @keydown="onKeyDown"
    />
    <DropDown
      v-tooltip="{
        content: getCategoryAction(data.categoryId),
        classes: ['__ps_control_category_tooltip'],
      }"
      class="category"
      v-model="data.categoryId"
      :options="categories"
      label="fullname"
      placeholder="Category"
      :disabled="readonly"
    >
      <template slot="selected-option" slot-scope="data">
        {{ data.name }}
      </template>
    </DropDown>
    <Icon
      class="comment-toggle"
      :class="{ dim: !data.requiresComment }"
      v-tooltip="data.requiresComment ? 'Comment Required' : 'Comment Not Required'"
      :icon="commentIcon"
      @click="onToggleRequiresComment()"
    />
    <Icon
      v-if="!readonly"
      v-tooltip="'Remove'"
      class="remove-icon"
      :icon="crossIcon"
      @click="onRemove()"
    />
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import { DropDown } from 'hx-vue';
import HamburgerIcon from '@/components/icons/Hamburger.vue';
import CommentIcon from '@/components/icons/Comment.vue';
import { attributeFromList } from '@/code/helpers';

const ENTER = 13;

export default {
  name: 'Control',
  components: {
    Icon,
    DropDown,
  },
  props: {
    readonly: Boolean,
    data: { type: Object, required: true },
  },
  data: () => {
    return {
      crossIcon: ErrorIcon,
      hamburgerIcon: HamburgerIcon,
      commentIcon: CommentIcon,
    };
  },
  computed: {
    categories() {
      const cats = this.$store.state.constants.preStartControlCategories;
      return [{ id: null, name: 'None' }].concat(cats).map(c => {
        const fullname = c.action ? `${c.name} (${c.action})` : c.name;
        return {
          id: c.id,
          name: c.name,
          action: c.action,
          fullname,
        };
      });
    },
  },
  mounted() {
    if (this.data.setFocus) {
      this.$refs['control-input'].focus();
      delete this.data.setFocus;
    }
  },
  methods: {
    onRemove() {
      this.$emit('remove');
    },
    onKeyDown(event) {
      if (event.keyCode === ENTER) {
        this.$emit('enter', event);
      }
    },
    onToggleRequiresComment() {
      if (this.readonly) {
        return;
      }
      // eslint-disable-next-line vue/no-mutating-props
      this.data.requiresComment = !this.data.requiresComment;
    },
    getCategoryAction(id) {
      return attributeFromList(this.categories, 'id', id, 'action');
    },
  },
};
</script>

<style>
.pre-start-control {
  display: grid;
  grid-template-columns: 3rem auto 10rem 2.5rem 2rem;
  margin: 0.25rem;
  padding: 0.5rem;
  background-color: #23343f;
}

.pre-start-control .drag-handle {
  cursor: pointer;
  width: 2rem;
  height: 100%;
  padding: 0.5rem;
}

.pre-start-control .remove-icon {
  cursor: pointer;
  height: 2rem;
  padding: 0.5rem;
}

.pre-start-control .remove-icon:hover {
  stroke: red;
}

.pre-start-control .comment-toggle {
  cursor: pointer;
  height: 2rem;
  padding: 0.2rem;
  padding-left: 0.5rem;
  padding-right: 0;
}

.pre-start-control .comment-toggle svg {
  stroke-width: 1.2;
}

.pre-start-control .comment-toggle.dim {
  opacity: 0.2;
}

.pre-start-control .comment-toggle:hover {
  opacity: 0.75;
}

.pre-start-form-editor .dropdown-wrapper .fixed-div {
  width: 14rem !important;
}

.__ps_control_category_tooltip {
  max-width: 14rem;
  text-align: center;
}
</style>