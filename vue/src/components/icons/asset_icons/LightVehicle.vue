<template>
  <g id="light_vehicle_icon" class="custom-icon">
    <circle id="wheel-back" r="3.0757811" cy="20.657343" cx="8.7643242" />
    <circle id="wheel-front" r="3.0757811" cy="20.657343" cx="25.962238" />
    <path id="bottom-line" d="M 11.840104,20.591199 H 22.820312" />
    <path
      id="body"
      d="M 6.7716796,18.309169 H 4.7624999 v 1.5875 H 3.175 v -3.175 h 8.995833 v -5.291666 h 9.525 l 1.5875,3.175 5.986198,0.562243 0.330729,0.463021 h 0.727604 l 1.124479,2.513541 v 1.5875 l -2.447396,0.363802"
    />
    <rect id="tray" y="14.075837" x="1.5875" height="2.6458342" width="10.583333" />
    <rect id="light" y="10.371669" x="13.229166" height="1.0583329" width="1.058332" />
    <path id="cabin-back" d="m 13.229166,12.488336 h 3.175 v 2.645833 h -3.174999 z" />
    <path
      id="cabin-front"
      d="m 17.991666,12.488336 v 2.645833 l 3.704167,6e-6 -1.058333,-2.645834 z"
    />
    <path id="rail" d="m 13.72526,19.036772 h 7.639844" />
  </g>
</template>

<script>
export default {
  name: 'LightVehicle',
  viewBox: [0, 0, 34, 34],
};
</script>
