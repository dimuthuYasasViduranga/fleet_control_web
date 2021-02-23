<template>
  <ScrollView class="pre-start-modal">
    <GridLayout class="no-pre-start" v-if="!localPreStart" rows="* 5* 2*" height="100%">
      <CenteredLabel
        row="1"
        class="label"
        :textWrap="true"
        :text="`No Pre-Start configured for this asset\nPlease contact controller`"
      />

      <Button row="2" text="Back" @tap="close()" />
    </GridLayout>

    <StackLayout v-else class="pre-start-content">
      <StackLayout v-for="(section, sIndex) in localPreStart.sections" :key="`section-${sIndex}`">
        <Label class="section-header title" :text="section.title" />
        <Label v-if="section.details" class="section-header details" :text="section.details" />
        <StackLayout
          v-for="(control, cIndex) in section.controls"
          :key="`section-${sIndex}-control-${cIndex}`"
        >
          <GridLayout class="control" columns="7* * * *">
            <CenteredLabel
              col="0"
              class="control-label"
              textAlignment="left"
              :textWrap="true"
              :text="control.label"
            />
            <Button
              col="1"
              class="answer"
              :class="{ selected: control.answer === true }"
              text="✔"
              @tap="setAnswer(control, true)"
            />
            <Button
              col="2"
              class="answer"
              :class="{ selected: control.answer === false }"
              text="❌"
              @tap="setAnswer(control, false)"
            />
            <Button
              col="3"
              class="answer"
              :class="{ selected: control.answer === null }"
              text="N/A"
              @tap="setAnswer(control, null)"
            />
          </GridLayout>
        </StackLayout>
      </StackLayout>
      <!-- comments -->
      <CenteredLabel class="comment-label" text="Comments" />
      <GridLayout
        class="comment"
        v-for="(comment, index) in localPreStart.comments"
        :key="index"
        columns="9* *"
      >
        <TextField
          col="0"
          class="text-field"
          keyboardType="text"
          :autocorrect="false"
          v-model="comment.text"
        />
        <Button col="1" class="comment-remove" text="x" @tap="onRemoveComment(comment)" />
      </GridLayout>

      <Button text="New Comment" @tap="onNewComment()" />

      <!-- comments go here -->
      <!-- ensure that it moves out of the way so that you can see what you are writing -->
      <CenteredLabel
        class="completion-status"
        textAlignment="right"
        :text="`Completed: ${completedControlIds.length}/${controlCount}`"
      />
      <GridLayout class="actions" columns="* *">
        <Button
          col="0"
          text="Submit"
          :isEnabled="completedControlIds.length === controlCount"
          @tap="onSubmit"
        />
        <Button col="1" text="Cancel" @tap="close()" />
      </GridLayout>
    </StackLayout>
  </ScrollView>
</template>

<script>
import { attributeFromList } from '../../code/helper';
import CenteredLabel from '../CenteredLabel.vue';

function preStartToSubmission(preStart, asset, operator) {
  const responses = preStart.sections
    .map(s => s.controls)
    .flat()
    .map(c => {
      return {
        controlId: c.id,
        answer: c.answer,
        comment: c.comment,
      };
    });

  return {
    formId: preStart.formId,
    assetId: asset.id,
    operatorId: operator.id,
    employeeId: operator.employeeId,
    comment: preStart.comments.map(c => c.text).join('\n'),
    timestamp: Date.now(),
    responses,
  };
}

function toLocalPreStart(preStart) {
  if (!preStart.id) {
    return null;
  }
  return {
    formId: preStart.id,
    comments: [],
    sections: preStart.sections.map(s => {
      return {
        title: s.title,
        details: s.details,
        controls: s.controls.map(c => {
          return {
            id: c.id,
            label: c.label,
            answer: undefined,
          };
        }),
      };
    }),
  };
}

export default {
  name: 'PreStartModal',
  components: {
    CenteredLabel,
  },
  props: {
    asset: { type: Object },
    operator: { type: Object },
    preStarts: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      completedControlIds: [],
      localPreStart: null,
    };
  },
  computed: {
    controlCount() {
      const preStart = this.localPreStart;
      if (!preStart) {
        return 0;
      }
      return preStart.sections.map(s => s.controls).flat().length;
    },
    preStart() {
      return attributeFromList(this.preStarts, 'assetTypeId', this.asset.typeId);
    },
  },
  mounted() {
    this.localPreStart = toLocalPreStart(this.preStart);
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    setAnswer(control, answer) {
      control.answer = answer;

      if (!this.completedControlIds.includes(control.id)) {
        this.completedControlIds.push(control.id);
      }
    },
    onSubmit() {
      if (!this.localPreStart || !this.asset || !this.operator) {
        console.error('[PreStart] Unable to submit pre-start. Missing fields');
        return;
      }

      const submission = preStartToSubmission(this.localPreStart, this.asset, this.operator);

      this.$store.dispatch('submitPreStartSubmission', { submission, channel: this.$channel });
      this.close(submission);
    },
    onNewComment() {
      this.localPreStart.comments.push({ text: '' });
    },
    onRemoveComment(comment) {
      this.localPreStart.comments = this.localPreStart.comments.filter(c => c !== comment);
    },
  },
};
</script>

<style>
.pre-start-modal {
  background-color: white;
  height: 100%;
  width: 100%;
}

.pre-start-modal .pre-start-content {
  padding: 25 50;
}

/* no pre-start */
.no-pre-start .label {
  font-size: 40;
}

.no-pre-start button {
  font-size: 30;
}

/* ---- sections ---- */
.pre-start-modal .title {
  font-size: 35;
  margin-top: 25;
  font-weight: 500;
}

.pre-start-modal .details {
  font-size: 28;
}

.pre-start-modal .section-header {
  background-color: #d6d7d7;
}

/* ---- controls ---- */

.pre-start-modal .control {
  border-top-width: 0;
  border-top-color: black;
  border-bottom-width: 1;
  border-bottom-color: black;
}

.pre-start-modal .control .control-label {
  font-size: 26;
  color: black;
}

.pre-start-modal .control .answer {
  height: 80;
  font-size: 26;
  background-color: white;
}

.pre-start-modal .control .answer.selected {
  background-color: orange;
}

/* ---- comments ---- */

.pre-start-modal .comment-label {
  margin-top: 50;
  font-size: 30;
  background-color: #d6d7d7;
  font-weight: 500;
}

.pre-start-modal .comment {
  height: 100;
}

.pre-start-modal .text-field {
  font-size: 26;
}

.pre-start-modal .comment-remove {
  font-size: 26;
  background-color: white;
  height: 75;
  width: 75;
}

.pre-start-modal .completion-status {
  font-size: 20;
}

/* ---- actions ---- */

.pre-start-modal .actions {
  margin-top: 30;
  height: 100;
  font-size: 30;
}
</style>