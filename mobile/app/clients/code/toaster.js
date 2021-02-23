import * as Toast from 'nativescript-toast';
import { Toasty } from 'nativescript-toasty';

// Transparency is given AT THE START
const GREEN = '#dd006600';
const RED = '#dd990000';

export function green(text, duration) {
  return custom(text, { duration, backgroundColor: GREEN });
}

export function info(text, duration) {
  return Toast.makeText(text, duration);
}

export function red(text, duration) {
  return custom(text, { duration, backgroundColor: RED });
}

export function custom(text, options) {
  return new Toasty({
    text,
    ...options,
  });
}
