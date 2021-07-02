<template>
  <div class="pre-start-category-editor">
    <div class="actions">
      <button class="hx-btn" @click="onReset()">Reset</button>
      <button class="hx-btn" @click="onSubmit()">Submit</button>
    </div>
    <div class="header">
      <table class="item">
        <td class="name">Category Name</td>
        <td class="action">Action on Failure</td>
        <td class="edit"></td>
      </table>
    </div>
    <div class="list">
      <Container
        class="category-container"
        group-name="category"
        :drop-placeholder="containerPlaceholderOptions"
        :get-child-payload="sourcePayload"
        lock-axis="y"
        @drop="onDrop"
      >
        <Draggable v-for="(item, index) in localCategories" :key="index">
          <table class="item">
            <tr>
              <td class="name">{{ item.name }}</td>
              <td class="action" :class="{ italic: !item.action }">
                {{ item.action || '-- No Action --' }}
              </td>
              <td class="edit">
                <Icon v-tooltip="'Edit'" class="edit-icon" :icon="editIcon" @click="onEdit(item)" />
              </td>
            </tr>
          </table>
        </Draggable>
      </Container>
    </div>
    <div class="notice">* Dropdowns are ordered as submitted</div>
    <button class="hx-btn" @click="onAddNew()">Add New</button>
  </div>
</template>

<script>
import { Container, Draggable } from 'vue-smooth-dnd';
import Icon from 'hx-layout/Icon.vue';
import CategoryEditorModal from './CategoryEditorModal.vue';
import ConfirmModal from '@/components/modals/ConfirmModal';

import EditIcon from '@/components/icons/Edit.vue';

function toLocalCategory(cat) {
  return {
    id: cat.id,
    name: cat.name,
    action: cat.action,
  };
}

function moveTo(arr, fromIndex, toIndex) {
  if (fromIndex === toIndex) {
    return arr;
  }

  const newArr = [...arr];

  const movedItem = newArr[fromIndex];

  newArr.splice(fromIndex, 1);

  newArr.splice(toIndex, 0, movedItem);

  return newArr;
}

export default {
  name: 'PreStartCategoryEditor',
  components: {
    Container,
    Draggable,
    Icon,
  },
  data: () => {
    return {
      editIcon: EditIcon,
      localCategories: [],
      containerPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    categories() {
      return this.$store.state.constants.preStartControlCategories;
    },
  },
  watch: {
    categories: {
      immediate: true,
      handler(cats = []) {
        if (this.localCategories.length === 0 && cats.length !== 0) {
          this.setLocalCategories(cats);
        }
      },
    },
  },
  methods: {
    setLocalCategories(cats) {
      this.localCategories = cats
        .slice()
        .sort((a, b) => a.order - b.order)
        .map(toLocalCategory);
    },
    sourcePayload(index) {
      return this.localCategories[index];
    },
    onDrop(dropResult) {
      this.localCategories = moveTo(
        this.localCategories,
        dropResult.removedIndex,
        dropResult.addedIndex,
      );
    },
    onReset() {
      this.setLocalCategories(this.categories);
    },
    onEdit(item) {
      const existingNames = this.localCategories.filter(c => c.id !== item.id).map(c => c.name);
      this.$modal.create(CategoryEditorModal, { category: item, existingNames }).onClose(resp => {
        if (resp) {
          Object.assign(item, resp);
        }
      });
    },
    onAddNew() {
      const existingNames = this.localCategories.map(c => c.name);

      this.$modal.create(CategoryEditorModal, { existingNames }).onClose(resp => {
        if (resp) {
          this.localCategories.push(resp);
        }
      });
    },
    onSubmit() {
      const opts = {
        title: 'Update Categories',
        body: 'These changes will affect all assets\n\nDo you want to proceed?',
        ok: 'yes',
        cancel: 'no',
      };
      this.$modal.create(ConfirmModal, opts).onClose(resp => {
        if (resp === 'yes') {
          this.submit(this.localCategories);
        }
      });
    },
    submit(categories) {
      const payload = categories.map((c, index) => {
        return {
          id: c.id,
          name: c.name,
          action: c.action,
          order: index,
        };
      });

      this.$channel
        .push('pre-start:update control categories', payload)
        .receive('ok', () => {
          this.onReset();
          this.$toaster.info('Categories updated');
        })
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', resp =>
          this.$toaster.noComms('Unable to update categories at this time'),
        );
    },
  },
};
</script>

<style>
.pre-start-category-editor {
  padding-bottom: 1rem;
}

.pre-start-category-editor .notice {
  font-style: italic;
  padding-bottom: 0.25rem;
}

.pre-start-category-editor .header {
  font-size: 1.25rem;
  height: 2rem;
  line-height: 2rem;
  background-color: #2f404b;
  text-align: center;
}

.pre-start-category-editor .item {
  width: 100%;
}

.pre-start-category-editor .item .name {
  width: 10rem;
}

.pre-start-category-editor .item .edit {
  width: 2rem;
}

.pre-start-category-editor .item .edit .edit-icon {
  cursor: pointer;
  margin: auto;
  width: 1.25rem;
}

.pre-start-category-editor .item .action.italic {
  font-style: italic;
  opacity: 0.75;
}

.pre-start-category-editor .item .edit-icon:hover {
  stroke: orange;
}

/* ------ drag and drop wrappers ----- */
.pre-start-category-editor .smooth-dnd-draggable-wrapper {
  cursor: pointer;
  background-color: #283741;
  width: 100%;
  font-size: 1.25rem;
  text-align: center;
  min-height: 2rem;
  border-top: 0.001em solid #677e8c;
  border-bottom: 0.001em solid #677e8c;
  margin: 10px 0;
}

.pre-start-category-editor .tile-drop-preview {
  height: 4rem;
  border: 1px dashed grey;
  background-color: rgba(150, 150, 200, 0.1);
}
</style>