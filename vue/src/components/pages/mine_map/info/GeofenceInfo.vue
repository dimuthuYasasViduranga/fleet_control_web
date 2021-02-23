<template>
  <div class="geofence-info">
    <table>
      <tr>
        <th class="title" colSpan="5">Geofence</th>
      </tr>
      <tr>
        <td class="heading">Name</td>
        <td class="value">{{ geofence.name }}</td>
      </tr>
      <tr>
        <td class="heading">Type</td>
        <td class="value">{{ geofence.type }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
export default {
  name: 'GeofenceInfo',
  props: {
    geofence: { type: Object, required: true },
  },
};
</script>

<style>
.geofence-info table {
  width: 100%;
}

.geofence-info .title {
  border-bottom: solid 1px;
}

.geofence-info .heading,
.geofence-info .value {
  text-align: center;
}

.geofence-info td {
  padding: 0.2rem 0.75rem;
}
</style>