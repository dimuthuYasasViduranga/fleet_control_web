<template>
  <g id="clock_with_user">
    <path
      d="M 15.642523,27.386146 A 12.592354,12.592354 0 0 1 3.5101704,19.161385 12.592354,12.592354 0 0 1 7.3819414,5.0245512 12.592354,12.592354 0 0 1 22.012029,4.1294399 12.592354,12.592354 0 0 1 27.578335,17.688825"
      id="clock-face"
    />
    <path id="clock-minute-hand" d="M 14.330142,7.7202594 V 16.782239" />
    <path id="clock-hour-hand" d="m 14.330142,16.782239 6.416145,-3.770312" />
    <path
      id="path2641"
      d="m 26.852497,25.544547 2.707557,1.875907 v 4.06446 H 17.67932 v -4.06446 l 2.707557,-1.875907"
    />
    <rect
      id="rect2643"
      ry="2.813858"
      rx="2.813858"
      height="6.8783202"
      width="5.6277161"
      y="18.353577"
      x="20.805828"
    />
  </g>
</template>

<script>
export default {
  name: 'ClockWithUser',
  viewBox: [5, 1, 26, 32],
};
</script>

<style>
#clock_with_user {
  stroke-width: 1.1;
}
</style>