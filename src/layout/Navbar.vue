<template>
  <div>
    <span id="nav-gap"/>
    <div id="nav-bar">
      <div v-for="route in routes" :key="route.path">
        <router-link class="nav-item" :to="route.path">
          <div :id="route.path" class="nav-item-wrapper" >
            <icon :name="route.icon" :size="route.iconSize"/>
            {{route.name}}
            {{route.icon}}
            {{route.iconSize}}
          </div>
        </router-link>
      </div>
    </div>
  </div>
</template>

<script>
import icon from '../components/Icon.vue'

export default {
  name: 'hxNavbar',
  props: {
    routes: Array,
    selected: String
  },
  components: {
    icon
  },
  methods: {
    changeSelected: (event) => {
      this.selected = event.target.id;
      console.log(this.selected);
    }
  }
}

</script>

<style>
.router-link-active .nav-item-wrapper {
  background-color: #1b2a33;
  border-left-color: #09819c;
  border-left-width: 0.15em;
  border-left-style: solid;
}

.nav-item-wrapper:hover {
  background-color: #23343f
}

.nav-item-wrapper {
  overflow: hidden;
  background-color: #0c1419;
  height: 4em;
  width: 100%;

  white-space: nowrap;
  color: #b7c3cd;
}

.nav-item {
  text-decoration: none;
}

#nav-bar:hover {
  overflow: hidden;
  overflow-y: auto;
  max-width: 21.33333rem;
}

#nav-bar {
  overflow: hidden;
  background-color: #1B2A33;
  z-index: 5;
  box-sizing: inherit;
  verflow-x: hidden;
  overflow-y: hidden;
  position: absolute;
  height: 100%;
  left: 0;
  top: 0;
  min-width: 4rem;
  max-width: 4rem;
  transition: max-width 250ms ease;
  outline: 0;
  box-shadow: 0 2px 4px rgba(0,0,0,.2);
  display: block;
  width: 100%;
  line-height: 1.33333;
  color: #b6c3cc;
}

</style>
