<template>
  <div class="pre-start-control">
    <Icon class="drag-handle" :icon="hamburgerIcon" />
    <input
      ref="control-input"
      class="label typeable"
      placeholder="Criteria"
      v-model="data.label"
      @keydown="onKeyDown"
    />
    <DropDown
      class="category"
      v-model="data.categoryId"
      :items="categories"
      label="fullname"
      selectedLabel="name"
      placeholder="Category"
    />
    <Icon
      class="comment-toggle"
      :class="{ dim: !data.requiresComment }"
      v-tooltip="data.requiresComment ? 'Comment Required' : 'Comment Not Required'"
      :icon="commentIcon"
      @click="onToggleRequiresComment()"
    />
    <Icon v-tooltip="'Remove'" class="remove-icon" :icon="crossIcon" @click="onRemove()" />
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import HamburgerIcon from '@/components/icons/Hamburger.vue';
import DropDown from '@/components/dropdown/DropDown.vue';
import CommentIcon from '@/components/icons/Comment.vue';

const ENTER = 13;

export default {
  name: 'Control',
  components: {
    Icon,
    DropDown,
  },
  props: {
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
      this.data.requiresComment = !this.data.requiresComment;
    },
  },
};
</script>

<style>
.pre-start-control {
  display: grid;
  grid-template-columns: 3rem auto 7rem 2.5rem 2rem;
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

.pre-start-control .category {
  width: 7rem;
}
</style>