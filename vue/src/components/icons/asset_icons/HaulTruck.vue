<template>
  <g id="haul_truck_icon">
    <path
      id="tray"
      d="M 4.2333333,9.1332347 H 19.579166 L 22.225,6.4874047 h 9.525 v 2.64583 h -7.9375 l -9.525,9.5250003 -12.1708334,-7.40833 z"
    />
    <path
      id="front"
      d="m 30.559375,9.0341178 v 2.6458302 h -4.233333 v 4.23334 h 4.233333 v 6.87916 h -1.5875"
    />
    <path id="back" d="m 7.4083332,14.524419 -0.00827,4.4316" />
    <path id="bottom" d="m 13.910343,22.892288 h 6.291534" />
    <circle id="wheel-back" r="4.3878121" cy="22.825628" cx="9.5580721" />
    <circle id="wheel-front" r="4.3878121" cy="22.825628" cx="24.606249" />
  </g>
</template>

<script>
export default {
  name: 'HaulTruckIcon',
  viewBox: [0, 0, 35, 35],
};
</script>

<style>
#haul_truck_icon {
  stroke-width: 1.2;
}
</style>
