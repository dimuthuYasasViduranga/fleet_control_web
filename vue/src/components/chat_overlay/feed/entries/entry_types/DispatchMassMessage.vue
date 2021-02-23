<template>
  <div class="dispatcher-mass-message" :class="acknowledgementClass">
    <div class="chat-line-right">
      <div class="box">
        <div class="box-wrapper">
          <div class="title">
            <div class="star">{{ '\u2b50' }}</div>
            <div ref="text" class="text">
              {{ dispatcherName }}
              {{ '\u2b95' }}
              <template v-if="nSubjects < maxNames || showMore">
                <span
                  v-for="(subject, index) in subjects"
                  :key="index"
                  :class="subjectAcknowledged(subject)"
                >
                  {{ subject.assetName }} {{ showComma(index) }}
                </span>
              </template>
              <span v-else>
                {{ nSubjects }} assets <span v-if="nUnread">({{ nUnread }} unread)</span>
              </span>
              <span v-if="nSubjects >= maxNames" class="see-more" @click="onToggleShowMore()">
                <br />{{ showMore ? 'less' : 'more' }}
              </span>
            </div>
          </div>
          <div class="message">{{ entry.text }}</div>
          <div class="answers" v-if="entry.answers.length !== 0">
            [
            <span
              class="answer"
              v-for="([answer, assets, count], index) in givenAnswers"
              v-tooltip.auto="{
                trigger: count === 0 ? 'manual' : 'hover',
                content: assets.join(', '),
                classes: ['dispatcher-mass-msg-subject-popover']
              }"
              :key="index"
            >
              <span class="text" :class="getUnselectedClass(count)">{{ answer }}</span>
              <span class="count" v-if="count !== 0">({{ count }})</span>
              <span v-if="index !== givenAnswers.length - 1" class="separator">|</span>
            </span>
            ]
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
const MAX_NAMES = 20;
export default {
  name: 'DispatchMassMessage',
  props: {
    entry: { type: Object, required: true },
  },
  data: () => {
    return {
      maxNames: MAX_NAMES,
      showMore: false,
    };
  },
  computed: {
    subjects() {
      return this.entry.subjects.slice().sort((a, b) => a.assetName.localeCompare(b.assetName));
    },
    nSubjects() {
      return this.subjects.length;
    },
    nUnread() {
      return this.subjects.filter(s => !s.acknowledged).length;
    },
    givenAnswers() {
      return this.entry.answers.map(answer => {
        const assets = this.entry.subjects.filter(s => s.answer === answer).map(s => s.assetName);
        assets.sort((a, b) => a.localeCompare(b));
        return [answer, assets, assets.length];
      });
    },
    hasAnyAnswers() {
      return this.entry.subjects.map(s => s.answer).filter(ans => ans).length !== 0;
    },
    dispatcherName() {
      return this.entry.dispatcher || 'Dispatcher';
    },
    acknowledgementClass() {
      if (this.entry.subjects.some(s => !s.acknowledged)) {
        return 'unacknowledged';
      }
      return '';
    },
  },
  methods: {
    showComma(index) {
      if (index === this.nSubjects - 1) {
        return '';
      }
      return ',';
    },
    subjectAcknowledged(subject) {
      return subject.acknowledged ? '' : 'subject-unack';
    },
    getUnselectedClass(count) {
      if (this.hasAnyAnswers && count === 0) {
        return 'unselected';
      }
    },
    onToggleShowMore() {
      this.showMore = !this.showMore;
    },
  },
};
</script>

<style>

.dispatcher-mass-msg-subject-popover {
  max-width: 20rem;
  text-align: center;
}

.dispatcher-mass-message {
  text-align: right;
  margin-left: 10%;
}

.dispatcher-mass-message .title .text {
  text-decoration: underline;
  padding-bottom: 0.25rem;
}

.dispatcher-mass-message .title {
  display: inline-flex;
}

.dispatcher-mass-message .answers .unselected {
  opacity: 0.25;
}

.dispatcher-mass-message .answers .answer .separator {
  margin: 0 0.25rem;
}

.dispatcher-mass-message .answers .answer .count {
  margin: 0 0.1rem;
  font-size: 0.75rem;
}

.dispatcher-mass-message.unacknowledged .box {
  border-color: orange;
}

.dispatcher-mass-message .subject-unack {
  color: orange;
}

.dispatcher-mass-message .chat-line-right {
  height: 100%;
  width: 100%;
  padding: 10px;
  padding-right: 30px;
}

.dispatcher-mass-message .see-more {
  cursor: pointer;
  color: orange;
}

.dispatcher-mass-message .box-wrapper {
  padding: 5px;
}

.dispatcher-mass-message .box {
  height: 100%;
  width: 100%;
  position: relative;
  border: 2px solid #003266;
  background-color: #003266;
  border-radius: 10px;
  border-top-right-radius: 0;
}

/* outter segment */
.dispatcher-mass-message .box:before {
  content: '';
  position: absolute;
  width: 0;
  height: 0;
  top: -2px; /* (border_diff / 2) */
  border: 20px solid;
  border-top-color: transparent;
  border-right-color: transparent;
  border-bottom-color: inherit;
  border-left-color: transparent;
  transform: translate(-50%, -50%) rotate(-45deg);
}

/* inner border */
.dispatcher-mass-message .box:after {
  content: '';
  position: absolute;
  width: 0;
  height: 0;
  top: 0;
  border: 16px solid;
  border-top-color: transparent;
  border-right-color: transparent;
  border-bottom-color: #003266;
  border-left-color: transparent;
  transform: translate(-50%, -50%) rotate(-45deg);
}
</style>