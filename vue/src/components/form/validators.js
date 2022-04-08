import { helpers } from 'vuelidate/lib/validators';
import { toEpoch } from '@/code/time';

export function dateGreaterThanOrEqual(compareField) {
  return helpers.withParams(
    { type: 'dateGreaterThanOrEqual', cmp: compareField },
    (value, parentVm) => {
      const epoch = toEpoch(value);
      if (!epoch) {
        return !helpers.req();
      }

      const otherValue = helpers.ref(compareField, this, parentVm);

      const cmpEpoch = toEpoch(otherValue);

      return epoch >= cmpEpoch;
    },
  );
}

export const customValidator = (name, callback, validateIfCallback) => {
  return helpers.withParams({ type: name }, function(value, model) {
    if (!validateIfCallback || validateIfCallback.call(this, value, model)) {
      return callback.call(this, value, model);
    }
    return false;
  });
};

export const doesNotContain = chars =>
  customValidator('doesNotContain', value => {
    return !value || [...value].every(l => !chars.includes(l));
  });

export const onlyContains = chars =>
  customValidator('onlyContains', value => {
    if (!value) {
      return true;
    }
    return [...value].every(l => chars.includes(l));
  });

export const positive = customValidator('positive', value => {
  const num = Number(value);
  return !isNaN(num) && num >= 0;
});
